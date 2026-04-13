// controllers/accountDeleteController.js
const { validationResult } = require('express-validator');
const pool = require('../db/pool');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { sendOtpEmail } = require('../services/mailer');

function clientIp(req) { return (req.ip || '').replace('::ffff:', '') || '0.0.0.0'; }
const IS_PROD = process.env.NODE_ENV === 'production';

/** ====== DELETE OTP limits: duros por entorno ======
 *  - DEV: límites grandes / expiración larga
 *  - PROD: toma de .env o defaults estrictos
 */
const DEL_COOLDOWN_SEC = IS_PROD
  ? Number(process.env.OTP_DELETE_COOLDOWN_SEC ?? 60)
  : 3;

const DEL_MAX_EMAIL_DAY = IS_PROD
  ? Number(process.env.OTP_DELETE_MAX_EMAIL_PER_DAY ?? 2)
  : 999_999;

const DEL_MAX_IP_HOUR = IS_PROD
  ? Number(process.env.OTP_DELETE_MAX_IP_PER_HOUR ?? 10)
  : 999_999;

const DEL_EXPIRES_MIN = IS_PROD
  ? Number(process.env.OTP_DELETE_EXPIRES_MIN ?? 8)
  : 1440;

/* ====== Ticket JWT dedicado a eliminación ====== */
const DELETE_TICKET_TTL = process.env.DELETE_TICKET_TTL || '10m';
const DELETE_TICKET_AUD = process.env.DELETE_TICKET_AUDIENCE || 'yoverifico-accdel';
const DELETE_TICKET_ISS = process.env.DELETE_TICKET_ISSUER || 'yoverifico';
const PURPOSE_DELETE = 'account_delete';

/* ========== 1) REQUEST OTP (eliminar) ========== */
exports.requestDeleteAccountCode = async (req, res) => {
  const correoOriginal = String(req.body.correo || '').trim();
  if (!correoOriginal) return res.status(400).json({ msg: 'Correo requerido' });
  const correoCanon = correoOriginal.toLowerCase();

  // El CAPTCHA ya se valida en rutas con captchaMiddleware('acc_delete_request')
  try {
    const { rows } = await pool.query(
      `SELECT otp_plain, resend_count, next_allowed_at
         FROM fn_request_email_otp($1,$2,$3,$4,$5,$6,$7,$8)`,
      [correoCanon,
        clientIp(req),
        req.headers['user-agent'] || null,
        DEL_COOLDOWN_SEC,
        DEL_MAX_EMAIL_DAY,
        DEL_MAX_IP_HOUR,
        DEL_EXPIRES_MIN,
        PURPOSE_DELETE]
    );

    const { otp_plain, resend_count, next_allowed_at } = rows[0] || {};
    // Anti-enumeración: respuesta genérica si no hay OTP
    if (!otp_plain) return res.status(200).json({ ok: true });

    await sendOtpEmail(correoOriginal, otp_plain, {
      template: 'account_delete',
      expiresMin: DEL_EXPIRES_MIN,
    });

    return res.json({ ok: true, resend_count, next_allowed_at });
  } catch (e) {
    if (e?.code === '42903') return res.status(429).json({ ok: false, msg: 'Cooldown' });
    if (e?.code === '42901') return res.status(429).json({ ok: false, msg: 'Límite diario por correo' });
    if (e?.code === '42902') return res.status(429).json({ ok: false, msg: 'Demasiadas solicitudes desde esta IP' });
    console.error('[ACCDEL][request] err:', e);
    // Anti-enumeración: no revelar si existe o no
    return res.status(200).json({ ok: true });
  }
};

/* ========== 2) VERIFY OTP → delete_ticket ========== */
exports.verifyDeleteAccountCode = async (req, res) => {
  const errs = validationResult(req);
  if (!errs.isEmpty()) return res.status(400).json({ msg: 'Datos inválidos' });

  const correo = String(req.body.correo || '').trim().toLowerCase();
  const codigo = String(req.body.codigo || '').trim();

  // Si quisieras CAPTCHA aquí, aplícalo en rutas con captchaMiddleware('acc_delete_verify')
  try {
    const { rows } = await pool.query(
      'SELECT * FROM fn_verify_email_otp($1::citext,$2::text,$3::text)',
      [correo, codigo, PURPOSE_DELETE]
    );
    const r = rows[0];
    if (!r?.ok) return res.status(400).json({ msg: 'Código inválido o expirado' });

    const ticket = jwt.sign(
      { email: correo, purpose: PURPOSE_DELETE },
      process.env.JWT_SECRET,
      { expiresIn: DELETE_TICKET_TTL, audience: DELETE_TICKET_AUD, issuer: DELETE_TICKET_ISS, algorithm: 'HS256' }
    );
    return res.json({ ticket });
  } catch (e) {
    console.error('[ACCDEL][verify] err:', e);
    return res.status(400).json({ msg: 'Código inválido' });
  }
};

/* ========== 3) CONFIRM → eliminar usuario ========== */
exports.finalizeAccountDeletion = async (req, res) => {
  const errs = validationResult(req);
  if (!errs.isEmpty()) return res.status(400).json({ msg: 'Datos inválidos' });

  const { ticket } = req.body;

  // Valida delete_ticket
  let correoCanon;
  try {
    const t = jwt.verify(ticket, process.env.JWT_SECRET, {
      audience: DELETE_TICKET_AUD,
      issuer: DELETE_TICKET_ISS,
      algorithms: ['HS256'],
    });
    if (t.purpose !== PURPOSE_DELETE) return res.status(401).json({ msg: 'Ticket inválido' });
    correoCanon = String(t.email || '').trim().toLowerCase();
    if (!correoCanon) return res.status(401).json({ msg: 'Ticket inválido (sin email)' });
  } catch (e) {
    return res.status(401).json({ msg: e.name === 'TokenExpiredError' ? 'Ticket expirado' : 'Ticket inválido' });
  }

  try {
    const u = await pool.query('SELECT * FROM obtener_usuario_por_correo($1)', [correoCanon]);
    if (!u.rows.length) return res.status(200).json({ ok: true }); // anti-enumeración

    const user = u.rows[0];

    const del = await pool.query('SELECT * FROM fn_usuario_eliminar($1)', [user.id]);
    const deleted = del.rows?.[0]?.deleted === true;
    if (!deleted) return res.status(400).json({ ok: false, msg: 'No se pudo eliminar la cuenta' });

    return res.json({ ok: true });
  } catch (e) {
    console.error('[ACCDEL][finalize] err:', e);
    return res.status(500).json({ msg: 'Error del servidor' });
  }
};

/* ========== Eliminar con sesión (opcional, reautenticado) ========== */
exports.deleteAccountWithSession = async (req, res) => {
  const errs = validationResult(req);
  if (!errs.isEmpty()) return res.status(400).json({ msg: 'Datos inválidos' });

  const userId = req.usuarioId;
  const { passwordActual } = req.body;

  try {
    if (passwordActual) {
      const u = await pool.query('SELECT * FROM obtener_usuario_basico_con_hash($1)', [userId]);
      const user = u.rows[0];
      if (!user) return res.status(404).json({ msg: 'Usuario no encontrado' });
      const ok = await bcrypt.compare(String(passwordActual), user.password);
      if (!ok) return res.status(401).json({ msg: 'Contraseña actual incorrecta' });
    }

    const del = await pool.query('SELECT * FROM fn_usuario_eliminar($1)', [userId]);
    const deleted = del.rows?.[0]?.deleted === true;
    if (!deleted) return res.status(400).json({ ok: false, msg: 'No se pudo eliminar la cuenta' });

    return res.json({ ok: true });
  } catch (e) {
    console.error('[ACCDEL][withSession] err:', e);
    return res.status(500).json({ msg: 'Error del servidor' });
  }
};

module.exports = exports;

// controllers/passwordResetController.js
const pool = require('../db/pool');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { sendPwdResetOtpEmail, sendPasswordChangedEmail } = require('../services/mailer');

// Utilidad IP
function clientIp(req) {
  return (req.ip || '').replace('::ffff:', '') || '0.0.0.0';
}

function intFromEnv(keys, fallback) {
  for (const k of keys) {
    const v = process.env[k];
    if (v !== undefined && v !== null && v !== '') return Number(v);
  }
  return fallback;
}

// === Límites para reset de contraseña ===
const IS_PROD = process.env.NODE_ENV === 'production';
const COOLDOWN_SEC = intFromEnv(['PWD_OTP_COOLDOWN_SEC', 'OTP_COOLDOWN_SEC'], IS_PROD ? 3600 : 0);
const MAX_EMAIL_DAY = intFromEnv(['PWD_OTP_MAX_EMAIL_PER_DAY', 'OTP_MAX_EMAIL_PER_DAY'], IS_PROD ? 5 : 1000000);
const MAX_IP_HOUR = intFromEnv(['PWD_OTP_MAX_IP_PER_HOUR', 'OTP_MAX_IP_PER_HOUR'], IS_PROD ? 10 : 1000000);
const EXPIRES_MIN = intFromEnv(['PWD_OTP_EXPIRES_MIN', 'OTP_EXPIRES_MIN'], 10);

const PWD_TICKET_TTL = process.env.PWD_TICKET_TTL || '45m';
const PWD_TICKET_AUD = process.env.PWD_TICKET_AUDIENCE || 'yoverifico-pwdreset';
const PWD_TICKET_ISS = process.env.PWD_TICKET_ISSUER || 'yoverifico';
const PURPOSE_PWDRESET = 'pwdreset';

/**
 * POST /api/auth/password/otp/request
 * Body: { correo }
 * - CAPTCHA se aplica en rutas con captchaMiddleware('pwd_otp_request')
 */
exports.requestResetCode = async (req, res) => {
  const { correo } = req.body || {};
  const correoOriginal = typeof correo === 'string' ? correo.trim() : '';
  if (!correoOriginal) return res.status(400).json({ ok: false, msg: 'Correo requerido' });

  const correoCanon = correoOriginal.toLowerCase();

  try {
    // 1) El correo debe existir
    const u = await pool.query('SELECT id FROM obtener_usuario_por_correo($1)', [correoCanon]);
    if (!u.rows?.length) {
      return res.status(404).json({ ok: false, msg: 'Correo no registrado' });
    }

    // 2) Solicitar OTP
    const { rows } = await pool.query(
      `SELECT otp_plain, link_plain, resend_count, next_allowed_at
         FROM fn_request_email_otp($1,$2,$3,$4,$5,$6,$7,$8)`,
      [
        correoCanon,
        clientIp(req),
        req.headers['user-agent'] || null,
        COOLDOWN_SEC,
        MAX_EMAIL_DAY,
        MAX_IP_HOUR,
        EXPIRES_MIN,
        PURPOSE_PWDRESET,
      ]
    );
    if (!rows?.length) return res.status(500).json({ ok: false, msg: 'OTP generator returned no data' });

    const { otp_plain, resend_count, next_allowed_at } = rows[0];
    const messageId = await sendPwdResetOtpEmail(correoOriginal, otp_plain);
    return res.json({ ok: true, resend_count, next_allowed_at, messageId });

  } catch (e) {
    if (e?.code === '42903') return res.status(429).json({ ok: false, msg: 'Cooldown' });
    if (e?.code === '42901') return res.status(429).json({ ok: false, msg: 'Límite diario por correo' });
    if (e?.code === '42902') return res.status(429).json({ ok: false, msg: 'Demasiadas solicitudes desde esta IP' });
    console.error('[PWDRESET] request error:', e);
    return res.status(500).json({ ok: false, msg: e.message || 'Error al solicitar OTP de contraseña' });
  }
};

/**
 * POST /api/auth/password/otp/verify
 * Body: { correo, codigo }
 * - CAPTCHA (si lo quieres) se aplica en rutas con captchaMiddleware('pwd_otp_verify')
 */
exports.verifyResetCode = async (req, res) => {
  const { correo, codigo } = req.body || {};
  const correoCanon = String(correo || '').trim().toLowerCase();
  const code = String(codigo || '').trim();
  if (!correoCanon || !code) return res.status(400).json({ ok: false, msg: 'Datos requeridos' });

  try {
    const { rows } = await pool.query(
      'SELECT * FROM fn_verify_email_otp($1::citext,$2::text,$3::text)',
      [correoCanon, code, PURPOSE_PWDRESET]
    );
    const r = rows?.[0];
    if (!r?.ok) {
      if (r?.locked) return res.status(423).json({ ok: false, msg: 'Demasiados intentos. Intenta más tarde.' });
      return res.status(400).json({ ok: false, msg: 'Código inválido o expirado' });
    }

    const ticket = jwt.sign(
      { email: correoCanon, purpose: PURPOSE_PWDRESET },
      process.env.JWT_SECRET,
      { expiresIn: PWD_TICKET_TTL, audience: PWD_TICKET_AUD, issuer: PWD_TICKET_ISS, algorithm: 'HS256' }
    );
    return res.json({ ok: true, ticket });

  } catch (e) {
    console.error('[PWDRESET] verify error:', e);
    return res.status(400).json({ ok: false, msg: 'Código inválido' });
  }
};

/**
 * POST /api/auth/password/reset
 * Body: { ticket, newPassword | nuevaPassword }
 * - CAPTCHA se aplica en rutas con captchaMiddleware('pwd_reset') si lo deseas
 */
exports.resetPassword = async (req, res) => {
  const ticket = req.body?.ticket;
  const newPassword = req.body?.newPassword ?? req.body?.nuevaPassword;

  if (!ticket || !newPassword) return res.status(400).json({ ok: false, msg: 'Datos requeridos' });
  if (String(newPassword).length < 6) return res.status(400).json({ ok: false, msg: 'Contraseña muy corta (mín. 6)' });

  try {
    // 1) Verifica ticket
    let emailCanon = '';
    try {
      const t = jwt.verify(ticket, process.env.JWT_SECRET, {
        audience: PWD_TICKET_AUD,
        issuer: PWD_TICKET_ISS,
        algorithms: ['HS256'],
      });
      if (t.purpose !== PURPOSE_PWDRESET) {
        return res.status(400).json({ ok: false, msg: 'Ticket con propósito inválido' });
      }
      emailCanon = String(t.email || '').trim().toLowerCase();
      if (!emailCanon) return res.status(400).json({ ok: false, msg: 'Ticket inválido (sin email)' });
    } catch (e) {
      return res.status(401).json({
        ok: false,
        msg: e?.name === 'TokenExpiredError' ? 'Ticket expirado' : 'Ticket inválido',
      });
    }

    // 2) Usuario por correo
    const u = await pool.query('SELECT id FROM obtener_usuario_por_correo($1)', [emailCanon]);
    if (!u.rows?.length) return res.status(404).json({ ok: false, msg: 'Usuario no encontrado' });
    const userId = u.rows[0].id;

    // 3) Hash & update
    const hash = await bcrypt.hash(String(newPassword), 10);
    const rUpdate = await pool.query('SELECT * FROM fn_usuario_cambiar_password($1,$2)', [userId, hash]);
    const r = rUpdate.rows?.[0];
    if (!r) return res.status(500).json({ ok: false, msg: 'Error al actualizar' });
    if (!r.updated) return res.status(400).json({ ok: false, msg: r.mensaje || 'No se pudo cambiar la contraseña' });

    // 4) Email de seguridad (no bloquear si falla)
    try {
      await sendPasswordChangedEmail(emailCanon, {
        whenIso: new Date().toISOString(),
        ip: clientIp(req),
        userAgent: req.headers['user-agent'] || '',
      });
    } catch (mailErr) {
      console.warn('[PWDRESET] password-changed mail failed:', mailErr?.message || mailErr);
    }

    return res.json({ ok: true, msg: 'Contraseña actualizada' });

  } catch (e) {
    console.error('[PWDRESET] reset error:', e);
    return res.status(500).json({ ok: false, msg: 'Error del servidor' });
  }
};

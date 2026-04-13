// controllers/otpController.js
const { validationResult } = require('express-validator');
const pool = require('../db/pool');
const { sendOtpEmail } = require('../services/mailer');
const jwt = require('jsonwebtoken');

function clientIp(req) {
  return (req.ip || '').replace('::ffff:', '') || '0.0.0.0';
}

const IS_PROD = process.env.NODE_ENV === 'production';

// Config OTP (con defaults distintos en dev)
const COOLDOWN_SEC = Number(process.env.OTP_COOLDOWN_SEC || (IS_PROD ? 60 : 3));
const MAX_EMAIL_DAY = Number(process.env.OTP_MAX_EMAIL_PER_DAY || (IS_PROD ? 5 : 999999));
const MAX_IP_HOUR = Number(process.env.OTP_MAX_IP_PER_HOUR || (IS_PROD ? 40 : 999999));
const EXPIRES_MIN = Number(process.env.OTP_EXPIRES_MIN || (IS_PROD ? 10 : 1440)); // en dev 24h

// Ticket corto para completar registro
const TICKET_TTL = process.env.SIGNUP_TICKET_TTL || '10m';
const TICKET_AUD = process.env.SIGNUP_TICKET_AUDIENCE || 'yoverifico-signup';
const TICKET_ISS = process.env.SIGNUP_TICKET_ISSUER || 'yoverifico';
const PURPOSE_SIGNUP = 'signup';

// ========== REQUEST CODE ==========
exports.requestCode = async (req, res) => {
  const correoOriginal = typeof req.body.correo === 'string' ? req.body.correo.trim() : '';
  if (!correoOriginal) return res.status(400).json({ msg: 'Correo requerido' });
  const correoCanon = correoOriginal.toLowerCase();

  try {
    const { rows } = await pool.query(
      `SELECT otp_plain, link_plain, resend_count, next_allowed_at
         FROM fn_request_email_otp($1::citext,$2::inet,$3::text,$4::int,$5::int,$6::int,$7::int,$8::text)`,
      [correoCanon, clientIp(req), req.headers['user-agent'] || null,
        COOLDOWN_SEC, MAX_EMAIL_DAY, MAX_IP_HOUR, EXPIRES_MIN, PURPOSE_SIGNUP]
    );

    if (!rows?.length) return res.status(500).json({ ok: false, msg: 'OTP generator returned no data' });
    const { otp_plain, resend_count, next_allowed_at } = rows[0];

    const messageId = await sendOtpEmail(correoOriginal, otp_plain);
    return res.json({ ok: true, resend_count, next_allowed_at, messageId });

  } catch (e) {
    if (e?.code === '40901') return res.status(409).json({ ok: false, msg: 'Correo ya registrado' });
    if (e?.code === '42903') return res.status(429).json({ ok: false, msg: 'Cooldown' });
    if (e?.code === '42901') return res.status(429).json({ ok: false, msg: 'Límite diario por correo' });
    if (e?.code === '42902') return res.status(429).json({ ok: false, msg: 'Demasiadas solicitudes desde esta IP' });
    console.error('OTP request error:', e);
    return res.status(500).json({ ok: false, msg: e.message || 'Error al solicitar OTP' });
  }
};

// ========== REENVIAR CODE ==========
exports.resendCode = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ msg: 'Datos inválidos' });

  const correo = String(req.body.correo || '').trim().toLowerCase();
  if (!correo) return res.status(400).json({ msg: 'Correo requerido' });

  try {
    const { rows } = await pool.query(
      `SELECT otp_plain, link_plain, resend_count, next_allowed_at
         FROM fn_request_email_otp($1::citext,$2::inet,$3::text,$4::int,$5::int,$6::int,$7::int,$8::text)`,
      [correo, clientIp(req), req.headers['user-agent'] || null,
        COOLDOWN_SEC, MAX_EMAIL_DAY, MAX_IP_HOUR, EXPIRES_MIN, PURPOSE_SIGNUP]
    );

    if (!rows?.length) {
      console.error('[OTP] resend: fn_request_email_otp returned NO ROW');
      return res.status(500).json({ ok: false, msg: 'OTP generator returned no data' });
    }

    const { otp_plain, resend_count, next_allowed_at } = rows[0];
    const messageId = await sendOtpEmail(correo, otp_plain);
    return res.json({ ok: true, resend_count, next_allowed_at, messageId });

  } catch (e) {
    console.error('OTP resend error:', e);
    if (e?.code === '42903') return res.status(429).json({ ok: false, msg: 'Cooldown' });
    if (e?.code === '42901') return res.status(429).json({ ok: false, msg: 'Daily limit reached for this email' });
    if (e?.code === '42902') return res.status(429).json({ ok: false, msg: 'Too many requests from this IP' });
    return res.status(500).json({ ok: false, msg: e.message || 'Error al reenviar OTP' });
  }
};

// ========== VERIFY CODE ==========
exports.verifyCode = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ msg: 'Datos inválidos' });

  const correo = String(req.body.correo || '').trim().toLowerCase();
  const codigo = String(req.body.codigo || '').trim();
  if (!correo || !codigo) return res.status(400).json({ msg: 'Datos requeridos' });

  try {
    // 👇 explícito: verify por propósito 'signup'
    const { rows } = await pool.query(
      'SELECT * FROM fn_verify_email_otp($1::citext,$2::text,$3::text)',
      [correo, codigo, PURPOSE_SIGNUP]
    );
    const r = rows[0];
    if (!r?.ok) return res.status(400).json({ msg: 'Código inválido o expirado' });

    const ticket = jwt.sign(
      { email: correo, purpose: PURPOSE_SIGNUP },
      process.env.JWT_SECRET,
      { expiresIn: TICKET_TTL, audience: TICKET_AUD, issuer: TICKET_ISS, algorithm: 'HS256' }
    );
    return res.json({ ticket });
  } catch (e) {
    console.error('OTP verify error:', e);
    return res.status(400).json({ msg: 'Código inválido' });
  }
};

// routes/usuarioRoutes.js
const express = require('express');
const { body } = require('express-validator');
const router = express.Router();

// Middlewares nuevos
const { captchaMiddleware } = require('../middlewares/captcha');
const { rateLimitPublic, rateLimitUser } = require('../middlewares/rateLimit');
const verifyToken = require('../middlewares/verifyToken');

// Controllers
const usuario = require('../controllers/usuarioController');

// Helper para asegurar handlers
function ensureHandler(obj, name) {
  if (obj && typeof obj[name] === 'function') return obj[name];
  console.error(`[usuarioRoutes] Handler faltante u inválido: ${name}`);
  return (req, res) => res.status(500).json({ ok: false, msg: `Handler ${name} no disponible` });
}

const requestPwdResetCode = ensureHandler(usuario, 'requestPwdResetCode');
const verifyPwdResetCode = ensureHandler(usuario, 'verifyPwdResetCode');
const finalizePwdReset = ensureHandler(usuario, 'finalizePwdReset');
const changePasswordLogged = ensureHandler(usuario, 'changePasswordLogged');

const requestDeleteAccountCode = ensureHandler(usuario, 'requestDeleteAccountCode');
const verifyDeleteAccountCode = ensureHandler(usuario, 'verifyDeleteAccountCode');
const finalizeAccountDeletion = ensureHandler(usuario, 'finalizeAccountDeletion');
const deleteAccountWithSession = ensureHandler(usuario, 'deleteAccountWithSession');

// ==============================
// Recuperación de contraseña (OTP)
// ==============================
// Request OTP: IP limit + CAPTCHA
router.post(
  '/password/otp/request',
  rateLimitPublic('pwd_otp_request', { window: 60, limit: 3 }),
  body('correo').isEmail(),
  requestPwdResetCode
);

// Verify OTP: sin CAPTCHA, límite leve (evita brute force del código)
router.post(
  '/password/otp/verify',
  rateLimitPublic('pwd_otp_verify', { window: 60, limit: 60 }),
  body('correo').isEmail(),
  body('codigo').isLength({ min: 4, max: 8 }).trim(),
  verifyPwdResetCode
);

// Reset final con ticket: sin CAPTCHA, límite leve
router.post(
  '/password/reset',
  rateLimitPublic('pwd_reset', { window: 60, limit: 60 }),
  body('ticket').notEmpty(),
  body('nuevaPassword').isLength({ min: 8 }),
  finalizePwdReset
);

// ==============================
// Cambio de contraseña con login
// ==============================
router.post(
  '/password/change',
  verifyToken,
  rateLimitUser('pwd_change', { window: 60, limit: 30 }),
  body('nuevaPassword').isLength({ min: 8 }),
  body('passwordActual').optional().isLength({ min: 1 }),
  changePasswordLogged
);

// ==============================
// Eliminación de cuenta (OTP)
// ==============================
// Request OTP para eliminar: IP limit + CAPTCHA
router.post(
  '/account/delete/otp/request',
  rateLimitPublic('acc_delete_request', { window: 60, limit: 3 }),
  body('correo').isEmail(),
  requestDeleteAccountCode
);

// Verify OTP: sin CAPTCHA, límite leve
router.post(
  '/account/delete/otp/verify',
  rateLimitPublic('acc_delete_verify', { window: 60, limit: 60 }),
  body('correo').isEmail(),
  body('codigo').isLength({ min: 4, max: 8 }).trim(),
  verifyDeleteAccountCode
);

// Confirmar eliminación con ticket: sin CAPTCHA, límite leve
router.post(
  '/account/delete/confirm',
  rateLimitPublic('acc_delete_confirm', { window: 60, limit: 60 }),
  body('ticket').notEmpty(),
  finalizeAccountDeletion
);

// (opcional) eliminación con sesión + reautenticación
router.post(
  '/account/delete/with-session',
  verifyToken,
  rateLimitUser('acc_delete_session', { window: 60, limit: 20 }),
  body('passwordActual').optional().isLength({ min: 1 }),
  deleteAccountWithSession
);

module.exports = router;

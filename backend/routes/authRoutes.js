// routes/auth.js
const express = require('express');
const router = express.Router();

const {
  registro,
  registroGoogle,   // /google y /registroGoogle
  login,
  getUsuario,
  whoami,
  existeCorreo,
  existeCorreoPorIdToken,
  refresh,
  // logout,
} = require('../controllers/authController');

const verifyToken = require('../middlewares/verifyToken');

// Middlewares nuevos
const { captchaMiddleware } = require('../middlewares/captcha');
const { rateLimitPublic, rateLimitUser } = require('../middlewares/rateLimit');

// Controladores secundarios
const otp = require('../controllers/otpController');
const { body } = require('express-validator');
const pwd = require('../controllers/passwordResetController');

// ====================================================================
// OTP por correo (públicas)
// ====================================================================
// Límite agresivo por IP + CAPTCHA
router.post('/otp/email/request',
  rateLimitPublic('otp_request', { window: 60, limit: 3 }),
  body('correo').isEmail(),
  otp.requestCode
);

router.post('/otp/email/resend',
  rateLimitPublic('otp_resend', { window: 60, limit: 3 }),
  body('correo').isEmail(),
  otp.resendCode
);

// Verificación de OTP: puedes omitir CAPTCHA si no lo requieres
router.post('/otp/email/verify',
  // Si quisieras captcha: captchaMiddleware('otp_verify')
  body('correo').isEmail(),
  body('codigo').isLength({ min: 4, max: 8 }).trim(),
  otp.verifyCode
);

// ====================================================================
// Reset de contraseña (públicas con OTP + ticket)
// ====================================================================
router.post('/password/otp/request',
  rateLimitPublic('pwd_otp_request', { window: 60, limit: 3 }),
  body('correo').isEmail(),
  pwd.requestResetCode
);

router.post('/password/otp/verify',
  // Si quieres: captchaMiddleware('pwd_otp_verify')
  body('correo').isEmail(),
  body('codigo').isLength({ min: 4, max: 8 }).trim(),
  pwd.verifyResetCode
);

router.post('/password/reset',
  // Aquí normalmente no pides captcha porque ya hay ticket
  body('ticket').notEmpty(),
  body('newPassword').isLength({ min: 6 }),
  pwd.resetPassword
);

// ====================================================================
// Autenticación y perfil
// ====================================================================
// Registro normal: IP limit + CAPTCHA
router.post('/registro',
  rateLimitPublic('signup', { window: 60, limit: 5 }),
  // captchaMiddleware('signup'),
  registro
);

// Google: SIN CAPTCHA (como pediste). Puedes dejar rate limit suave si quieres.
router.post('/google',
  rateLimitPublic('google_signup', { window: 60, limit: 30 }),
  registroGoogle
);
router.post('/registroGoogle',
  rateLimitPublic('google_signup', { window: 60, limit: 30 }),
  registroGoogle
);

// Login: IP limit + CAPTCHA
router.post('/login',
  rateLimitPublic('login', { window: 60, limit: 20 }),
  // captchaMiddleware('login'),
  login
);

// Refresh (privada): menor agresividad, por usuario
router.post('/refresh',
  rateLimitUser('refresh', { window: 60, limit: 60 }),
  refresh
);

// (Opcional) logout server-side
// router.post('/logout', verifyToken, rateLimitUser('logout', { window: 60, limit: 30 }), logout);

// Privadas (JWT) con rate limit moderado por usuario
router.get('/usuario',
  verifyToken,
  rateLimitUser('get_usuario', { window: 60, limit: 200 }),
  getUsuario
);

router.get('/whoami',
  verifyToken,
  rateLimitUser('whoami', { window: 60, limit: 200 }),
  whoami
);

// ====================================================================
// Utilidades (públicas): existe-correo
// ====================================================================
router.post('/existe-correo',
  rateLimitPublic('pwd_recovery_check', { window: 60, limit: 30 }),
  // captchaMiddleware('pwd_recovery_check'),
  existeCorreo
);

// Google util: SIN CAPTCHA (verifica con Google)
router.post('/existe-correo/google',
  rateLimitPublic('gid_check', { window: 60, limit: 60 }),
  existeCorreoPorIdToken
);

module.exports = router;

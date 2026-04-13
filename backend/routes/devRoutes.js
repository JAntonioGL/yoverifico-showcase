// routes/devRoutes.js
const express = require('express');
const router = express.Router();
const verifyToken = require('../middlewares/verifyToken');

const { 
  loginSinCaptcha,
  enviarNotificacionesPendientes,
  enviarNotificacionDePrueba,
  registroSinCaptcha
} = require('../controllers/devController');

router.get('/dev/ping', (req, res) => {
  res.json({ ok: true, where: '/api/dev/ping' });
});

router.post('/dev/login', loginSinCaptcha);

router.get('/dev/whoami', verifyToken, (req, res) => {
  res.json({ usuarioId: req.usuarioId, entitlements: req.entitlements });
});

router.post('/dev/registro', registroSinCaptcha);

router.post('/dev/enviar-pendientes', enviarNotificacionesPendientes);
router.post('/dev/notificacion-prueba', enviarNotificacionDePrueba);

module.exports = router;

const express = require('express');
const router = express.Router();
const verifyToken = require('../middlewares/verifyToken');
const verifyAdminKey = require('../middlewares/verifyAdminKey');
const { rateLimitUser, rateLimitPublic } = require('../middlewares/rateLimit');

const {
  programarNotificacion,
  programarContingenciaFanout,
  listarPendientes,
  marcarEnviada,
  programarManual,
  programarCancelacionContingencia,
  getEstadoContingencia,
} = require('../controllers/notificacionController');

// ------------------------------------------------------------
// 🔒 RUTAS PROTEGIDAS (requieren JWT del usuario autenticado)
// ------------------------------------------------------------

// Programar notificación normal (por vehículo o global)
router.post('/programar', rateLimitUser('prog_noti', { window: 60, limit: 200 }), verifyToken, programarNotificacion);

// Programar notificación de contingencia (solo usuarios válidos)
router.post('/contingencia', verifyAdminKey, programarContingenciaFanout);

// Programar notificación de CANCELACION de contingencia (solo usuarios válidos)
router.post('/contingencia/cancelar', verifyAdminKey, programarCancelacionContingencia);

// Agrega rateLimitUser y verifyToken para protegerla igual que '/programar'
router.get('/contingencia/consulta', rateLimitUser('consulta_cont', { window: 60, limit: 30 }), verifyToken, getEstadoContingencia);

// Marcar una notificación como enviada (usado por el worker tras enviar con FCM)
router.post('/marcar-enviada', marcarEnviada);

// ------------------------------------------------------------
// ⚙️  RUTAS ADMIN O INTERNAS (opcional, usa verifyToken si lo deseas)
// ------------------------------------------------------------

// Listar notificaciones pendientes (usado por cron o admin)
router.get('/pendientes', listarPendientes);

// Encolar notificación manual inmediata (para pruebas desde Postman)
router.post('/manual', verifyAdminKey, programarManual);


// ------------------------------------------------------------
module.exports = router;

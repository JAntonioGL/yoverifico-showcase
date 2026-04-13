// routes/actionsRoutes.js
const express = require('express');
const router = express.Router();

const verifyToken = require('../middlewares/verifyToken');
const concederSiSuave = require('../middlewares/concederSiSuave');
const { rateLimitUser } = require('../middlewares/rateLimit');

const actionsController = require('../controllers/actionsController');

// =====================================================
// PRECHEQUEO: el cliente pregunta si la acción requiere anuncio
// =====================================================
router.post(
    '/:nombre_accion/prechequeo',
    verifyToken,
    rateLimitUser('accion_precheck', { window: 60, limit: 100 }), // 100/min por usuario
    actionsController.prechequeoAccion
);

// =====================================================
// EJECUTAR: acción real, puede modificar datos o consumir pase
// =====================================================
router.post(
    '/:nombre_accion/ejecutar',
    verifyToken,
    rateLimitUser('accion_execute', { window: 60, limit: 20 }), // 20/min por usuario
    concederSiSuave,
    actionsController.ejecutarAccion
);

module.exports = router;

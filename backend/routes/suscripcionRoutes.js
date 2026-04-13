// routes/suscripciones.js
const express = require('express');
const router = express.Router();

const {
  obtenerSuscripciones,
  verificarSuscripcion,
  upgradePorPlanId,
  upgradePorCodigo,
  upgradePorPlay,
} = require('../controllers/suscripcionController'); // Se corrigió la ruta para que coincida con el nombre del archivo

const verifyToken = require('../middlewares/verifyToken');

// Lista de planes (catálogo)
router.get('/', verifyToken, obtenerSuscripciones);

// Verificar suscripción con purchaseToken (consulta directa a Play)
router.post('/verificar', verifyToken, verificarSuscripcion);

// ------- Upgrades -------
// 1) Upgrade directo por id_plan
router.post('/upgrade/plan-id', verifyToken, upgradePorPlanId);

// 2) Upgrade por código del plan
router.post('/upgrade/codigo', verifyToken, upgradePorCodigo);

// 3) Upgrade por compra en Play
router.post('/upgrade/play', verifyToken, upgradePorPlay);

module.exports = router;

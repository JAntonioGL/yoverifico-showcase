// routes/adsRoutes.js
const express = require('express');
const router = express.Router();

const verifyToken = require('../middlewares/verifyToken');
const ADS = require('../config/adsConfig');

// Importa tus controladores (impleméntalos en controllers/adsController.js)
const adsController = require('../controllers/adsController');

// GET /api/anuncios/configuracion
// Devuelve banderas remotas para el cliente (opcional, útil para feature flags)
router.get('/configuracion', (req, res) => {
  res.json({
    anuncios_habilitados: ADS.anuncios_habilitados,
    modo_aplicacion: ADS.modo_aplicacion,
    rewarded_habilitado: ADS.rewarded_habilitado,
    interstitial_intervalo_min_seg: ADS.interstitial_intervalo_min_seg,
  });
});

// POST /api/anuncios/recompensado/intentarlo
// Protegido: usuario autenticado pide datos_custom para inyectar en el anuncio (lleva 'folio')
router.post('/recompensado/intentarlo', verifyToken, adsController.intentoRecompensado);

// POST /api/anuncios/ssv/google
// Webhook público llamado por AdMob al completar el anuncio.
// Valida firma/secret en el propio controlador.
router.post('/ssv/google', adsController.webhookSSVGoogle);
router.get('/ssv/google', adsController.webhookSSVGoogle);

module.exports = router;

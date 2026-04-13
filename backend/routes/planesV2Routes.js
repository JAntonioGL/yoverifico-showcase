// routes/planesV2Routes.js
const express = require('express');
const router = express.Router();

const verifyToken = require('../middlewares/verifyToken');
const verifyGoogleOidc = require('../middlewares/verifyGoogleOidc');
const { rateLimitUser, rateLimitPublic } = require('../middlewares/rateLimit');

const {
  obtenerCatalogo,
  entitlement,
  upgradePorPlay,
  downgradeSchedule,
  downgradeCancel,
  verify,
  rtdnWebhook,
} = require('../controllers/planesV2Controller');

// ---------- App (JWT) ----------
router.get(
  '/catalogo',
  verifyToken,
  rateLimitUser('plans_catalog', { window: 60, limit: 120 }),   // lectura: laxo
  obtenerCatalogo
);

router.get(
  '/entitlement',
  verifyToken,
  rateLimitUser('plans_entitlement', { window: 60, limit: 120 }), // lectura: laxo
  entitlement
);

// Escrituras: más estrictas (y en el controller maneja Idempotency-Key si puedes)
router.post(
  '/upgrade/play',
  verifyToken,
  rateLimitUser('plans_upgrade', { window: 60, limit: 20 }),    // write: estricto
  upgradePorPlay
);

router.post(
  '/downgrade/schedule',
  verifyToken,
  rateLimitUser('plans_downgrade_sched', { window: 60, limit: 20 }),
  downgradeSchedule
);

router.post(
  '/downgrade/cancel',
  verifyToken,
  rateLimitUser('plans_downgrade_cancel', { window: 60, limit: 30 }),
  downgradeCancel
);

router.post(
  '/verify',
  verifyToken,
  rateLimitUser('plans_verify', { window: 60, limit: 60 }),     // consulta verificación (moderado)
  verify
);

// ---------- Webhook Pub/Sub (Google) ----------
// Nota: evitar rate-limit aquí; confía en OIDC y deduplicación por eventId.
// Si AÚN quieres un límite de seguridad, ponlo alto y con burst adecuado.
const acceptJson = (req, res, next) => {
  const ct = (req.headers['content-type'] || '').toLowerCase();
  if (!ct.includes('application/json')) {
    return res.status(415).json({ msg: 'Content-Type debe ser application/json' });
  }
  return next();
};

router.post(
  '/rtdn/webhook',
  acceptJson,
  express.json({ type: (h) => String(h).toLowerCase().includes('application/json') }),
  verifyGoogleOidc(),    // Autenticación de Google
  // rateLimitPublic('rtdn_webhook', { window: 60, limit: 600 }), // <- solo si insistes; no recomendado
  rtdnWebhook
);

module.exports = router;

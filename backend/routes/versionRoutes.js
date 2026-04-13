// routes/versionRoutes.js
const express = require('express');
const router = express.Router();

const { getVersionPolicy } = require('../controllers/versionController');
const verifyToken = require('../middlewares/verifyToken');
const { rateLimitUser } = require('../middlewares/rateLimit');

// Consulta de política de versión (usada pocas veces por sesión)
router.get(
    '/politica',
    verifyToken,
    rateLimitUser('version_policy', { window: 300, limit: 10 }), // máx. 10 consultas cada 5 min por usuario
    getVersionPolicy
);

module.exports = router;

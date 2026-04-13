// routes/bugsRoutes.js
const express = require('express');
const router = express.Router();

const { crearTicket } = require('../controllers/ticketsController');
const verifyToken = require('../middlewares/verifyToken');
const { rateLimitUser } = require('../middlewares/rateLimit');

// Un solo paso: crea ticket + sube imágenes (multipart)
router.post(
  '/',
  verifyToken,
  rateLimitUser('bug_report', { window: 300, limit: 5 }), // 5 reportes / 5 min por usuario
  crearTicket
);

module.exports = router;

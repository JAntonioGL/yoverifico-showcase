// routes/adminBugsRoutes.js
const express = require('express');
const router = express.Router();

const { adminLeerTickets, adminActualizarTicket } = require('../controllers/ticketsController');
const verifyAdminKey = require('../middlewares/verifyAdminKey');
const { rateLimitUser } = require('../middlewares/rateLimit');
// Lectura (lista / detalle / imagen binaria) por un solo endpoint
router.get(
    '/',
    verifyAdminKey, // valida X-Admin-Key
    rateLimitUser('admin_bugs_read', { window: 60, limit: 120 }),
    adminLeerTickets
);

// Actualizar estado/comentarios
router.post(
    '/:id',
    verifyAdminKey,
    rateLimitUser('admin_bugs_update', { window: 60, limit: 60 }),
    adminActualizarTicket
);

module.exports = router;

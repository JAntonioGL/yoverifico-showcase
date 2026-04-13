// routes/vehiculoRoutes.js
const express = require('express');
const router = express.Router();

const {
  guardarVehiculo,
  obtenerVehiculosUsuario,
  eliminarVehiculo,
  actualizarVerificacion
} = require('../controllers/vehiculoController');

const verifyToken = require('../middlewares/verifyToken');
const { rateLimitUser } = require('../middlewares/rateLimit');

// Crear vehículo (write → límite más estricto)
router.post('/',
  verifyToken,
  rateLimitUser('vehiculo_create', { window: 60, limit: 10 }),   // 10/min por usuario
  guardarVehiculo
);

// Listar vehículos (read → más laxo)
router.get('/mis-vehiculos',
  verifyToken,
  rateLimitUser('vehiculo_list', { window: 60, limit: 200 }),    // 200/min por usuario
  obtenerVehiculosUsuario
);

// Eliminar vehículo (write → estricto)
router.delete('/eliminar/:id_vehiculo',
  verifyToken,
  rateLimitUser('vehiculo_delete', { window: 60, limit: 10 }),   // 10/min por usuario
  eliminarVehiculo
);

// Actualizar verificación (write → intermedio)
router.post('/verificacion',
  verifyToken,
  rateLimitUser('vehiculo_verif_update', { window: 60, limit: 30 }), // 30/min por usuario
  actualizarVerificacion
);

module.exports = router;

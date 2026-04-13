/**
 * YoVerifico Backend - Entry Point (Showcase Version)
 * * Este archivo demuestra la orquestación del servidor Express, 
 * integrando capas de seguridad, gestión de estados con Redis y 
 * modularización de rutas.
 */

require('dotenv').config();
const express = require('express');
const admin = require('firebase-admin');

// --- Capas de Seguridad y Configuración ---
const {
    httpsAndHeaders,
    attachRateLimits,
    otpLimiter,
    requireAdminKey
} = require('./security');

const verifyToken = require('./middlewares/verifyToken');

// --- Importación de Rutas (Modularización) ---
const authRoutes = require('./routes/authRoutes');
const vehiculoRoutes = require('./routes/vehiculoRoutes');
const planesV2Routes = require('./routes/planesV2Routes');
const bugsRoutes = require('./routes/bugsRoutes');
// ...otras rutas (notificaciones, anuncios, suscripciones)

const app = express();

// 1. Configuración de Seguridad Global
httpsAndHeaders(app);    // Seguridad de cabeceras (Helmet, etc.)
attachRateLimits(app);   // Rate limiting global basado en Redis

// 2. Rutas Públicas con Rate Limiting Específico
// Se aplica un limiter estricto antes de entrar al router de autenticación
app.use('/api/auth/otp', otpLimiter(), authRoutes);

// 3. Rutas Protegidas por JWT
// Demostración de desacoplamiento: Middleware de verificación antes de la lógica
app.use('/api/vehiculos', verifyToken, vehiculoRoutes);
app.use('/api/bugs', verifyToken, bugsRoutes);

// 4. Rutas Administrativas
// Protegidas por validación de API Key y opcionalmente Allowlist de IPs
app.use('/api/admin', requireAdminKey, planesV2Routes);

// 5. Manejo de Errores y 404
app.use(/^\/api(\/|$)/, (req, res) => res.status(404).json({ msg: 'Not Found' }));

// 6. Inicialización del Servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    // Al arrancar, el sistema realiza un "Preflight Check" de:
    // - Conectividad con Redis para Rate Limiting.
    // - Existencia de directorios de adjuntos y logs.
    // - Configuración efectiva de entorno (Prod vs Dev).
    console.log(`🚀 Backend YoVerifico listo en puerto ${PORT}`);
});
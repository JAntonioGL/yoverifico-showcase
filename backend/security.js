// Ejemplo de lo que subirías (security.js.sample)
function httpsAndHeaders(app) {
    app.disable('x-powered-by');
    // Redirección HTTPS forzada en producción
    // Configuración de CORS basada en dominios autorizados en .env
    app.use(helmet());
}

function otpLimiter() {
    // Rate limit estricto para proteger el flujo de autenticación
    return rateLimit({ windowMs: 60000, max: 1 });
}
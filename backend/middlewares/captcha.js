/**
 * Auth Middleware - Token Verification & Entitlements inyectión
 * * Este middleware protege las rutas privadas, valida la integridad del JWT 
 * y mapea los privilegios del usuario (plan, anuncios, límites) directamente 
 * al objeto 'req' para optimizar las consultas a la base de datos.
 */

const jwt = require('jsonwebtoken');

module.exports = function verifyToken(req, res, next) {
  // 1. Extracción del esquema Bearer
  const auth = req.headers.authorization || '';
  if (!auth.startsWith('Bearer ')) {
    return res.status(401).json({ msg: 'Authorization header missing or malformed' });
  }
  const token = auth.slice(7);

  try {
    // 2. Configuración de Verificación con Tolerancia de Reloj
    const verifyOpts = {
      algorithms: ['HS256'],
      clockTolerance: 5, // 5 segundos de margen para desincronización de dispositivos
      audience: process.env.JWT_AUDIENCE,
      issuer: process.env.JWT_ISSUER
    };

    const decoded = jwt.verify(token, process.env.JWT_SECRET, verifyOpts);

    // 3. Normalización y Validación de Identidad
    const usuarioId = Number(decoded.id ?? decoded.uid ?? decoded.sub);
    if (!usuarioId || usuarioId <= 0) throw new Error('Invalid User ID');
    
    req.usuarioId = usuarioId;

    // 4. Inyección de Contexto de Suscripción (Entitlements)
    // Extraemos los límites directamente del claim del JWT para evitar I/O innecesario
    req.entitlements = {
      plan: decoded.plan || 'FREE',
      con_anuncios: decoded.ads === true,
      maximo_vehiculos: Number(decoded.maxVehiculos) || 1
    };

    next();
  } catch (e) {
    // Captura tanto errores de firma como tokens expirados
    return res.status(401).json({ msg: 'Token invalid or expired' });
  }
};
// middlewares/verifyToken.js
const jwt = require('jsonwebtoken');

module.exports = function verifyToken(req, res, next) {
  const auth = req.headers.authorization || '';
  if (!auth.startsWith('Bearer ')) {
    return res.status(401).json({ msg: 'Token no enviado (use Authorization: Bearer <jwt>)' });
  }
  const token = auth.slice(7);

  try {
    // Opcionalmente fuerza aud/iss si están definidos en el entorno
    const verifyOpts = {
      algorithms: ['HS256'],
      clockTolerance: 5 // seg de holgura por reloj
    };
    if (process.env.JWT_AUDIENCE) verifyOpts.audience = process.env.JWT_AUDIENCE;
    if (process.env.JWT_ISSUER)   verifyOpts.issuer   = process.env.JWT_ISSUER;

    const decoded = jwt.verify(token, process.env.JWT_SECRET, verifyOpts);

    // Normaliza el ID de usuario desde id/uid/sub (lo que emita tu login)
    const rawId = decoded.id ?? decoded.uid ?? decoded.sub;
    const usuarioId = Number(rawId);
    if (!Number.isFinite(usuarioId) || usuarioId <= 0) {
      return res.status(401).json({ msg: 'Token inválido (id ausente o no numérico)' });
    }
    req.usuarioId = usuarioId;

    // Entitlements como usas hoy
    const plan = decoded.plan || 'FREE';
    const ads  = decoded.ads === true;
    let maxVehiculos = Number(decoded.maxVehiculos);
    if (!Number.isFinite(maxVehiculos) || maxVehiculos <= 0) maxVehiculos = 1;

    req.plan = plan;
    req.ads  = ads;
    req.maxVehiculos = maxVehiculos;
    req.entitlements = {
      plan,
      con_anuncios: ads,
      maximo_vehiculos: maxVehiculos,
    };

    return next();
  } catch (e) {
    return res.status(401).json({ msg: 'Token inválido o expirado' });
  }
};

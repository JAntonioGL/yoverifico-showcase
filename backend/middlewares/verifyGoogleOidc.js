// Middleware OIDC para Pub/Sub push (factory)
const { OAuth2Client } = require('google-auth-library');

module.exports = function verifyGoogleOidc() {
  const audience = process.env.RTDN_AUDIENCE; // p.ej. yv-rtdn
  const saEmail  = process.env.RTDN_SA_EMAIL; // p.ej. pubsub-push@yoverifico.iam.gserviceaccount.com
  const allowAdminKey = String(process.env.RTDN_ALLOW_ADMIN_KEY || 'false') === 'true';
  const adminKey = process.env.ADMIN_API_KEY || '';

  const client = new OAuth2Client();

  return async function (req, res, next) {
    try {
      // Fallback dev: x-admin-key
      const xKey = req.header('x-admin-key');
      if (allowAdminKey && adminKey && xKey === adminKey) return next();

      const authz = req.header('authorization') || req.header('Authorization');
      if (!authz || !authz.startsWith('Bearer ')) {
        return res.status(401).json({ ok:false, msg:'Falta Authorization Bearer' });
      }

      const idToken = authz.slice('Bearer '.length);
      const ticket = await client.verifyIdToken({ idToken, audience });
      const payload = ticket.getPayload();

      // iss válido
      const iss = payload.iss || '';
      if (!(iss === 'https://accounts.google.com' || iss === 'accounts.google.com')) {
        return res.status(401).json({ ok:false, msg:'Issuer inválido' });
      }

      // email del emisor (service account que pusiste en --push-auth-service-account)
      const email = payload.email || null;
      if (!email || email.toLowerCase() !== String(saEmail || '').toLowerCase()) {
        return res.status(401).json({ ok:false, msg:'Service Account no permitida' });
      }

      return next();
    } catch (e) {
      console.error('[OIDC] verify error:', e?.message || e);
      return res.status(401).json({ ok:false, msg:'Token OIDC inválido' });
    }
  };
};

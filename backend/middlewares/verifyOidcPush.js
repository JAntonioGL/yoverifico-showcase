// middlewares/verifyOidcPush.js
const jwt = require('jsonwebtoken');
const jwksRsa = require('jwks-rsa');

const AUDIENCE = process.env.OIDC_AUDIENCE || 'yv-rtdn';
const ALLOWED_ISSUERS = (process.env.OIDC_ALLOWED_ISSUERS || 'https://accounts.google.com')
    .split(',').map(s => s.trim()).filter(Boolean);
const ALLOWED_EMAILS = (process.env.OIDC_ALLOWED_EMAILS || '')
    .split(',').map(s => s.trim().toLowerCase()).filter(Boolean);

// JWKS de Google (caché automático)
const jwksClient = jwksRsa({
    jwksUri: 'https://www.googleapis.com/oauth2/v3/certs',
    cache: true,
    cacheMaxEntries: 5,
    cacheMaxAge: 10 * 60 * 1000, // 10 min
});

function getKey(header, callback) {
    jwksClient.getSigningKey(header.kid, (err, key) => {
        if (err) return callback(err);
        const signingKey = key.getPublicKey();
        callback(null, signingKey);
    });
}

module.exports = function verifyOidcPush(req, res, next) {
    try {
        const auth = req.headers.authorization || '';
        const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
        if (!token) return res.status(401).json({ ok: false, msg: 'Missing Bearer token' });

        jwt.verify(
            token,
            getKey,
            {
                algorithms: ['RS256'],
                audience: AUDIENCE,
                issuer: ALLOWED_ISSUERS,
            },
            (err, payload) => {
                if (err) return res.status(401).json({ ok: false, msg: 'Invalid OIDC token' });

                // Validar email de la SA que empuja el mensaje
                const email = String(payload.email || '').toLowerCase();
                if (ALLOWED_EMAILS.length && !ALLOWED_EMAILS.includes(email)) {
                    return res.status(403).json({ ok: false, msg: 'Caller not allowed', email });
                }

                // opcional: exponer payload por si lo quieres usar en el handler
                req.oidc = payload;
                next();
            }
        );
    } catch (e) {
        return res.status(401).json({ ok: false, msg: 'Auth error' });
    }
};

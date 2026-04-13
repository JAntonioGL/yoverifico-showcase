// middlewares/rateLimit.js
const { getRedis } = require('../utils/redisClient');

// ==== helpers entorno/keys ====
const IS_PROD = process.env.NODE_ENV === 'production';
const RL_DISABLED = String(process.env.RL_DISABLE || 'false') === 'true';

const ALLOW_IPS = (process.env.RL_ALLOW_IPS || '')
    .split(',').map(s => s.trim()).filter(Boolean);

const BYPASS_WITH_ADMIN = String(process.env.RL_BYPASS_WITH_ADMIN_KEY || 'false') === 'true';
const ADMIN_API_KEY = process.env.ADMIN_API_KEY || '';

function clientIp(req) {
    // requiere trust proxy=1 en prod para que req.ip refleje x-forwarded-for
    const xff = (req.headers['x-forwarded-for'] || '').split(',')[0].trim();
    const ip = req.ip || xff || req.headers['x-real-ip'] || req.socket?.remoteAddress || '';
    return (ip || '').replace('::ffff:', '');
}

function isAllowlisted(req) {
    if (BYPASS_WITH_ADMIN && ADMIN_API_KEY) {
        const key = req.headers['x-admin-key'];
        if (key && key === ADMIN_API_KEY) return true;
    }
    const ip = clientIp(req);
    return ALLOW_IPS.includes(ip);
}

// ==== valores por defecto (puedes moverlos a .env) ====
const DEF_WINDOW = Number(process.env.RL_WINDOW_SEC || 60);

const DEF_IP_MAX = Number(process.env.RL_IP_MAX || 300);
const DEF_USER_MAX = Number(process.env.RL_USER_MAX || 120);
const DEF_WRITE_MAX = Number(process.env.RL_WRITE_USER_MAX || 40);

// ==== rate limiter genérico (ventana deslizante con INCR + TTL) ====
// options: { bucket, window, limit, by: 'ip'|'user'|'custom', keyBuilder }
function rateLimiter(options = {}) {
    const {
        bucket = 'generic',
        window = DEF_WINDOW,
        limit,                // si no viene, se deduce según 'by' y método
        by = 'ip',            // 'ip' | 'user' | 'custom'
        keyBuilder,           // fn(req) -> string  (si by='custom')
        failOpen = true,      // si Redis falla: true=deja pasar
        setHeaders = true,    // agrega headers tipo X-RateLimit-*
    } = options;

    return async (req, res, next) => {
        try {
            // 1) Entorno: bypass en development o si RL_DISABLE=true
            if (!IS_PROD || RL_DISABLED) return next();

            // 2) Excepciones (allowlist / admin key)
            if (isAllowlisted(req)) return next();

            // 3) Construir clave
            let subjectKey;
            if (by === 'ip') {
                subjectKey = clientIp(req) || '0.0.0.0';
            } else if (by === 'user') {
                // ajusta según dónde pongas el id del usuario (verifyToken)
                const userId = req.usuarioId || req.user?.id || req.userId;
                if (!userId) {
                    // si no hay usuario, cae a IP para no dejar huecos
                    subjectKey = `anon:${clientIp(req) || '0.0.0.0'}`;
                } else {
                    subjectKey = `u:${userId}`;
                }
            } else if (by === 'custom' && typeof keyBuilder === 'function') {
                subjectKey = keyBuilder(req);
            } else {
                subjectKey = clientIp(req) || '0.0.0.0';
            }

            // 4) Límite por defecto según método/tipo
            const isWrite = ['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method);
            const effLimit = Number(
                limit ??
                (by === 'user' ? (isWrite ? DEF_WRITE_MAX : DEF_USER_MAX) : DEF_IP_MAX)
            );

            // 5) INCR + TTL (ventana deslizante sencilla)
            const redis = getRedis();
            if (redis.status !== 'ready') await redis.connect();

            const key = `rl:${bucket}:${subjectKey}`;
            // INCR devuelve el contador actual; si es 1, ponemos TTL
            const count = await redis.incr(key);
            if (count === 1) {
                await redis.expire(key, window);
            }
            const ttl = await redis.ttl(key); // segundos restantes de la ventana
            const remaining = Math.max(0, effLimit - count);

            // 6) Headers informativos (opcionales)
            if (setHeaders) {
                res.setHeader('X-RateLimit-Limit', String(effLimit));
                res.setHeader('X-RateLimit-Remaining', String(Math.max(0, remaining)));
                res.setHeader('X-RateLimit-Reset', String(Math.max(0, ttl)));
            }

            // 7) Aplicar decisión
            if (count > effLimit) {
                // opcional: Retry-After (segundos hasta reset)
                res.setHeader('Retry-After', String(Math.max(1, ttl)));
                return res.status(429).json({ ok: false, error: 'too_many_requests' });
            }

            return next();

        } catch (e) {
            console.error('[rateLimit] error:', e.message);
            // Fail-open recomendado para no tumbar tráfico por caída de Redis
            if (options.failOpen !== false) return next();
            return res.status(503).json({ ok: false, error: 'rate_limit_unavailable' });
        }
    };
}

// ==== atajos convenientes ====
function rateLimitPublic(bucket, opts = {}) {
    // por IP (más estricto si necesitas), ideal para OTP/login/registro
    return rateLimiter({ by: 'ip', bucket, ...opts });
}

function rateLimitUser(bucket, opts = {}) {
    // por usuario autenticado (menos agresivo), ideal para rutas con JWT
    return rateLimiter({ by: 'user', bucket, ...opts });
}

module.exports = {
    rateLimiter,
    rateLimitPublic,
    rateLimitUser,
};

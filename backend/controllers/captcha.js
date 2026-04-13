// captcha.js
const axios = require('axios');

function clientIp(req) {
  // Igual que tu helper: normaliza IPv4 detrás de IPv6.
  return (req?.ip || '').replace('::ffff:', '') || '0.0.0.0';
}

/**
 * Verifica reCAPTCHA v3 con soporte de bypass:
 * - Dev (NODE_ENV !== 'production') => bypass
 * - Prod + x-admin-key válido (si CAPTCHA_BYPASS_WITH_ADMIN_KEY='true') => bypass
 * - Prod + IP allowlist (CAPTCHA_ALLOW_IPS) => bypass
 *
 * @param {Object} opts
 * @param {string} opts.token - captcha token del cliente (puede omitirse si hay bypass)
 * @param {string} [opts.expectedAction] - acción esperada (p.ej. 'otp_request')
 * @param {number} [opts.minScore=0.5] - score mínimo de reCAPTCHA v3
 * @param {Object} [opts.req] - request de Express para leer headers/IP
 * @returns {Promise<{ok:boolean, reason?:string, score?:number, action?:string, bypass?:boolean}>}
 */
async function verifyCaptcha({ token, expectedAction, minScore = 0.5, req } = {}) {
  const isProd = process.env.NODE_ENV === 'production';

  // 1) BYPASS AUTOMÁTICO EN NO-PROD
  if (!isProd) {
    return { ok: true, bypass: true, reason: 'non_production' };
  }

  // 2) BYPASS EN PROD CON ADMIN KEY
  if (process.env.CAPTCHA_BYPASS_WITH_ADMIN_KEY === 'true' && req) {
    const headerKey = req.headers['x-admin-key'];
    if (headerKey && process.env.ADMIN_API_KEY && headerKey === process.env.ADMIN_API_KEY) {
      return { ok: true, bypass: true, reason: 'admin_key' };
    }
  }

  // 3) BYPASS EN PROD POR IP ALLOWLIST
  if (process.env.CAPTCHA_ALLOW_IPS && req) {
    const allow = process.env.CAPTCHA_ALLOW_IPS.split(',').map(s => s.trim()).filter(Boolean);
    if (allow.length > 0) {
      const ip = clientIp(req);
      if (allow.includes(ip)) {
        return { ok: true, bypass: true, reason: 'allowlisted_ip' };
      }
    }
  }

  // 4) SIN BYPASS → VALIDAR CAPTCHA NORMALMENTE
  if (!token) return { ok: false, reason: 'missing' };

  const { data } = await axios.post(
    'https://www.google.com/recaptcha/api/siteverify',
    null,
    {
      params: {
        secret: process.env.RECAPTCHA_SECRET_KEY,
        response: token,
      },
      timeout: 5000,
    }
  );

  // data: { success, score, action, ... }
  if (!data?.success) return { ok: false, reason: 'failed' };

  if (expectedAction && data.action !== expectedAction) {
    return { ok: false, reason: 'bad_action', action: data.action };
  }

  if (typeof data.score === 'number' && data.score < minScore) {
    return { ok: false, reason: 'low_score', score: data.score };
  }

  return { ok: true, score: data.score, action: data.action };
}

module.exports = { verifyCaptcha };

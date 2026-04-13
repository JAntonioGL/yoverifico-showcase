// utils/captcha.js
const axios = require('axios');

function clientIp(req) {
  return (req?.ip || '').replace('::ffff:', '') || '0.0.0.0';
}

function isProdLike() {
  return process.env.NODE_ENV === 'production' ||
         String(process.env.CAPTCHA_SIMULATE_PROD || 'false') === 'true';
}

function resolveMinScore() {
  const explicit = Number(process.env.CAPTCHA_MIN_SCORE);
  if (!Number.isNaN(explicit) && explicit >= 0 && explicit <= 1) {
    return explicit;
  }
  if (isProdLike()) return 0.5;
  if (String(process.env.CAPTCHA_RELAX_DEV ?? 'true') === 'true') return 0.1;
  return 0.5;
}

/**
 * verifyCaptcha
 * @param {Object} opts
 * @param {string} opts.token
 * @param {string} [opts.expectedAction]
 * @param {number} [opts.minScore]
 * @param {Object} [opts.req]
 */
async function verifyCaptcha2({ token, expectedAction, minScore, req } = {}) {
  const prodLike = isProdLike();
  const effMinScore = typeof minScore === 'number' ? minScore : resolveMinScore();

  // 1) BYPASS en dev (si NO simulamos prod)
  if (!prodLike) {
    return {
      ok: true,
      bypass: true,
      reason: 'non_production_bypass',
      score: 0.9,
      action: expectedAction || null,
      minScore: effMinScore,
      details: null,
    };
  }

  // 2) BYPASS con admin key (opcional)
  if (process.env.CAPTCHA_BYPASS_WITH_ADMIN_KEY === 'true' && req) {
    const headerKey = req.headers['x-admin-key'];
    if (headerKey && process.env.ADMIN_API_KEY && headerKey === process.env.ADMIN_API_KEY) {
      return {
        ok: true,
        bypass: true,
        reason: 'admin_key',
        score: 0.9,
        action: expectedAction || null,
        minScore: effMinScore,
        details: null,
      };
    }
  }

  // 3) BYPASS por IP allowlist (opcional)
  if (process.env.CAPTCHA_ALLOW_IPS && req) {
    const allow = process.env.CAPTCHA_ALLOW_IPS.split(',').map(s => s.trim()).filter(Boolean);
    if (allow.length > 0) {
      const ip = clientIp(req);
      if (allow.includes(ip)) {
        return {
          ok: true,
          bypass: true,
          reason: 'allowlisted_ip',
          score: 0.9,
          action: expectedAction || null,
          minScore: effMinScore,
          details: null,
        };
      }
    }
  }

  // 4) Validación normal
  if (!token) return { ok: false, reason: 'missing', minScore: effMinScore };

  let data;
  try {
    const resp = await axios.post(
      'https://www.google.com/recaptcha/api/siteverify',
      null,
      {
        params: {
          secret: process.env.RECAPTCHA_SECRET_KEY,
          response: token,
        },
        timeout: 10000,
      }
    );
    data = resp.data || {};
  } catch (e) {
    // Loguea para debug del servidor si quieres:
    console.error('[reCAPTCHA axios error]', e?.message || e);
    return { ok: false, reason: 'network_error', error: e?.message, minScore: effMinScore };
  }

  // data: { success, score, action, hostname, 'error-codes' }
  if (!data?.success) {
    return { ok: false, reason: 'failed', details: data, minScore: effMinScore };
  }

  if (expectedAction && data.action !== expectedAction) {
    return { ok: false, reason: 'bad_action', action: data.action, details: data, minScore: effMinScore };
  }

  if (typeof data.score === 'number' && data.score < effMinScore) {
    return {
      ok: false,
      reason: 'low_score',
      score: data.score,
      action: data.action,
      details: data,
      minScore: effMinScore,
    };
  }

  return {
    ok: true,
    score: data.score,
    action: data.action,
    hostname: data.hostname,
    minScore: effMinScore,
    details: data,
  };
}

/** Mapea el resultado a status + body amigable para el front */
function mapCaptchaResultToHttp(result) {
  const r = result || {};
  const base = {
    ok: !!r.ok,
    reason: r.reason,
    score: r.score,
    action: r.action,
    hostname: r.hostname,
    bypass: r.bypass || false,
    minScore: r.minScore,
    details: r.details || null,
  };

  if (r.ok) {
    return {
      status: 200,
      body: { ...base, msg: r.bypass ? 'Captcha bypass (entorno no productivo)' : 'Captcha verificado' },
    };
  }

  const reason = r.reason;
  if (reason === 'missing') {
    return { status: 400, body: { ...base, msg: 'Falta token de reCAPTCHA' } };
  }
  if (reason === 'bad_action') {
    return { status: 403, body: { ...base, msg: `Acción inválida de reCAPTCHA (recibida: ${r.action})` } };
  }
  if (reason === 'low_score') {
    return {
      status: 403,
      body: {
        ...base,
        msg: `Score bajo (${r.score ?? 'N/A'}) < mínimo (${r.minScore})`,
      },
    };
  }
  if (reason === 'failed') {
    return {
      status: 403,
      body: { ...base, msg: 'Validación reCAPTCHA fallida', errors: r.details?.['error-codes'] || null },
    };
  }
  if (reason === 'network_error') {
    return { status: 502, body: { ...base, msg: 'Error de red verificando reCAPTCHA' } };
  }

  return { status: 400, body: { ...base, msg: 'No se pudo verificar reCAPTCHA' } };
}

module.exports = { verifyCaptcha2, mapCaptchaResultToHttp, clientIp };

require('dotenv').config();

const toBool = (v, def = false) => {
  if (v === undefined) return def;
  return ['1', 'true', 'yes', 'si', 'sí', 'on'].includes(String(v).toLowerCase());
};

const ADS = {
  anuncios_habilitados: toBool(process.env.ANUNCIOS_HABILITADOS, true),
  modo_aplicacion: process.env.ADS_MODO_APLICACION || 'estricto', // 'estricto' | 'suave'
  // interstitial (si algún día lo usas como soft gate)
  interstitial_intervalo_min_seg: Number(process.env.INTERSTITIAL_INTERVALO_MIN_SEG || 120),

  // rewarded (pase)
  rewarded_habilitado: toBool(process.env.REWARDED_HABILITADO, true),

  // Seguridad SSV (webhook)
  admob_ssv_secreto: process.env.ADMOB_SSV_SECRETO || '', // si usas shared secret
  admob_unidades_permitidas: (process.env.ADMOB_AD_UNITS || '')
    .split(',')
    .map(s => s.trim())
    .filter(Boolean),

  // Diagnóstico
  log_detallado_ads: toBool(process.env.LOG_DETALLADO_ADS, false),
};

module.exports = ADS;

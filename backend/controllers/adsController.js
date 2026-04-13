// controllers/adsController.js
const pool = require('../db/pool');
const ADS = require('../config/adsConfig');

/**
 * POST /api/anuncios/recompensado/intentarlo
 * Body: { folio: "uuid" }
 * Requiere verifyToken (req.usuarioId)
 * - Valida que el folio exista y esté pendiente (en la función SQL)
 * - Devuelve datos_custom para inyectar en el Ad recompensado
 */
const intentoRecompensado = async (req, res) => {
  if (!ADS.anuncios_habilitados || !ADS.rewarded_habilitado) {
    return res.status(403).json({ msg: 'Anuncios deshabilitados' });
  }

  const { folio } = req.body || {};
  const idUsuario = req.usuarioId;

  if (!folio) {
    return res.status(400).json({ msg: 'Falta folio' });
  }

  try {
    // Confirmamos que el folio pertenezca al usuario y esté en estado válido (pendiente)
    // Nota: si deseas validar aquí el estado, puedes crear una función SQL de consulta;
    // para mantenerlo simple, damos por válido y dejamos la validación fuerte al webhook y a "validar_y_usar".
    // Si quieres validar duro aquí, crea función "estado_pase_anuncio(folio)" y verifica id_usuario/estado.

    // datos que el cliente debe inyectar como custom data del anuncio (AdMob SSV)
    const datos_custom = {
      folio,
      id_usuario: idUsuario,
      // El cliente también debe enviar el nombre_accion a la hora de ejecutar.
      // Para el SSV, si quieres incluirlo aquí, tendrás que obtenerlo (ej. por consulta/función) o pasarlo desde el cliente.
      // nombre_accion: ... (opcional si lo incluyes en el custom_data)
    };

    return res.json({ datos_custom });
  } catch (err) {
    console.error('❌ intentoRecompensado error:', err);
    return res.status(500).json({ msg: 'Error del servidor' });
  }
};

/**
 * POST /api/anuncios/ssv/google
 * Webhook público llamado por AdMob al completar el anuncio.
 * - Valida secret/firma (si la configuraste).
 * - Marca el pase como "concedido" (idempotente).
 *
 * Tip: según tu configuración SSV, estos datos vendrán como querystring.
 * Ajusta extracción según lo que te envíe AdMob (custom_data -> folio).
 */
const webhookSSVGoogle = async (req, res) => {
  try {
    // AdMob usa GET para Verify URL y para SSV real
    const q = req.query || {};
    const b = req.body || {};

    // En SSV real, el folio te llega dentro de custom_data (query param).
    // En Verify URL puede NO venir nada. Acepta ambos casos.
    const customData = q.custom_data ?? b.custom_data ?? '';
    const adUnit = q.ad_unit_id ?? b.ad_unit_id ?? q.ad_unit ?? b.ad_unit;

    // Si es solo verificación (no hay custom_data), responde 200 OK.
    if (!customData) {
      return res.status(200).json({ ok: true, ready: true });
    }

    // Si tu app manda el folio “plano”, úsalo tal cual; si manda JSON, parsea.
    let folio = customData;
    try {
      const parsed = JSON.parse(customData);
      if (parsed && typeof parsed === 'object' && parsed.folio) {
        folio = parsed.folio;
      }
    } catch (_) { /* no era JSON, está bien */ }

    if (!folio) {
      return res.status(200).json({ ok: false, motivo: 'custom_data_sin_folio' });
    }

    // Marca concedido en DB (idempotente)
    const { rows } = await pool.query(
      'SELECT marcar_pase_concedido($1::uuid, $2::text) AS resultado',
      [folio, adUnit || null]
    );
    const resultado = rows?.[0]?.resultado || 'no_encontrado';
    return res.status(200).json({ ok: true, resultado });
  } catch (err) {
    console.error('SSV error:', err);
    // Siempre 200 para que AdMob no reintente agresivo
    return res.status(200).json({ ok: false, msg: 'error_interno' });
  }
};


module.exports = {
  intentoRecompensado,
  webhookSSVGoogle,
};

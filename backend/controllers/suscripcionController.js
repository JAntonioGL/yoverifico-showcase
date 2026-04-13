const { google } = require('googleapis');
const pool = require('../db/pool');

// -------- Google Play helpers ----------
async function getPublisherClient() {
  const auth = new google.auth.GoogleAuth({
    keyFile: process.env.GOOGLE_SERVICE_ACCOUNT_KEY,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  const client = await auth.getClient();
  return google.androidpublisher({ version: 'v3', auth: client });
}

function priceFromGooglePrice(priceObj) {
  if (!priceObj) return null;
  const units = Number(priceObj.units || 0);
  const nanos = Number(priceObj.nanos || 0);
  return units + (nanos / 1e9);
}

// --- util: elegir un basePlan anual (P1Y) con precio MX, si hay varios ---
function pickAnnualMxBasePlan(basePlans) {
  if (!Array.isArray(basePlans)) return null;
  for (const bp of basePlans) {
    const isActive = bp?.state === 'ACTIVE';
    const period = bp?.autoRenewingBasePlanType?.billingPeriodDuration || null;
    if (!isActive || period !== 'P1Y') continue;
    const rcMx = (bp.regionalConfigs || []).find(rc => rc.regionCode === 'MX');
    if (rcMx?.price) {
      return { basePlanId: bp.basePlanId, period, mxPrice: rcMx.price };
    }
  }
  return null;
}

// ====== GET /api/suscripciones (precio desde Play; resto desde BD) ======
const obtenerSuscripciones = async (req, res) => {
  try {
    const packageName = process.env.ANDROID_PACKAGE_NAME;
    const publisher = await getPublisherClient();

    const { rows: planesDb } = await pool.query(`
      SELECT
        id, codigo, nombre, descripcion, maximo_vehiculos, con_anuncios,
        precio_mxn_anual, estado, caracteristicas,
        play_product_id
      FROM public.vista_planes_app
      WHERE estado = 'activo'
    `);

    const byProductId = new Map();
    for (const p of planesDb) if (p.play_product_id) byProductId.set(p.play_product_id, p);
    const freePlan = planesDb.find(p => p.codigo === 'FREE');

    const result = await publisher.monetization.subscriptions.list({ packageName });
    const subscriptions = result.data.subscriptions || [];

    const playPrices = new Map(); // productId -> { price, currency, period }
    for (const sub of subscriptions) {
      const productId = sub.productId;
      const picked = pickAnnualMxBasePlan(sub.basePlans);
      if (!picked) continue;

      const price = priceFromGooglePrice(picked.mxPrice);
      const currency = picked.mxPrice?.currencyCode || 'MXN';
      if (price == null) continue;

      if (!playPrices.has(productId)) {
        playPrices.set(productId, { price, currency, period: picked.period });
      }
    }

    const out = [];

    if (freePlan) {
      out.push({
        codigo: freePlan.codigo,
        nombre: freePlan.nombre,
        descripcion: freePlan.descripcion,
        maximo_vehiculos: freePlan.maximo_vehiculos,
        con_anuncios: freePlan.con_anuncios,
        caracteristicas: freePlan.caracteristicas,
        period: 'P1Y',
        price: 0,
        currency: 'MXN',
        es_de_pago: false,
        play: null,
      });
    } else {
      console.warn('[BD] No se encontró plan FREE en vista_planes_app');
    }

    for (const p of planesDb) {
      if (p.codigo === 'FREE') continue;
      if (!p.play_product_id) {
        console.warn(`[MAPPING] Plan BD sin play_product_id: ${p.codigo}`);
        continue;
      }

      const playInfo = playPrices.get(p.play_product_id);
      if (!playInfo) {
        console.warn(`[PLAY MISSING] No hay precio en Play para ${p.codigo} (productId=${p.play_product_id})`);
        continue;
      }

      const precioDb = Number(p.precio_mxn_anual || 0);
      if (precioDb > 0 && Math.abs(precioDb - playInfo.price) > 0.009) {
        console.warn(`[PRICE MISMATCH] ${p.codigo}: BD=${precioDb} vs PLAY=${playInfo.price} ${playInfo.currency}`);
      }

      out.push({
        codigo: p.codigo,
        nombre: p.nombre,
        descripcion: p.descripcion,
        maximo_vehiculos: p.maximo_vehiculos,
        con_anuncios: p.con_anuncios,
        caracteristicas: p.caracteristicas,
        period: playInfo.period || 'P1Y',
        price: playInfo.price,
        currency: playInfo.currency || 'MXN',
        es_de_pago: true,
        play: { productId: p.play_product_id },
      });
    }

    out.sort((a, b) => {
      if (a.codigo === 'FREE') return -1;
      if (b.codigo === 'FREE') return 1;
      const am = a.maximo_vehiculos ?? -1;
      const bm = b.maximo_vehiculos ?? -1;
      return bm - am;
    });

    return res.json(out);
  } catch (error) {
    console.error('Error al obtener suscripciones/planes:', error);
    return res.status(500).json({ msg: 'Error al obtener suscripciones/planes' });
  }
};

// ====== POST /api/suscripciones/verificar (igual) ======
const verificarSuscripcion = async (req, res) => {
  try {
    const { purchaseToken } = req.body;
    const packageName = process.env.ANDROID_PACKAGE_NAME;
    const publisher = await getPublisherClient();

    const result = await publisher.purchases.subscriptionsv2.get({
      packageName,
      token: purchaseToken,
    });

    res.json(result.data);
  } catch (error) {
    console.error('Error al verificar suscripción:', error);
    res.status(400).json({ msg: 'No se pudo verificar la suscripción' });
  }
};

// ===================== NUEVO: helpers upgrade =====================
async function existeReferenciaUsuario(idUsuario, referencia) {
  if (!referencia) return false;
  const { rows } = await pool.query(
    `SELECT 1 FROM public.usuarios_planes
      WHERE id_usuario = $1 AND referencia_externa = $2
      LIMIT 1`,
    [idUsuario, referencia]
  );
  return rows.length > 0;
}

async function asignarPlan({ idUsuario, idPlan, anios = 1, origen = 'api', referencia = null }) {
  await pool.query(
    `SELECT public.asignar_plan_usuario_anual_id($1, $2, $3, $4, $5)`,
    [idUsuario, idPlan, anios, origen, referencia]
  );
}

// ====== POST /api/suscripciones/upgrade/plan-id ======
const upgradePorPlanId = async (req, res) => {
  try {
    const idUsuario = req.usuarioId;
    if (!idUsuario) return res.status(401).json({ msg: 'No autenticado' });

    const { id_plan, anios = 1, origen = 'api', referencia = null } = req.body || {};
    if (!id_plan) return res.status(400).json({ msg: 'id_plan es requerido' });

    if (referencia && await existeReferenciaUsuario(idUsuario, referencia)) {
      return res.json({ ok: true, idempotent: true, msg: 'Upgrade ya aplicado previamente' });
    }

    // valida que exista el plan
    const { rows: exists } = await pool.query(
      `SELECT 1 FROM public.planes WHERE id = $1 LIMIT 1`,
      [id_plan]
    );
    if (!exists.length) return res.status(404).json({ msg: `No existe plan con id ${id_plan}` });

    await asignarPlan({
      idUsuario,
      idPlan: Number(id_plan),
      anios: Number(anios) || 1,
      origen,
      referencia,
    });

    return res.json({ ok: true });
  } catch (error) {
    console.error('upgradePorPlanId error:', error);
    return res.status(400).json({ msg: 'No se pudo asignar el plan' });
  }
};

// ====== POST /api/suscripciones/upgrade/codigo ======
const upgradePorCodigo = async (req, res) => {
  try {
    const idUsuario = req.usuarioId;
    if (!idUsuario) return res.status(401).json({ msg: 'No autenticado' });

    const { codigo, anios = 1, origen = 'api', referencia = null } = req.body || {};
    if (!codigo) return res.status(400).json({ msg: 'codigo es requerido' });

    const { rows } = await pool.query(
      `SELECT id FROM public.planes WHERE codigo = $1 LIMIT 1`,
      [codigo]
    );
    if (!rows.length) return res.status(404).json({ msg: `No existe plan con codigo ${codigo}` });

    if (referencia && await existeReferenciaUsuario(idUsuario, referencia)) {
      return res.json({ ok: true, idempotent: true, msg: 'Upgrade ya aplicado previamente' });
    }

    await asignarPlan({
      idUsuario,
      idPlan: rows[0].id,
      anios: Number(anios) || 1,
      origen,
      referencia,
    });

    return res.json({ ok: true });
  } catch (error) {
    console.error('upgradePorCodigo error:', error);
    return res.status(400).json({ msg: 'No se pudo asignar el plan' });
  }
};

// ====== POST /api/suscripciones/upgrade/play ======
// ====== POST /api/suscripciones/upgrade/play ======
const upgradePorPlay = async (req, res) => {
  try {
    const idUsuario = req.usuarioId;
    if (!idUsuario) return res.status(401).json({ msg: 'No autenticado' });

    const { purchaseToken, devBypass } = req.body || {};

    if (!purchaseToken) {
      return res.status(400).json({ msg: 'purchaseToken es requerido' });
    }

     // 🔹 FLUJO NORMAL (Producción)
    const packageName = process.env.ANDROID_PACKAGE_NAME;
    const publisher = await getPublisherClient();

    console.log('[UPGRADE/PLAY] Iniciando verificación con Google Play para token:', purchaseToken);
    const verify = await publisher.purchases.subscriptionsv2.get({
      packageName,
      token: purchaseToken,
    });
    console.log('[UPGRADE/PLAY] Respuesta cruda de Google Play:', JSON.stringify(verify.data, null, 2));
    const sub = verify.data;

    const item = (sub?.lineItems || [])[0];
    const productId = item?.productId;
    if (!productId) {
      console.error('[UPGRADE/PLAY] Compra inválida: productId ausente');
      return res.status(400).json({ msg: 'Compra inválida: productId ausente' });
    }
    console.log(`[UPGRADE/PLAY] Google Play productId encontrado: ${productId}`);

    // Estado válido
    const status = sub?.subscriptionState;
    const aceptables = new Set(['SUBSCRIPTION_STATE_ACTIVE', 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD']);
    if (!status || !aceptables.has(status)) {
      console.error(`[UPGRADE/PLAY] Estado no válido de la suscripción: ${status || 'DESCONOCIDO'}`);
      return res.status(409).json({ msg: `Estado no válido: ${status || 'DESCONOCIDO'}` });
    }
    console.log(`[UPGRADE/PLAY] Estado de suscripción válido: ${status}`);

    // ACKNOWLEDGE
    try {
      await publisher.purchases.subscriptions.acknowledge({
        packageName,
        subscriptionId: productId,
        token: purchaseToken,
        requestBody: { developerPayload: `ack_${idUsuario}_${Date.now()}` },
      });
      console.log('[UPGRADE/PLAY] Compra reconocida (acknowledged) exitosamente.');
    } catch (e) {
      if (!/already/i.test(e.message || '')) {
        console.warn('Acknowledge falló:', e?.message || e);
      } else {
        console.log('[UPGRADE/PLAY] La compra ya había sido reconocida previamente.');
      }
    }

    // Mapear a plan
    const { rows } = await pool.query(
      `SELECT id, codigo FROM public.planes WHERE play_product_id = $1 LIMIT 1`,
      [productId]
    );
    if (!rows.length) {
      console.error(`[UPGRADE/PLAY] No hay plan mapeado en la BD para productId ${productId}`);
      return res.status(404).json({ msg: `No hay plan mapeado para productId ${productId}` });
    }
    console.log(`[UPGRADE/PLAY] Plan de la BD encontrado: ${rows[0].codigo} (id: ${rows[0].id})`);

    await asignarPlan({
      idUsuario,
      idPlan: rows[0].id,
      anios: 1,
      origen: 'play',
      referencia: purchaseToken,
    });
    console.log(`[UPGRADE/PLAY] Plan ${rows[0].codigo} asignado exitosamente al usuario ${idUsuario}`);

    return res.json({ ok: true, plan_id: rows[0].id, productId, status });
  } catch (error) {
    console.error('upgradePorPlay error:', error);
    return res.status(400).json({ msg: 'No se pudo procesar el upgrade por Play' });
  }
};


module.exports = {
  obtenerSuscripciones,
  verificarSuscripcion,
  upgradePorPlanId,
  upgradePorCodigo,
  upgradePorPlay,
};

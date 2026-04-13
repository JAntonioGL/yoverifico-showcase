// controllers/planesV2Controller.js
// Planes v2 – Catálogo / Upgrade / Verify / RTDN autoservicio (renew/expire)

const { google } = require('googleapis');
const pool = require('../db/pool');

const IS_PROD = process.env.NODE_ENV === 'production';
const DEV_BYPASS_VERIFY = String(process.env.PLAN_DEV_BYPASS_PLAY_VERIFY || 'false') === 'true';
const DEV_FAKE_PRODUCT_ID = process.env.PLAN_DEV_FAKE_PRODUCT_ID || 'dev.product';
const DEV_FAKE_EXPIRY_MIN = Number(process.env.PLAN_DEV_FAKE_EXPIRY_MIN || 60);
const DEV_VERBOSE_LOG = String(process.env.PLAN_DEV_VERBOSE_LOG || 'false') === 'true';
const ANDROID_PACKAGE_NAME = process.env.ANDROID_PACKAGE_NAME;

/* ===================== Helpers ===================== */
function nowPlus(min) {
    return new Date(Date.now() + min * 60 * 1000);
}

async function getPublisherClient() {
    const auth = new google.auth.GoogleAuth({
        keyFile: process.env.GOOGLE_SERVICE_ACCOUNT_KEY,
        scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });
    const client = await auth.getClient();
    return google.androidpublisher({ version: 'v3', auth: client });
}

// Mapa productId::basePlanId -> {price, currency, period}
function buildPlayPriceIndex(subscriptions = []) {
    const idx = new Map();
    for (const sub of subscriptions) {
        const productId = sub?.productId;
        if (!productId) continue;
        for (const bp of sub.basePlans || []) {
            if (bp?.state !== 'ACTIVE') continue;
            const period = bp?.autoRenewingBasePlanType?.billingPeriodDuration ||
                bp?.prepaidBasePlanType?.billingPeriodDuration || 'P1Y';
            const mxCfg = (bp.regionalConfigs || []).find(rc => rc.regionCode === 'MX');
            if (!mxCfg?.price) continue;
            const basePlanId = bp?.basePlanId || null;
            if (!basePlanId) continue;
            const units = Number(mxCfg.price.units || 0);
            const nanos = Number(mxCfg.price.nanos || 0);
            const price = units + nanos / 1e9;
            const currency = mxCfg.price.currencyCode || 'MXN';
            idx.set(`${productId}::${basePlanId}`, { price, currency, period });
        }
    }
    return idx;
}

function _b64json(str) {
    try { return JSON.parse(Buffer.from(str, 'base64').toString('utf8')); }
    catch { return null; }
}

// Ubica id_usuario por contexto Play
async function _findUserIdByPlayContext({ purchaseToken, linkedPurchaseToken, obfuscatedAccountId }) {
    if (linkedPurchaseToken) {
        const { rows } = await pool.query(
            `SELECT up.id_usuario
         FROM public.suscripciones_play sp
         JOIN public.usuarios_planes up ON up.id = sp.id_usuario_plan
        WHERE sp.purchase_token = $1
        LIMIT 1`,
            [linkedPurchaseToken]
        );
        if (rows.length) return Number(rows[0].id_usuario);
    }
    if (purchaseToken) {
        const { rows } = await pool.query(
            `SELECT up.id_usuario
         FROM public.suscripciones_play sp
         JOIN public.usuarios_planes up ON up.id = sp.id_usuario_plan
        WHERE sp.purchase_token = $1
        LIMIT 1`,
            [purchaseToken]
        );
        if (rows.length) return Number(rows[0].id_usuario);
    }
    if (obfuscatedAccountId) {
        const { rows } = await pool.query(
            `SELECT DISTINCT up.id_usuario
         FROM public.suscripciones_play sp
         JOIN public.usuarios_planes up ON up.id = sp.id_usuario_plan
        WHERE sp.obfuscated_account_id = $1
        LIMIT 1`,
            [obfuscatedAccountId]
        );
        if (rows.length) return Number(rows[0].id_usuario);
    }
    return null;
}

/* ==============================================================
   1) Catálogo
============================================================== */
const obtenerCatalogo = async (req, res) => {
    try {
        const userId = req.usuarioId;
        const packageName = ANDROID_PACKAGE_NAME;

        // ¿Tiene personalizado?
        const { rows: entRows } = await pool.query(
            `SELECT up.id AS id_usuario_plan, p.id AS id_plan, p.codigo, p.nombre,
              COALESCE(p.es_personalizado,false) AS es_personalizado
         FROM public.usuarios_planes up
         JOIN public.planes p ON p.id = up.id_plan
        WHERE up.id_usuario = $1 AND up.estado='activo'
        LIMIT 1`,
            [userId]
        );
        const ent = entRows[0] || null;
        if (ent?.es_personalizado) {
            return res.json({ ok: true, dev_mode: !IS_PROD, personalized_catalog: true, planes: [] });
        }

        // Visible (no personalizados)
        const { rows: planesDb } = await pool.query(`
      SELECT id, codigo, nombre, descripcion, maximo_vehiculos, con_anuncios,
             precio_mxn_anual, estado, caracteristicas,
             play_product_id, play_base_plan_id, play_offer_id,
             COALESCE(rank,0) AS rank,
             COALESCE(es_personalizado,false) AS es_personalizado,
             COALESCE(adquirible_en_app, (codigo <> 'FREE')) AS adquirible_en_app
        FROM public.vista_planes_app_v2
       WHERE estado='activo' AND COALESCE(es_personalizado,false)=false
    `);

        const needPlay = planesDb.some(p => p.play_product_id && p.play_base_plan_id);
        let playIndex = new Map();
        if (needPlay && packageName) {
            const publisher = await getPublisherClient();
            const result = await publisher.monetization.subscriptions.list({ packageName });
            if (DEV_VERBOSE_LOG) console.log('[CATALOGO][PLAY RAW]', JSON.stringify(result.data, null, 2));
            playIndex = buildPlayPriceIndex(result.data.subscriptions || []);
        }

        const out = planesDb.map(p => {
            const esDePago = p.codigo !== 'FREE';
            const habilitadoEnPlay = esDePago && !!(p.play_product_id && p.play_base_plan_id);
            const key = (p.play_product_id && p.play_base_plan_id) ? `${p.play_product_id}::${p.play_base_plan_id}` : null;
            const playInfo = key ? playIndex.get(key) : null;

            const visible_en_app = p.estado === 'activo' && (p.codigo === 'FREE' || habilitadoEnPlay);
            return {
                ...p,
                rank: Number(p.rank || 0),
                es_de_pago: esDePago,
                visible_en_app,
                habilitado_en_play: habilitadoEnPlay,
                periodo_iso8601: (playInfo && playInfo.period) || 'P1Y',
                precio_mxn_anual: playInfo ? String(playInfo.price.toFixed(2)) : String(p.precio_mxn_anual || '0.00'),
                currency: playInfo ? playInfo.currency : 'MXN',
            };
        });

        out.sort((a, b) => (b.rank || 0) - (a.rank || 0) || (b.maximo_vehiculos || 0) - (a.maximo_vehiculos || 0));
        return res.json({ ok: true, dev_mode: !IS_PROD, planes: out });
    } catch (err) {
        console.error('obtenerCatalogo error:', err);
        return res.status(500).json({ ok: false, msg: 'Error al obtener catálogo' });
    }
};

/* ==============================================================
   2) Entitlement
============================================================== */
const entitlement = async (req, res) => {
    try {
        const idUsuario = req.usuarioId;
        const { rows } = await pool.query('SELECT * FROM public.fn_usuario_entitlement_v1($1)', [idUsuario]);
        const ent = rows?.[0] || null;
        return res.json({ ok: true, dev_mode: !IS_PROD, entitlement: ent });
    } catch (e) {
        console.error('entitlement error:', e);
        return res.status(500).json({ ok: false, msg: 'Error al obtener entitlement' });
    }
};

/* ==============================================================
   3) Upgrade Play (compra in-app)
============================================================== */
const upgradePorPlay = async (req, res) => {
    try {
        const idUsuario = req.usuarioId;
        const packageName = ANDROID_PACKAGE_NAME;
        const { purchaseToken } = req.body || {};
        if (!purchaseToken) return res.status(400).json({ ok: false, msg: 'purchaseToken requerido' });

        let productId = null, basePlanId = null, offerId = null;
        let subscriptionState = 'SUBSCRIPTION_STATE_UNSPECIFIED';
        let expiryTimeIso = null, linkedPurchaseToken = null;
        let obfuscatedAccountId = null, obfuscatedProfileId = null;

        if (!IS_PROD && DEV_BYPASS_VERIFY) {
            productId = DEV_FAKE_PRODUCT_ID;
            subscriptionState = 'SUBSCRIPTION_STATE_ACTIVE';
            expiryTimeIso = nowPlus(DEV_FAKE_EXPIRY_MIN).toISOString();
        } else {
            const publisher = await getPublisherClient();
            const verify = await publisher.purchases.subscriptionsv2.get({ packageName, token: purchaseToken });
            if (DEV_VERBOSE_LOG) console.log('[PLAY verify RAW]', JSON.stringify(verify.data, null, 2));

            const sub = verify.data;
            const item = (sub?.lineItems || [])[0];
            productId = item?.productId || null;
            const itemExpiry = item?.expiryTime || null;
            expiryTimeIso = itemExpiry ? new Date(itemExpiry).toISOString() : null;
            basePlanId = item?.offerDetails?.basePlanId || item?.basePlanId || null;
            offerId = item?.offerDetails?.offerId || item?.offerId || null;
            subscriptionState = sub?.subscriptionState || 'SUBSCRIPTION_STATE_UNSPECIFIED';
            linkedPurchaseToken = sub?.linkedPurchaseToken || null;

            const ext = sub.externalAccountIdentifiers || item?.externalAccountIdentifiers || null;
            obfuscatedAccountId = ext?.obfuscatedExternalAccountId || null;
            obfuscatedProfileId = ext?.obfuscatedExternalProfileId || null;

            if (!productId) return res.status(400).json({ ok: false, msg: 'Compra inválida: productId ausente' });

            try {
                await publisher.purchases.subscriptions.acknowledge({
                    packageName,
                    subscriptionId: productId,
                    token: purchaseToken,
                    requestBody: { developerPayload: `ack_${idUsuario}_${Date.now()}` },
                });
            } catch (e) {
                if (!/already/i.test(e?.message || '')) console.warn('[ACK warn]', e?.message || e);
            }
        }

        const { rows } = await pool.query(
            `SELECT public.fn_upgrade_play_apply_v1(
        $1::int,$2::text,$3::text,$4::text,$5::timestamptz,
        $6::text,$7::text,$8::text,$9::text,$10::text,$11::text
      ) AS r`,
            [
                idUsuario,
                productId,
                purchaseToken,
                subscriptionState,
                expiryTimeIso ? new Date(expiryTimeIso) : null,
                basePlanId,
                offerId,
                linkedPurchaseToken,
                ANDROID_PACKAGE_NAME,
                obfuscatedAccountId,
                obfuscatedProfileId,
            ]
        );

        const r = rows[0]?.r || { ok: false, code: 'unknown' };
        if (r.ok) return res.json({ ok: true, dev_mode: !IS_PROD, ...r });

        const map = { custom_locked: 422, plan_not_mapped: 404, invalid_state: 409, not_higher_tier: 422, forbidden: 403, idempotent: 200 };
        return res.status(map[r.code] || 400).json({ ok: false, ...r, dev_mode: !IS_PROD });
    } catch (e) {
        console.error('upgradePorPlay error:', e);
        return res.status(500).json({ ok: false, msg: 'No se pudo procesar upgrade' });
    }
};

/* ==============================================================
   4) Downgrade programado/cancelado
============================================================== */
const downgradeSchedule = async (req, res) => {
    try {
        const idUsuario = req.usuarioId;
        const { id_plan, codigo } = req.body || {};
        if (!id_plan && !codigo) return res.status(400).json({ ok: false, msg: 'Falta id_plan o codigo' });

        const { rows } = await pool.query(
            'SELECT public.fn_downgrade_schedule_v1($1,$2,$3) AS r',
            [idUsuario, id_plan || null, codigo || null]
        );
        const r = rows[0]?.r || { ok: false, code: 'unknown' };
        if (r.ok) return res.json({ ok: true, ...r, dev_mode: !IS_PROD });

        const map = {
            custom_locked: 422,
            not_lower_tier: 422,
            pending_change_exists: 409,
            unknown_expiry: 409,
            forbidden: 403,
            cooldown_active: 409,
        };
        return res.status(map[r.code] || 400).json({ ok: false, ...r, dev_mode: !IS_PROD });
    } catch (e) {
        console.error('downgradeSchedule error:', e);
        return res.status(500).json({ ok: false, msg: 'No se pudo programar downgrade' });
    }
};

const downgradeCancel = async (req, res) => {
    try {
        const idUsuario = req.usuarioId;
        const { rows } = await pool.query('SELECT public.fn_downgrade_cancel_v1($1) AS r', [idUsuario]);
        const r = rows[0]?.r || { ok: false, code: 'unknown' };
        if (r.ok) return res.json({ ok: true, dev_mode: !IS_PROD });

        const status = r.code === 'pending_not_found' ? 404 : 400;
        return res.status(status).json({ ok: false, ...r, dev_mode: !IS_PROD });
    } catch (e) {
        console.error('downgradeCancel error:', e);
        return res.status(500).json({ ok: false, msg: 'No se pudo cancelar downgrade' });
    }
};

/* ==============================================================
   5) Verify / Resync
============================================================== */
const verify = async (req, res) => {
    try {
        const idUsuario = req.usuarioId;
        const { purchaseToken } = req.body || {};
        if (!purchaseToken) return res.status(400).json({ ok: false, msg: 'purchaseToken requerido' });

        const packageName = ANDROID_PACKAGE_NAME;
        let productId, basePlanId, offerId, subscriptionState, expiryTimeIso, linkedPurchaseToken;

        if (!IS_PROD && DEV_BYPASS_VERIFY) {
            productId = DEV_FAKE_PRODUCT_ID;
            basePlanId = null;
            offerId = null;
            linkedPurchaseToken = null;
            subscriptionState = 'SUBSCRIPTION_STATE_ACTIVE';
            expiryTimeIso = nowPlus(DEV_FAKE_EXPIRY_MIN).toISOString();
        } else {
            const publisher = await getPublisherClient();
            const verify = await publisher.purchases.subscriptionsv2.get({ packageName, token: purchaseToken });
            if (DEV_VERBOSE_LOG) console.log('[VERIFY RAW]', JSON.stringify(verify.data, null, 2));

            const sub = verify.data;
            const item = (sub?.lineItems || [])[0];

            productId = item?.productId || null;
            basePlanId = item?.offerDetails?.basePlanId || item?.basePlanId || null;
            offerId = item?.offerDetails?.offerId || item?.offerId || null;
            linkedPurchaseToken = sub?.linkedPurchaseToken || null;
            subscriptionState = sub?.subscriptionState || 'SUBSCRIPTION_STATE_UNSPECIFIED';

            const itemExpiry = item?.expiryTime || null;
            expiryTimeIso = itemExpiry ? new Date(itemExpiry).toISOString() : null;

            if (!productId) return res.status(400).json({ ok: false, msg: 'Compra inválida (sin productId)' });
        }

        const { rows } = await pool.query(
            'SELECT public.fn_play_resync_snapshot_v1($1,$2,$3,$4,$5,$6,$7,$8) AS r',
            [
                idUsuario,
                purchaseToken,
                productId,
                subscriptionState,
                expiryTimeIso ? new Date(expiryTimeIso) : null,
                linkedPurchaseToken,
                basePlanId,
                offerId,
            ]
        );

        const r = rows[0]?.r || { ok: false, code: 'unknown' };
        if (r.ok) {
            return res.json({
                ok: true,
                dev_mode: !IS_PROD,
                ...r
            });
        }
        return res.status(400).json({ ok: false, ...r, dev_mode: !IS_PROD });
    } catch (e) {
        console.error('verify error:', e);
        return res.status(500).json({ ok: false, msg: 'No se pudo verificar' });
    }
};

/* ==============================================================
   6) RTDN – Webhook (procesa renovación/expiración)
   Ruta: POST /api/planes/v2/rtdn  (SIN JWT; protégela con OIDC o x-admin-key)
============================================================== */
// Helpers de logging
function maskMid(str, tail = 6) {
    if (!str) return null;
    const s = String(str);
    if (s.length <= tail) return '*'.repeat(s.length);
    return '*'.repeat(s.length - tail) + s.slice(-tail);
}
function jlog(level, obj) {
    try {
        const base = { ts: new Date().toISOString(), scope: 'RTDN', level };
        console.log(JSON.stringify({ ...base, ...obj }));
    } catch {
        // fallback
        console.log(`[RTDN][${level}]`, obj);
    }
}

const rtdnWebhook = async (req, res) => {
    const startedAt = Date.now();
    try {
        const { message } = req.body || {};
        if (!message?.data) {
            jlog('warn', { msg: 'falta message.data', http: 400 });
            return res.status(400).json({ ok: false, msg: 'Falta message.data' });
        }

        const messageId = message.messageId || null;
        const publishTime = message.publishTime || null;
        const payload = _b64json(message.data);

        const n = payload?.subscriptionNotification || {};
        const nType = Number(n?.notificationType ?? -1);
        const subId = n?.subscriptionId || null; // este es tu productId
        const nTypeNames = {
            1: 'SUBSCRIPTION_RECOVERED', 2: 'SUBSCRIPTION_RENEWED', 3: 'SUBSCRIPTION_CANCELED',
            4: 'SUBSCRIPTION_PURCHASED', 5: 'SUBSCRIPTION_ON_HOLD', 6: 'SUBSCRIPTION_IN_GRACE_PERIOD',
            7: 'SUBSCRIPTION_RESTARTED', 8: 'SUBSCRIPTION_PRICE_CHANGE_CONFIRMED', 9: 'SUBSCRIPTION_DEFERRED',
            10: 'SUBSCRIPTION_PAUSED', 11: 'SUBSCRIPTION_PAUSE_SCHEDULE_CHANGED', 12: 'SUBSCRIPTION_REVOKED',
            13: 'SUBSCRIPTION_EXPIRED',
        };
        const nTypeName = nTypeNames[nType] || `UNKNOWN_${nType}`;

        // SIEMPRE log:
        console.log(JSON.stringify({
            ts: new Date().toISOString(),
            scope: 'RTDN',
            level: 'info',
            event: 'received',
            notificationType: nType,
            notificationTypeName: nTypeName,
            subscriptionId: subId,
            hasPurchaseToken: !!(payload?.purchaseToken || payload?.subscriptionPurchase?.purchaseToken)
        }));

        // Best-effort: guarda crudo
        try {
            await pool.query(
                'SELECT public.fn_rtdn_store_event_v1($1,$2,$3,$4,$5) AS id',
                [messageId, payload?.purchaseToken || null, payload?.subscriptionNotification?.notificationType || null, payload?.eventTimeMillis || null, payload]
            );
            jlog('info', { event: 'stored_raw_ok', messageId });
        } catch (e) {
            jlog('warn', { event: 'stored_raw_fail', messageId, error: e?.message || String(e) });
        }

        // Necesitamos token para verificar en Play
        const purchaseToken = payload?.purchaseToken || n?.purchaseToken || payload?.subscriptionPurchase?.purchaseToken || null;
        if (!purchaseToken) {
            // Si NO hay token y es EXPIRED, intentamos resolver usuario desde la BD
            if (nType === 13 /* SUBSCRIPTION_EXPIRED */ && subId) {
                try {
                    // 1) busca la suscripción más reciente de ese productId que ya venció
                    //    ajusta nombres de tabla/campos según tu esquema real
                    const q = `
        SELECT up.id_usuario AS user_id, sp.purchase_token
          FROM public.suscripciones_play sp
          JOIN public.usuarios_planes up ON up.id = sp.id_usuario_plan
         WHERE sp.product_id = $1
           AND up.estado = 'activo'
           AND (sp.estado IN ('active','grace','pending') OR sp.estado IS NULL)
           AND sp.expiry_ts <= now()
         ORDER BY sp.expiry_ts DESC
         LIMIT 1
      `;
                    const { rows: cand } = await pool.query(q, [subId]);

                    if (cand.length) {
                        const userId = Number(cand[0].user_id);
                        const lastToken = cand[0].purchase_token || null;

                        // (Opcional) si tienes el último token, intenta verificar en Play antes de bajar:
                        // Si prefieres bajar directo al ver EXPIRED en RTDN sin token, puedes saltar verify.
                        if (lastToken) {
                            try {
                                const publisher = await getPublisherClient();
                                const vv = await publisher.purchases.subscriptionsv2.get({
                                    packageName: ANDROID_PACKAGE_NAME,
                                    token: lastToken,
                                });
                                const state = vv?.data?.subscriptionState || 'UNSPECIFIED';

                                console.log(JSON.stringify({
                                    ts: new Date().toISOString(),
                                    scope: 'RTDN',
                                    level: 'info',
                                    event: 'verified_in_play_no_rtdn_token',
                                    subscriptionId: subId,
                                    subscriptionState: state
                                }));

                                // Si Play ya marca EXPIRED → baja
                                if (state === 'SUBSCRIPTION_STATE_EXPIRED' || state === 'SUBSCRIPTION_STATE_CANCELED') {
                                    const { rows } = await pool.query(
                                        `SELECT public.fn_downgrade_to_free_now_v1($1,$2,$3) AS r`,
                                        [userId, 'rtdn_no_token', lastToken]
                                    );
                                    const r = rows[0]?.r || { ok: false };
                                    console.log(JSON.stringify({
                                        ts: new Date().toISOString(),
                                        scope: 'RTDN',
                                        level: r.ok ? 'info' : 'warn',
                                        event: 'downgraded_to_free',
                                        cause: 'expired_no_token',
                                        userId
                                    }));
                                    return res.json({ ok: true, action: 'downgraded_to_free', via: 'no_token_resolve' });
                                }
                            } catch (e) {
                                console.warn('[RTDN no-token verify warn]', e?.message || e);
                            }
                        }

                        // Si no pudimos verificar pero el evento ya es EXPIRED, ejecuta downgrade conservador:
                        const { rows } = await pool.query(
                            `SELECT public.fn_downgrade_to_free_now_v1($1,$2,$3) AS r`,
                            [userId, 'rtdn_no_token_fallback', lastToken]
                        );
                        const r = rows[0]?.r || { ok: false };
                        console.log(JSON.stringify({
                            ts: new Date().toISOString(),
                            scope: 'RTDN',
                            level: r.ok ? 'info' : 'warn',
                            event: 'downgraded_to_free',
                            cause: 'expired_no_token_fallback',
                            userId
                        }));
                        return res.json({ ok: true, action: 'downgraded_to_free', via: 'no_token_fallback' });
                    }

                    // No encontramos candidato → almacena y salida 202
                    console.log(JSON.stringify({
                        ts: new Date().toISOString(),
                        scope: 'RTDN',
                        level: 'info',
                        event: 'no_candidate_for_expired_no_token',
                        subscriptionId: subId
                    }));
                } catch (e) {
                    console.warn('[RTDN no-token expired resolve warn]', e?.message || e);
                }
            }

            // otros tipos sin token → solo almacenar
            console.log(JSON.stringify({
                ts: new Date().toISOString(),
                scope: 'RTDN',
                level: 'info',
                event: 'no_token_deferred',
                notificationTypeName: nTypeName,
                subscriptionId: subId
            }));
            return res.status(202).json({ ok: true, msg: 'Sin purchaseToken; almacenado', deferred: true });
        }

        // Verifica estado real en Play
        const publisher = await getPublisherClient();
        const verify = await publisher.purchases.subscriptionsv2.get({
            packageName: ANDROID_PACKAGE_NAME,
            token: purchaseToken,
        });

        const sub = verify.data;
        const item = (sub?.lineItems || [])[0];
        const productId = item?.productId || payload?.subscriptionId || null;
        const basePlanId = item?.offerDetails?.basePlanId || item?.basePlanId || null;
        const offerId = item?.offerDetails?.offerId || item?.offerId || null;
        const expiryIso = item?.expiryTime || null;
        const expiryTs = expiryIso ? new Date(expiryIso) : null;

        const subscriptionState = sub?.subscriptionState || 'SUBSCRIPTION_STATE_UNSPECIFIED';
        const linkedPurchaseToken = sub?.linkedPurchaseToken || null;

        const ext = sub.externalAccountIdentifiers || item?.externalAccountIdentifiers || null;
        const obfAcc = ext?.obfuscatedExternalAccountId || null;

        jlog('info', {
            event: 'verified_play',
            messageId,
            state: subscriptionState,
            productId,
            basePlanId,
            offerId,
            expiryIso,
            linkedPurchaseToken: maskMid(linkedPurchaseToken),
            purchaseToken: maskMid(purchaseToken),
            obfAcc: maskMid(obfAcc)
        });

        // Localiza usuario
        const idUsuario = await _findUserIdByPlayContext({
            purchaseToken,
            linkedPurchaseToken,
            obfuscatedAccountId: obfAcc
        });

        if (!idUsuario) {
            jlog('warn', {
                event: 'user_not_found',
                messageId,
                state: subscriptionState,
                purchaseToken: maskMid(purchaseToken),
            });
            // Acepta para no reintentar
            return res.status(202).json({ ok: true, msg: 'Usuario desconocido; evento almacenado', deferred: true });
        }

        // ---------- REGLAS ----------
        if (subscriptionState === 'SUBSCRIPTION_STATE_ACTIVE' ||
            subscriptionState === 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD') {

            const { rows } = await pool.query(
                `SELECT public.fn_apply_play_renewal_v1(
           $1,$2,$3,$4,$5,$6,$7,$8,$9
         ) AS r`,
                [
                    idUsuario,
                    productId,
                    purchaseToken,
                    subscriptionState,
                    expiryTs,
                    basePlanId,
                    offerId,
                    linkedPurchaseToken,
                    ANDROID_PACKAGE_NAME,
                ]
            );
            const r = rows[0]?.r || { ok: false };

            if (!r.ok) {
                jlog('error', {
                    event: 'renew_apply_fail',
                    messageId,
                    idUsuario,
                    state: subscriptionState,
                    productId,
                    expiryIso,
                    error: r.code || 'unknown'
                });
                return res.status(400).json({ ok: false, ...r });
            }

            jlog('info', {
                event: 'renew_applied',
                messageId,
                idUsuario,
                state: subscriptionState,
                productId,
                basePlanId,
                offerId,
                newExpiry: expiryIso
            });

            return res.json({ ok: true, action: 'renewal_applied', ...r });
        }

        if (subscriptionState === 'SUBSCRIPTION_STATE_CANCELED') {
            // NO-OP; sólo logging para auditoría
            jlog('info', {
                event: 'canceled_noop',
                messageId,
                idUsuario,
                productId
            });
            return res.status(202).json({ ok: true, action: 'canceled_noop' });
        }

        if (subscriptionState === 'SUBSCRIPTION_STATE_EXPIRED') {
            const { rows } = await pool.query(
                `SELECT public.fn_downgrade_to_free_now_v1($1,$2,$3) AS r`,
                [idUsuario, 'rtdn_auto', purchaseToken]
            );
            const r = rows[0]?.r || { ok: false };

            if (!r.ok) {
                jlog('error', {
                    event: 'expire_downgrade_fail',
                    messageId,
                    idUsuario,
                    productId,
                    error: r.code || 'unknown'
                });
                return res.status(400).json({ ok: false, ...r });
            }

            jlog('info', {
                event: 'expired_downgraded',
                messageId,
                idUsuario,
                productId
            });

            return res.json({ ok: true, action: 'downgraded_to_free', ...r });
        }

        // Otros estados → sin acción
        jlog('info', {
            event: 'state_no_action',
            messageId,
            idUsuario,
            state: subscriptionState
        });
        return res.status(202).json({ ok: true, msg: 'Estado sin acción', state: subscriptionState });

    } catch (e) {
        jlog('error', {
            event: 'handler_exception',
            error: e?.message || String(e)
        });
        // Responder 200 evita reintentos infinitos si el error es nuestro.
        return res.status(200).json({ ok: false, handled: false });
    } finally {
        jlog('info', { event: 'done', ms: Date.now() - startedAt });
    }
};


/* ==============================================================
   7) Endpoints de prueba (opcional, protégelos con x-admin-key)
============================================================== */
const rtdnTestRenew = async (req, res) => {
    try {
        const { userId, productId, basePlanId, offerId, purchaseToken, expiryIso, linkedPurchaseToken } = req.body || {};
        if (!userId || !productId || !purchaseToken || !expiryIso) {
            return res.status(400).json({ ok: false, msg: 'Faltan campos' });
        }
        const expiryTs = new Date(expiryIso);
        const { rows } = await pool.query(
            `SELECT public.fn_apply_play_renewal_v1($1,$2,$3,$4,$5,$6,$7,$8,$9) AS r`,
            [userId, productId, purchaseToken, 'SUBSCRIPTION_STATE_ACTIVE', expiryTs, basePlanId || null, offerId || null, linkedPurchaseToken || null, ANDROID_PACKAGE_NAME]
        );
        return res.json({ ok: true, ...(rows[0]?.r || {}) });
    } catch (e) {
        console.error('rtdnTestRenew error:', e);
        return res.status(500).json({ ok: false });
    }
};

const rtdnTestExpire = async (req, res) => {
    try {
        const { userId, purchaseToken } = req.body || {};
        if (!userId) return res.status(400).json({ ok: false, msg: 'userId requerido' });
        const { rows } = await pool.query(
            `SELECT public.fn_downgrade_to_free_now_v1($1,$2,$3) AS r`,
            [userId, 'manual_test', purchaseToken || null]
        );
        return res.json({ ok: true, ...(rows[0]?.r || {}) });
    } catch (e) {
        console.error('rtdnTestExpire error:', e);
        return res.status(500).json({ ok: false });
    }
};

/* ===================== Exports ===================== */
module.exports = {
    obtenerCatalogo,
    entitlement,
    upgradePorPlay,
    downgradeSchedule,
    downgradeCancel,
    verify,
    // RTDN
    rtdnWebhook,
    rtdnTestRenew,
    rtdnTestExpire,
};

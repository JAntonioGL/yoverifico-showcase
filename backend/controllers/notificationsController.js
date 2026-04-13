// controllers/notificacionesController.js
const pool = require('../db/pool');
const moment = require('moment-timezone'); // <--- AGREGA ESTO
/**
 * Normaliza una fecha de entrada (string ISO, con/ sin zona) a un timestamp UTC
 * almacenado como TIMESTAMP (sin TZ) en Postgres.
 * Guardamos siempre UTC para ser consistentes con la vista que compara con now() AT TIME ZONE 'UTC'.
 */
function toPgTimestampUTC(input) {
    const d = new Date(input);
    if (Number.isNaN(d.getTime())) {
        throw new Error('fecha_programada inválida');
    }
    // Regresamos una cadena ISO UTC; en el INSERT la convertimos a timestamptz y luego a timestamp UTC.
    return d.toISOString();
}

/**
 * Sanitiza / valida el campo data (payload extra).
 * Si viene como string JSON válido, lo parsea; si viene objeto, lo deja igual; si viene vacío, null.
 */
function sanitizeData(data) {
    if (data == null || data === '') return null;
    if (typeof data === 'string') {
        try { return JSON.parse(data); } catch (_) {
            throw new Error('data debe ser JSON válido');
        }
    }
    if (typeof data === 'object') return data;
    throw new Error('data debe ser objeto JSON o string JSON');
}

/**
 * POST /api/notificaciones/programar
 * Encola una notificación (por vehículo o global) para que el worker la envíe cuando corresponda.
 * Body:
 *  - titulo (string, requerido)
 *  - mensaje (string, requerido)
 *  - fecha_programada (string fecha; requerido)
 *  - id_vehiculo (int, opcional; nullable para global)
 *  - placa_vehiculo (string, opcional; nullable)
 *  - tipo (string, opcional; default 'programada')  ej: 'contingencia'
 *  - dedup_key (string, opcional)
 *  - data (obj/json, opcional)  ej: { fecha, terminaciones_1, terminaciones_0s }
 */
async function programarNotificacion(req, res) {
    try {
        const userId = req.usuarioId;
        const {
            titulo,
            mensaje,
            fecha_programada,
            id_vehiculo = null,
            placa_vehiculo = null,
            tipo = 'programada',
            dedup_key = null,
            data = null,
            priority = null,
            ttl_seconds = null,
        } = req.body || {};

        if (!userId) return res.status(401).json({ msg: 'No autorizado' });
        if (!titulo || !mensaje || !fecha_programada) {
            return res.status(400).json({ msg: 'Faltan parámetros obligatorios (titulo, mensaje, fecha_programada).' });
        }

        const fechaISO = toPgTimestampUTC(fecha_programada);
        const payload = sanitizeData(data);

        // Insert directo a la tabla (compatibilidad con tu vista y cron)
        // Guardamos fecha UTC en columna TIMESTAMP SIN TZ: (timestamptz -> timestamp at time zone 'UTC')
        const sql = `
  SELECT ok, id_notificacion, msg
  FROM public.fn_notif_programar(
    $1::int,  -- p_id_usuario
    $2::text, -- p_titulo
    $3::text, -- p_mensaje
    $4::timestamptz, -- p_fecha_programada
    $5::int,  -- p_id_vehiculo
    $6::text, -- p_placa_vehiculo
    $7::text, -- p_tipo
    $8::text, -- p_dedup_key
    $9::jsonb,-- p_data
    $10::int, -- p_priority
    $11::int  -- p_ttl_seconds
  )
`;
        const params = [
            userId,
            id_vehiculo,
            placa_vehiculo,
            titulo,
            mensaje,
            tipo,
            dedup_key,
            payload ? JSON.stringify(payload) : null,
            priority,
            ttl_seconds,
            fechaISO,
        ];

        const { rows } = await pool.query(sql, params);
        return res.status(201).json({
            msg: 'Notificación programada correctamente.',
            id_notificacion: rows[0].id,
        });
    } catch (err) {
        // Manejo de duplicado por índice único parcial (dedup por usuario+vehiculo+dedup_key mientras enviada=false)
        if (err && err.code === '23505') {
            return res.status(409).json({ msg: 'Duplicado: dedup_key ya existe para ese usuario/vehículo y no ha sido enviada.' });
        }
        console.error('Error programando notificación:', err);
        return res.status(500).json({ msg: 'Error al programar notificación.' });
    }
}

/**
 * POST /api/notificaciones/contingencia
 * Programa una contingencia "para todos" (fan-out en DB).
 *
 * Body:
 *  - fecha (YYYY-MM-DD)                         requerido (día al que aplica la restricción)
 *  - titulo (string)                            requerido
 *  - mensaje (string)                           requerido
 *  - fecha_programada (ISO con TZ)              requerido (hora de envío del día D)
 *  - terminaciones_1 (array o CSV)              requerido
 *  - terminaciones_0s (array o CSV)             requerido
 *  - dedup_key (string)                         opcional (default: "contingencia-<fecha>")
 *  - prealerta_fecha_programada (ISO con TZ)    opcional (para enviar día -1)
 *  - prealerta_dedup_key (string)               opcional (default: "<dedup>-pre")
 */
async function programarContingenciaFanout(req, res) {
    try {
        const {
            fecha,
            titulo,
            mensaje,
            fecha_programada,
            terminaciones_1,
            terminaciones_0s,
            dedup_key = null,
            prealerta_fecha_programada = null,
            prealerta_dedup_key = null,
        } = req.body || {};

        if (!fecha || !titulo || !mensaje || !fecha_programada) {
            return res.status(400).json({
                msg: 'Faltan campos: fecha, titulo, mensaje, fecha_programada son requeridos.',
            });
        }
        if (!terminaciones_1 || !terminaciones_0s) {
            return res.status(400).json({ msg: 'terminaciones_1 y terminaciones_0s son requeridos.' });
        }

        const toTextArray = (v) =>
            Array.isArray(v) ? v.map(String) : String(v).split(',').map(s => s.trim());

        const t1 = toTextArray(terminaciones_1);
        const t0 = toTextArray(terminaciones_0s);

        const sql = `
      SELECT insertados_dia, insertados_prealerta
      FROM public.fn_notif_programar_contingencia(
        $1::date, $2::text, $3::text, $4::timestamptz,
        $5::text[], $6::text[], $7::text,
        $8::timestamptz, $9::text
      )
    `;
        const params = [
            fecha,
            titulo,
            mensaje,
            fecha_programada,
            t1,
            t0,
            dedup_key,
            prealerta_fecha_programada,
            prealerta_dedup_key,
        ];

        const { rows } = await pool.query(sql, params);
        const r = rows?.[0] || { insertados_dia: 0, insertados_prealerta: 0 };

        return res.status(201).json({
            msg: 'Contingencia programada correctamente.',
            insertados_dia: Number(r.insertados_dia) || 0,
            insertados_prealerta: Number(r.insertados_prealerta) || 0,
            dedup_key: dedup_key || `contingencia-${fecha}`,
            prealerta_dedup_key: prealerta_dedup_key || `contingencia-${fecha}-pre`,
        });
    } catch (err) {
        console.error('Error programando contingencia (fan-out DB):', err);
        return res.status(500).json({ msg: 'Error al programar contingencia.' });
    }
}

/**
 * GET /api/notificaciones/pendientes?limit=100
 * Usa la función que retorna SETOF de la vista.
 */
async function listarPendientes(req, res) {
    try {
        const limit = Number(req.query.limit || 100);
        const { rows } = await pool.query(
            'SELECT * FROM public.fn_notif_listar_pendientes($1::int)',
            [Number.isFinite(limit) ? limit : 100]
        );
        return res.json(rows || []);
    } catch (err) {
        console.error('Error listando pendientes:', err);
        return res.status(500).json({ msg: 'Error al listar pendientes.' });
    }
}

/**
 * POST /api/notificaciones/marcar-enviada
 * Body:
 *  - id (int)             **requerido**
 *  - message_id (string)  opcional (el que regresa FCM)
 */
async function marcarEnviada(req, res) {
    try {
        const { id, message_id = null } = req.body || {};
        if (!id) return res.status(400).json({ msg: 'Falta id.' });

        const { rows } = await pool.query(
            'SELECT ok, msg FROM public.fn_notif_marcar_enviada($1::int, $2::varchar)',
            [id, message_id]
        );
        const r = rows?.[0];
        if (!r?.ok) {
            // already_sent | not_found
            const status = r.msg === 'not_found' ? 404 : 409;
            return res.status(status).json({ ok: false, msg: r.msg });
        }
        return res.json({ ok: true, msg: 'ok' });
    } catch (err) {
        console.error('Error marcando enviada:', err);
        return res.status(500).json({ msg: 'Error al marcar enviada.' });
    }
}

/**
 * POST /api/notificaciones/manual
 * Encola una notificación para enviar de inmediato (fecha_programada = NOW()) desde Postman.
 * Útil para pruebas rápidas sin tocar el cron.
 * Body: mismo que /programar (puedes omitir fecha_programada)
 */
async function programarManual(req, res) {
    try {
        const now = new Date().toISOString();
        req.body = { ...req.body, fecha_programada: req.body?.fecha_programada || now };
        return programarNotificacion(req, res);
    } catch (err) {
        console.error('Error en manual:', err);
        return res.status(500).json({ msg: 'Error al programar notificación manual.' });
    }
}


async function programarCancelacionContingencia(req, res) {
    console.log('SE RECIBIO notif cancel');
    try {
        const {
            fecha,                // 'YYYY-MM-DD' a cancelar
            titulo,               // opcional
            mensaje,              // opcional
            fecha_envio = null,   // opcional (timestamp o null)
            dedup_key = null,     // opcional
            programar_aviso = true // opcional (boolean)
        } = req.body || {};

        if (!fecha) {
            return res.status(400).json({ msg: 'Falta campo: fecha (YYYY-MM-DD).' });
        }

        const sql = `
      SELECT borrados, insertados
      FROM public.fn_notif_cancelar_contingencia(
        $1::date, $2::boolean, $3::text, $4::text,
        $5::timestamptz, $6::text
      )
    `;

        const params = [
            fecha,
            programar_aviso,
            titulo || 'Contingencia cancelada',
            mensaje || 'Se canceló la contingencia para la fecha indicada.',
            fecha_envio,
            dedup_key
        ];

        const { rows } = await pool.query(sql, params);
        const r = rows?.[0] || { borrados: 0, insertados: 0 };

        return res.status(201).json({
            msg: 'Cancelación de contingencia procesada correctamente.',
            fecha,
            borrados: Number(r.borrados) || 0,
            insertados: Number(r.insertados) || 0,
            dedup_key: dedup_key || `contingencia-${fecha}-cancel`,
        });
    } catch (err) {
        console.error('❌ Error programando cancelación de contingencia:', err);
        return res.status(500).json({ msg: 'Error al programar cancelación.' });
    }
}


/**
 * GET /api/notificaciones/estado-contingencia
 * Retorna:
 * - false (boolean): Si no hay contingencia hoy ni mañana.
 * - JSON Object: { hoy: {...}, manana: {...} } si hay algo activo.
 */
async function getEstadoContingencia(req, res) {
    try {
        const zona = 'America/Mexico_City';
        const hoy = moment().tz(zona).format('YYYY-MM-DD');
        const manana = moment().tz(zona).add(1, 'days').format('YYYY-MM-DD');

        // --- AGREGAR ESTO PARA DEBUG ---
        console.log('--- DEBUG CONTINGENCIA ---');
        console.log('Hora Servidor:', new Date().toISOString());
        console.log('Zona usada:', zona);
        console.log('Buscando fecha HOY:', hoy);
        console.log('Buscando fecha MAÑANA:', manana);
        // -------------------------------

        const sql = `
      SELECT 
        to_char(fecha, 'YYYY-MM-DD') as fecha_str,
        terminaciones_1,
        terminaciones_0s
      FROM contingencias_api
      WHERE fecha IN ($1::date, $2::date)
    `;

        const { rows } = await pool.query(sql, [hoy, manana]);

        // --- CAMBIO CLAVE AQUÍ ---
        // Si la consulta no trajo nada, retornamos false directo.
        if (!rows || rows.length === 0) {
            return res.status(200).json(false);
        }

        // Si llegamos aquí, ES porque SÍ hay algo. Armamos el objeto.
        const respuesta = {
            hoy: null,
            manana: null
        };

        rows.forEach(row => {
            const data = {
                fecha: row.fecha_str,
                terminaciones_1: row.terminaciones_1 || [],
                terminaciones_0s: row.terminaciones_0s || []
            };

            if (row.fecha_str === hoy) {
                respuesta.hoy = data;
            } else if (row.fecha_str === manana) {
                respuesta.manana = data;
            }
        });

        return res.json(respuesta);

    } catch (err) {
        console.error('Error consultando estado contingencia:', err);
        // En error también podrías retornar false para que la app no haga nada
        return res.status(500).json({ msg: 'Error al consultar estado.' });
    }
}

module.exports = {
    programarNotificacion,
    programarContingenciaFanout,
    listarPendientes,
    marcarEnviada,
    programarManual,
    programarCancelacionContingencia,
    getEstadoContingencia,
};

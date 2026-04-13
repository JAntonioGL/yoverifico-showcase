// notificacionesScheduler.js
const cron = require('node-cron');
const admin = require('firebase-admin');
const pool = require('./db/pool');

// Jitter opcional para reducir picos (desactivado por defecto)
const JITTER_MS = Number(process.env.SCHED_JITTER_MS || 0);

// Pequeño helper de sleep (para jitter opcional)
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * Convierte un objeto cualquiera en un diccionario apto para FCM data.
 */
function sanitizeDataForFcm(obj) {
  const out = {};
  if (!obj || typeof obj !== 'object') return out;
  for (const [k, v] of Object.entries(obj)) {
    if (v === null || v === undefined) continue;
    const t = typeof v;
    if (t === 'string') out[k] = v;
    else if (t === 'number' || t === 'boolean') out[k] = String(v);
    else if (v instanceof Date) out[k] = v.toISOString();
    else if (Array.isArray(v) || t === 'object') out[k] = JSON.stringify(v);
    else out[k] = String(v);
  }
  return out;
}


async function programarNotificacionesSinVerificacion() {
  // Mantengo tu Jitter
  if (typeof JITTER_MS !== 'undefined' && JITTER_MS > 0) {
    await sleep(Math.floor(Math.random() * JITTER_MS));
  }
  console.log('🧾 Programador sin verificación: preparando notificaciones del día...');

  try {
    // Mantenemos tu query original
    const { rows } = await pool.query(`
      SELECT
        id_usuario,
        id_vehiculo,
        placa,
        vehiculo_nombre
      FROM public.vista_programacion_notif_sin_verificacion
    `);

    if (!rows.length) {
      console.log('ℹ️  No hay vehículos sin verificación.');
      return;
    }

    let creadas = 0;
    let omitidasDuplicado = 0;
    let errores = 0;

    // =====================================================================
    // CORRECCIÓN DE ZONA HORARIA
    // =====================================================================
    // 1. Forzamos la fecha a la zona horaria de México (o la que necesites)
    const zonaHoraria = 'America/Mexico_City';
    const hoyLocal = new Date(new Date().toLocaleString("en-US", { timeZone: zonaHoraria }));

    const year = hoyLocal.getFullYear();
    const month = hoyLocal.getMonth() + 1;
    const day = hoyLocal.getDate();

    // Helper para ceros a la izquierda (01, 02...)
    const pad = (n) => String(n).padStart(2, '0');

    // (Opcional) Log para estar seguro qué día está procesando
    // console.log(`📅 Fecha local calculada: ${year}-${pad(month)}-${pad(day)}`);

    for (const r of rows) {
      const {
        id_usuario,
        id_vehiculo,
        placa,
        vehiculo_nombre,
      } = r;

      // Tus textos originales
      const titulo = 'Sin registro de datos';
      const mensaje = `¡Hey!, no olvides actualizar los datos de tu ${vehiculo_nombre} (${placa}), te estás arriesgando a multas, que no se te pase.`;

      // 14:00 y 22:00
      for (const hour of [14, 22]) {

        // =================================================================
        // CAMBIO CLAVE: Construcción manual de la fecha
        // =================================================================
        // No usamos 'buildLocalOffsetDateString' porque esa función hace 'new Date()' internamente
        // y podría tomar el mes/año equivocado (UTC) si estás cerca de fin de mes/año.
        // Aquí usamos estrictamente los datos 'year', 'month', 'day' que calculamos arriba.

        const fechaProgramada = `${year}-${pad(month)}-${pad(day)}T${pad(hour)}:00:00-06:00`;

        // Tu dedup_key original (usando los datos locales seguros)
        const dedup_key = `sin_verificacion:${id_vehiculo}:${year}${pad(month)}${pad(day)}:${hour}`;

        try {
          const { rows: res } = await pool.query(
            `SELECT ok, id_notificacion, msg
             FROM public.fn_notif_programar(
               $1::int,
               $2::text,
               $3::text,
               $4::timestamptz,
               $5::int,
               $6::text,
               $7::text,
               $8::text,
               $9::jsonb,
               $10::int,
               $11::int
             )`,
            [
              id_usuario,
              titulo,
              mensaje,
              fechaProgramada,
              id_vehiculo,
              placa,
              'sin_verificacion',
              dedup_key,
              JSON.stringify({
                tipo: 'sin_verificacion',
                fuente: 'vista_programacion_notif_sin_verificacion'
              }),
              null,
              null
            ]
          );

          const ok = res?.[0]?.ok === true;
          const msg = res?.[0]?.msg || '';

          if (ok) {
            creadas++;
          } else if (msg.includes('duplicado')) {
            omitidasDuplicado++;
          } else {
            errores++;
            console.warn(`⚠️ Programar sin_verificacion veh=${id_vehiculo}: ${msg}`);
          }
        } catch (e) {
          errores++;
          console.error(`💥 Error al programar sin_verificacion veh=${id_vehiculo}:`, e.message);
        }
      }
    }

    console.log(
      `📊 Programador sin verificación: creadas=${creadas}, duplicadas=${omitidasDuplicado}, errores=${errores}.`
    );
  } catch (err) {
    console.error('💥 Error leyendo vista o programando sin verificación:', err.message);
  }
}


// ======================== NUEVO: Programador diario 12:00 ========================

/** Obtiene último día del mes actual (en número de día). */
function getLastDayOfCurrentMonth() {
  const now = new Date();
  const y = now.getFullYear();
  const m = now.getMonth(); // 0-11
  return new Date(y, m + 1, 0).getDate();
}

/** Construye una fecha con offset -06:00 en formato "YYYY-MM-DDTHH:mm:ss-06:00". */
function buildLocalOffsetDateString(day, hour = 13, minute = 0, second = 0) {
  const now = new Date();
  const y = now.getFullYear();
  const m = now.getMonth() + 1; // 1-12
  const pad = (n) => String(n).padStart(2, '0');
  return `${y}-${pad(m)}-${pad(day)}T${pad(hour)}:${pad(minute)}:${pad(second)}-06:00`;
}

/** Devuelve arreglo de días candidatos según nivel/tipo, ya filtrados por > hoy. */
function computeCandidateDays(nivelUsuario, tipo) {
  const today = new Date().getDate(); // día del mes
  const last = getLastDayOfCurrentMonth();

  // Base
  const base = [5, 17, 28];

  // Ventanas por nivel
  const last3 = [last - 2, last - 1, last].filter((d) => d >= 1);
  const last7 = [last - 6, last - 5, last - 4, last - 3, last - 2, last - 1, last].filter((d) => d >= 1);

  let days = [];

  if (tipo === 'extemporaneo') {
    // Extemporáneo: Nivel 2 -> [5]; Nivel 3 -> [5,17]; Nivel 1 no aplica
    if (nivelUsuario === 2) days = [5];
    else if (nivelUsuario === 3) days = [5, 17];
    else days = []; // nivel 1 no recibe extemporáneo
  } else if (tipo === 'leve') {
    // Leve: solo último día del mes
    days = [last];
  } else {
    // normal / urgente
    days = [...base];
    if (nivelUsuario === 2) days.push(...last3);
    if (nivelUsuario === 3) days.push(...last7);
  }

  // Quitar duplicados y filtrar estrictamente > hoy
  const uniq = Array.from(new Set(days));
  return uniq.filter((d) => d > today && d <= last).sort((a, b) => a - b);
}

/** Título/Mensaje por tipo (según lo definido). */
function buildTitleAndMessage(tipo, vehiculoNombre, placa) {
  const nom = vehiculoNombre || 'tu vehículo';
  const plc = placa || '';

  if (tipo === 'normal') {
    return {
      titulo: 'Ya le toca!',
      mensaje: `Le toca verificación a tu ${nom} (placas ${plc}). ¡Que no se te pase! Agenda tu cita.`
    };
  }
  if (tipo === 'urgente') {
    return {
      titulo: 'Que no se te pase!!!',
      mensaje: `Tenemos el tiempo encima: lleva tu ${nom} (placas ${plc}) a verificar. ¡Agenda tu cita!`
    };
  }
  if (tipo === 'leve') {
    return {
      titulo: 'Ya casi le toca!!',
      mensaje: `El siguiente mes le toca a tu ${nom} (placas ${plc}). ¡Que no se te pase! Agenda tu cita.`
    };
  }
  // extemporaneo
  return {
    titulo: '¿Se te pasó o nomás no nos avisaste?',
    mensaje: `Tu ${nom} (${plc}) tiene verificación vencida, si ya verificaste actualiza su estado, si no regularízate, ¡entra a la app!`
  };
}

/** Construye dedup_key = "YYYYMM-<tipo>-YYYYMMDD" */
function buildDedupKey(tipo, day) {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(day).padStart(2, '0');
  return `${y}${m}-${tipo}-${y}${m}${d}`;
}

/**
 * Lee la vista y programa notificaciones del MES ACTUAL
 * respetando: días > hoy, niveles, tipo desde la vista, dedup_key por día y tipo.
 */
async function programarNotificacionesMes() {
  if (JITTER_MS > 0) await sleep(Math.floor(Math.random() * JITTER_MS));
  console.log('🗓️  Programador mensual: preparando notificaciones del mes actual...');

  try {
    const { rows } = await pool.query(`
      SELECT
        id_usuario,
        id_plan,
        nivel_usuario,
        id_vehiculo,
        placa,
        estado_id,
        fecha_limite,
        vehiculo_nombre,
        tipo_notificacion
      FROM public.vista_programacion_notificaciones_mes
    `);

    if (!rows.length) {
      console.log('ℹ️  No hay vehículos elegibles en la vista para este mes.');
      return;
    }

    let creadas = 0, omitidasPorFecha = 0, omitidasDuplicado = 0, errores = 0;

    for (const r of rows) {
      const {
        id_usuario,
        nivel_usuario,
        id_vehiculo,
        placa,
        vehiculo_nombre,
        tipo_notificacion: tipo
      } = r;

      const candidateDays = computeCandidateDays(Number(nivel_usuario), String(tipo));
      if (!candidateDays.length) {
        omitidasPorFecha++;
        continue;
      }

      for (const day of candidateDays) {
        const { titulo, mensaje } = buildTitleAndMessage(String(tipo), vehiculo_nombre, placa);
        const dedup_key = buildDedupKey(String(tipo), day);
        // Fecha programada a las 12:00 con offset -06:00 (CDMX)
        const fechaProgramada = buildLocalOffsetDateString(day, 13, 0, 0);

        try {
          const { rows: res } = await pool.query(
            `SELECT ok, id_notificacion, msg
               FROM public.fn_notif_programar(
                 $1::int,  -- p_id_usuario
                 $2::text, -- p_titulo
                 $3::text, -- p_mensaje
                 $4::timestamptz, -- p_fecha_programada (guardará UTC)
                 $5::int,  -- p_id_vehiculo
                 $6::text, -- p_placa_vehiculo
                 $7::text, -- p_tipo
                 $8::text, -- p_dedup_key
                 $9::jsonb,-- p_data
                 $10::int, -- p_priority
                 $11::int  -- p_ttl_seconds
               )`,
            [
              id_usuario,
              titulo,
              mensaje,
              fechaProgramada,
              id_vehiculo,
              placa,
              String(tipo), // guardar tipo en la columna tipo
              dedup_key,
              JSON.stringify({ tipo: String(tipo), fuente: 'vista_programacion_notificaciones_mes' }),
              null,
              null
            ]
          );

          const ok = res?.[0]?.ok === true;
          const msg = res?.[0]?.msg || '';
          if (ok) {
            creadas++;
          } else if (msg.includes('duplicado')) {
            omitidasDuplicado++;
          } else {
            errores++;
            console.warn(`⚠️  Programar (${tipo}) d=${day} veh=${id_vehiculo}: ${msg}`);
          }
        } catch (e) {
          errores++;
          console.error(`💥 Error al programar (${tipo}) d=${day} veh=${id_vehiculo}:`, e.message);
        }
      }
    }

    console.log(`📊 Programador mensual: creadas=${creadas}, omitidasPorFecha=${omitidasPorFecha}, duplicadas=${omitidasDuplicado}, errores=${errores}.`);
  } catch (err) {
    console.error('💥 Error leyendo la vista o programando:', err.message);
  }
}

// ======================================================
// NUEVO: Programador de notificaciones para FORÁNEOS
// ======================================================

async function programarNotificacionesForaneos() {
  if (JITTER_MS > 0) await sleep(Math.floor(Math.random() * JITTER_MS));
  console.log('🗓️  Programador mensual (foráneos): preparando notificaciones...');

  try {
    const { rows } = await pool.query(`
      SELECT
        id_usuario,
        id_plan,
        nivel_usuario,
        id_vehiculo,
        placa,
        estado_id,
        fecha_limite,
        vehiculo_nombre,
        tipo_notificacion
      FROM public.vista_programacion_notif_foraneos_mes
    `);

    if (!rows.length) {
      console.log('ℹ️  No hay vehículos foráneos elegibles.');
      return;
    }

    let creadas = 0, omitidasPorFecha = 0, omitidasDuplicado = 0, errores = 0;

    const hoy = new Date();
    const hoyNum = hoy.getDate();

    const pad = (n) => String(n).padStart(2, '0');
    const buildFechaLocal = (day) => {
      const y = hoy.getFullYear();
      const m = hoy.getMonth() + 1;
      return `${y}-${pad(m)}-${pad(day)}T13:00:00-06:00`;
    };

    for (const r of rows) {
      const {
        id_usuario,
        nivel_usuario,
        id_vehiculo,
        placa,
        vehiculo_nombre,
        fecha_limite,
        tipo_notificacion: tipo
      } = r;

      let candidateDates = [];

      if (tipo === 'normal') {
        // Basado en la fecha límite del vehículo
        const fechaLimite = new Date(fecha_limite);
        const fechaMenos3 = new Date(fechaLimite);
        fechaMenos3.setDate(fechaLimite.getDate() - 3);

        const fechaMenos5 = new Date(fechaLimite);
        fechaMenos5.setDate(fechaLimite.getDate() - 5);

        const lastDayOfCurrentMonth = new Date(hoy.getFullYear(), hoy.getMonth() + 1, 0);
        const lastDayNum = lastDayOfCurrentMonth.getDate();

        const d3 = fechaMenos3.getDate();
        const d5 = fechaMenos5.getDate();

        // Nivel 1 → solo 3 días antes
        if (nivel_usuario === 1 && d3 > hoyNum && d3 <= lastDayNum) candidateDates.push(d3);

        // Nivel 2 → 5 y 3 días antes
        if (nivel_usuario === 2) {
          if (d5 > hoyNum && d5 <= lastDayNum) candidateDates.push(d5);
          if (d3 > hoyNum && d3 <= lastDayNum) candidateDates.push(d3);
        }

        // Nivel 3 → igual que nivel 2
        if (nivel_usuario === 3) {
          if (d5 > hoyNum && d5 <= lastDayNum) candidateDates.push(d5);
          if (d3 > hoyNum && d3 <= lastDayNum) candidateDates.push(d3);
        }
      }
      else if (tipo === 'extemporaneo') {
        // Basado en días fijos del mes actual
        const days = [];
        if (nivel_usuario === 2) days.push(1);
        if (nivel_usuario === 3) days.push(1, 5, 10);

        candidateDates = days.filter((d) => d > hoyNum);
      }

      if (!candidateDates.length) {
        omitidasPorFecha++;
        continue;
      }

      for (const day of candidateDates) {
        const fechaProgramada = buildFechaLocal(day);
        const dedup_key = `${hoy.getFullYear()}${pad(hoy.getMonth() + 1)}-${tipo}-${hoy.getFullYear()}${pad(hoy.getMonth() + 1)}${pad(day)}`;

        const { titulo, mensaje } = (() => {
          if (tipo === 'normal') {
            return {
              titulo: 'Casi le toca otra vez!',
              mensaje: `Tu ${vehiculo_nombre || 'vehículo'} (${placa || ''}) está por vencer su verificación. Hay que ir agendando una cita.`
            };
          }
          return {
            titulo: 'Ya se venció!',
            mensaje: `La verificación de tu ${vehiculo_nombre || 'vehículo'} (${placa || ''}) se venció. Renueva cuanto antes. Agenda tu cita.`
          };
        })();

        try {
          const { rows: res } = await pool.query(
            `SELECT ok, id_notificacion, msg
             FROM public.fn_notif_programar(
               $1::int,  -- id_usuario
               $2::text, -- titulo
               $3::text, -- mensaje
               $4::timestamptz,
               $5::int,  -- id_vehiculo
               $6::text, -- placa
               $7::text, -- tipo
               $8::text, -- dedup_key
               $9::jsonb,
               $10::int,
               $11::int
             )`,
            [
              id_usuario,
              titulo,
              mensaje,
              fechaProgramada,
              id_vehiculo,
              placa,
              tipo,
              dedup_key,
              JSON.stringify({ tipo, fuente: 'vista_programacion_notif_foraneos_mes' }),
              null,
              null
            ]
          );

          const ok = res?.[0]?.ok === true;
          const msg = res?.[0]?.msg || '';
          if (ok) creadas++;
          else if (msg.includes('duplicado')) omitidasDuplicado++;
          else {
            errores++;
            console.warn(`⚠️  Programar (${tipo}) d=${day} veh=${id_vehiculo}: ${msg}`);
          }
        } catch (e) {
          errores++;
          console.error(`💥 Error al programar (${tipo}) d=${day} veh=${id_vehiculo}:`, e.message);
        }
      }
    }

    console.log(`📊 Programador (foráneos): creadas=${creadas}, omitidasPorFecha=${omitidasPorFecha}, duplicadas=${omitidasDuplicado}, errores=${errores}.`);
  } catch (err) {
    console.error('💥 Error leyendo la vista foráneos o programando:', err.message);
  }
}
// ======================== Worker de envío (tuyo, intacto) ========================

const enviarNotificacionesProgramadas = async () => {
  console.log('🕒 Verificando notificaciones programadas...');
  try {
    let processed = 0;

    while (true) {
      const { rows } = await pool.query(
        'SELECT * FROM public.fn_notif_tomar_pendiente()'
      );
      if (!rows.length) break; // no hay más trabajo

      const n = rows[0];
      const {
        id,
        id_usuario,
        id_vehiculo,
        fcm_token,
        titulo,
        mensaje,
        tipo,
        dedup_key,
        data,
        priority,
        ttl_seconds,
      } = n;

      if (!fcm_token) {
        console.warn(`⚠️ Notif ${id}: usuario ${id_usuario} sin fcm_token; se omite.`);
        try {
          await pool.query(
            'SELECT ok, msg FROM public.fn_notif_post_envio($1::int,$2::int,$3::text,$4::boolean,$5::text,$6::text,$7::text)',
            [id, id_usuario, null, false, null, 'messaging/no-token', 'Usuario sin fcm_token']
          );
        } catch (_) { }
        continue;
      }

      let payloadBase = {
        id_notificacion: String(id),
        tipo_notificacion: (tipo || 'programada'),
        dedup_key: (dedup_key || ''),
        ...(id_vehiculo ? { vehiculoId: String(id_vehiculo) } : {}),
      };
      if (data) {
        try {
          const extraObj = (typeof data === 'string') ? JSON.parse(data) : data;
          payloadBase = { ...payloadBase, ...extraObj };
        } catch (e) {
          console.warn(`⚠️ Notif ${id}: error al parsear data JSON —`, e.message);
        }
      }
      const payload = sanitizeDataForFcm(payloadBase);

      const msg = {
        token: fcm_token,
        notification: { title: titulo, body: mensaje },
        data: payload,
        android: {},
        apns: {},
      };

      if (priority !== null && priority !== undefined) {
        const isHigh = Number(priority) >= 4;
        msg.android.priority = isHigh ? 'high' : 'normal';
        msg.apns.headers = { ...(msg.apns.headers || {}), 'apns-priority': isHigh ? '10' : '5' };
      }
      if (ttl_seconds !== null && ttl_seconds !== undefined) {
        const ttl = Number(ttl_seconds);
        msg.android.ttl = `${ttl}s`;
        msg.apns.headers = { ...(msg.apns.headers || {}) };
        msg.apns.headers['apns-expiration'] = `${Math.floor(Date.now() / 1000) + ttl}`;
      }

      try {
        const response = await admin.messaging().send(msg);
        console.log(`✅ Notificación ${id} enviada. FCM ID: ${response}`);
        await pool.query(
          'SELECT ok, msg FROM public.fn_notif_post_envio($1::int,$2::int,$3::text,$4::boolean,$5::text,$6::text,$7::text)',
          [id, id_usuario, fcm_token, true, response, null, null]
        );
      } catch (err) {
        const code = err.code || '';
        const message = err.message || '';
        console.error(`❌ Error enviando notificación ${id}: ${message}`);
        try {
          await pool.query(
            'SELECT ok, msg FROM public.fn_notif_post_envio($1::int,$2::int,$3::text,$4::boolean,$5::text,$6::text,$7::text)',
            [id, id_usuario, fcm_token, false, null, code, message]
          );
        } catch (e2) {
          console.error(`💥 Error en fn_notif_post_envio para notif ${id}:`, e2.message);
        }
      }

      processed++;
    }

    console.log(`🏁 Ciclo completado. Enviadas/procesadas: ${processed}.`);
  } catch (err) {
    console.error('💥 Error en el proceso de notificaciones programadas:', err);
  }
};

async function liberarNotificacionesAtrasadas() {
  try {
    const { rows } = await pool.query(
      'SELECT public.fn_notif_reliberar_atrasadas($1)',
      [10] // minutos; puedes ajustar
    );
    const count = rows?.[0]?.fn_notif_reliberar_atrasadas ?? 0;
    if (count > 0) console.log(`♻️ Liberadas ${count} notificaciones atascadas.`);
  } catch (err) {
    console.error('💥 Error al liberar notificaciones atascadas:', err.message);
  }
}

// ======================== Crons ========================

// 1) Envío (tu existente)
const cronSchedule = process.env.CRON_SCHEDULE || '*/5 * * * *'; // cada 5 minutos
console.log(`🕐 Scheduler de envío activo: ${cronSchedule}`);
cron.schedule(cronSchedule, enviarNotificacionesProgramadas);

// 2) Liberador (tu existente)
const cronSchedule2LIB = process.env.CRON_LIBERAR_SCHEDULE || '*/6 * * * *';
console.log(`🕐 Liberador activo: ${cronSchedule2LIB}`);
cron.schedule(cronSchedule2LIB, liberarNotificacionesAtrasadas);

// 3) NUEVO: Programador diario 12:00 CDMX
// Usa CRON_TZ si quieres fijar explícitamente la TZ: CRON_TZ=America/Mexico_City
const cronProgramar = process.env.CRON_PROGRAMAR_MENSUAL || '0 12 * * *';
console.log(`🕐 Programador mensual activo: ${cronProgramar} (CDMX -06:00)`);
console.log(`🕐 Programador mensual activo: ${cronProgramar} (CDMX -06:00)`);
cron.schedule(cronProgramar, async () => {
  await programarNotificacionesMes();
  await programarNotificacionesForaneos();
});

const cronScheduleSV = process.env.CRON_SIN_VERIFICACION || '0 */8 * * 0,2,4,5,6';

console.log(`🕐 Cron sin verificación activo: ${cronSchedule}`);
cron.schedule(cronScheduleSV, programarNotificacionesSinVerificacion);


module.exports = {
  enviarNotificacionesProgramadas,
  liberarNotificacionesAtrasadas,
  programarNotificacionesMes,
  programarNotificacionesSinVerificacion
};

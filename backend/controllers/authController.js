// controllers/authController.js
const pool = require('../db/pool');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const { emitirToken } = require('../utils/jwt');

const REQUIRE_EMAIL_OTP = process.env.REQUIRE_EMAIL_OTP === 'true';
const TICKET_AUD = process.env.SIGNUP_TICKET_AUDIENCE || 'yoverifico-signup';
const TICKET_ISS = process.env.SIGNUP_TICKET_ISSUER || 'yoverifico';

const client = new OAuth2Client();
const clientIds = process.env.GOOGLE_CLIENT_IDS
  ? process.env.GOOGLE_CLIENT_IDS.split(',').map((id) => id.trim())
  : [];

// TTL refresh (días)
const REFRESH_TTL_DAYS = (() => {
  const raw = String(process.env.REFRESH_TTL || '180').trim().toLowerCase();
  const m = raw.match(/^(\d+)(d)?$/);
  return m ? Number(m[1]) : 180;
})();
const REFRESH_ABSOLUTE_MAX_DAYS = (() => {
  const raw = String(process.env.REFRESH_ABSOLUTE_MAX || '365').trim().toLowerCase();
  const m = raw.match(/^(\d+)(d)?$/);
  return m ? Number(m[1]) : 365;
})();

/* ========================= HELPER LOGS/SESSIONS ========================= */
function maskToken(t) {
  if (!t || typeof t !== 'string') return String(t);
  if (t.length <= 10) return '*'.repeat(t.length);
  return t.slice(0, 4) + '…' + t.slice(-4) + ` (len=${t.length})`;
}
function logPayload(label, obj) {
  try {
    const keys = Object.keys(obj || {});
    console.log(`[auth:${label}] payload keys ->`, keys);
    console.log(`[auth:${label}] session_id=`, obj?.session_id || null, ' refresh_token=', maskToken(obj?.refresh_token));
  } catch (e) {
    console.log(`[auth:${label}] log error:`, e?.message || e);
  }
}

/**
 * Diagnóstico: verifica que la función exista con esa firma
 */
async function assertIssueSessionExists() {
  try {
    const pq = await pool.query(`
      SELECT n.nspname AS schema, p.proname AS name, pg_get_function_identity_arguments(p.oid) AS args
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE p.proname = 'auth_issue_session'
      ORDER BY 1,2,3
    `);
    console.log('[diag:auth_issue_session] rows:', pq.rowCount, pq.rows);
  } catch (e) {
    console.error('[diag:auth_issue_session] error:', e.message);
  }
}

async function issueSessionDB(userId, req) {
  await assertIssueSessionExists();

  const device = String(req.headers['x-device-label'] || 'unknown');
  const ua = String(req.headers['user-agent'] || '');
  const ipRaw = (req.headers['x-forwarded-for'] || req.socket?.remoteAddress || '').toString().split(',')[0].trim();
  const ip = ipRaw && ipRaw !== '' ? ipRaw : null;

  console.log('[auth:issueSessionDB] calling with:', {
    userId, device, ua_short: ua.slice(0, 40), ip, REFRESH_TTL_DAYS
  });

  let q;
  try {
    q = await pool.query(
      `SELECT * FROM public.auth_issue_session($1::int, $2::text, $3::text, $4::inet, $5::int, 12::int)`,
      [userId, device, ua, ip, REFRESH_TTL_DAYS]
    );
  } catch (e) {
    console.error('[auth:issueSessionDB] CALL ERROR:', e.message);
    throw e;
  }

  console.log('[auth:issueSessionDB] result rowCount =', q.rowCount, ' fields=', q.fields?.map(f => f.name));

  const row = q.rows?.[0];
  console.log('[auth:issueSessionDB] raw row =', row);

  const sess = {
    session_id: row?.session_id ?? null,
    refresh_token: row?.refresh_token ?? null,
    // la función devuelve "refresh_expires" (sin _at)
    refresh_expires_at: row?.refresh_expires ?? null,
  };

  console.log(
    '[auth:issueSessionDB] parsed => session_id =', sess.session_id,
    ' refresh_token =', maskToken(sess.refresh_token),
    ' refresh_expires_at =', sess.refresh_expires_at
  );

  return sess;
}

/* ========================= whoami ========================= */
const whoami = async (req, res) => {
  try {
    const ures = await pool.query('SELECT * FROM obtener_usuario_basico($1)', [req.usuarioId]);
    if (ures.rows.length === 0) return res.status(404).json({ msg: 'Usuario no encontrado' });
    const usuario = ures.rows[0];

    // Pedimos TODO lo necesario para el front (incluye vehi_* y puede_agregar)
    const eres = await pool.query(`
      SELECT
        -- compat con front “viejo”
        plan_codigo              AS codigo_plan
      , plan_nombre              AS nombre_plan
      , plan_codigo              AS plan_codigo
      , plan_nombre              AS plan_nombre
      , es_personalizado
      , con_anuncios
      , maximo_vehiculos
      , vehi_guardados
      , vehi_restantes
      , puede_agregar
      , '{}'::jsonb              AS caracteristicas
      FROM vista_usuario_entitlement_v1
      WHERE id_usuario = $1
      LIMIT 1
    `, [usuario.id]);

    return res.json({ usuario, entitlements: eres.rows[0] });
  } catch (err) {
    console.error('whoami error:', err);
    return res.status(500).json({ msg: 'Error del servidor' });
  }
};

/* ========================= registro ========================= */
const registro = async (req, res) => {
  console.log('SE SOLICITARON REGISTRO NORMAL');
  // captchaToken ya no se usa aquí: lo valida el middleware en rutas
  const { nombre, correo, password, fcmToken, ticket } = req.body;

  // Ticket
  let correoCanon;
  if (REQUIRE_EMAIL_OTP) {
    if (!ticket) return res.status(401).json({ msg: 'Ticket de verificación requerido' });
    try {
      const t = jwt.verify(ticket, process.env.JWT_SECRET, {
        audience: TICKET_AUD, issuer: TICKET_ISS, algorithms: ['HS256'],
      });
      const ticketEmailCanon = String(t.email || '').trim().toLowerCase();
      if (!ticketEmailCanon) return res.status(400).json({ msg: 'Ticket inválido (sin email)' });
      if (correo && ticketEmailCanon !== String(correo).trim().toLowerCase()) {
        return res.status(400).json({ msg: 'Ticket inválido para este correo' });
      }
      if (t.purpose && t.purpose !== 'signup') {
        return res.status(400).json({ msg: 'Ticket con propósito inválido' });
      }
      correoCanon = ticketEmailCanon;
    } catch (e) {
      console.warn('Ticket inválido:', e.name, e.message);
      return res.status(401).json({ msg: e.name === 'TokenExpiredError' ? 'Ticket expirado' : 'Ticket inválido' });
    }
  } else {
    if (!correo) return res.status(400).json({ msg: 'Correo requerido' });
    correoCanon = String(correo).trim().toLowerCase();
  }

  if (!password) return res.status(400).json({ msg: 'Password requerido' });
  if (!nombre) return res.status(400).json({ msg: 'Nombre requerido' });

  try {
    const hashed = await bcrypt.hash(password, 10);
    const r = await pool.query(
      'SELECT registro_usuario($1, $2, $3, $4) AS id',
      [nombre, correoCanon, hashed, fcmToken]
    );
    const usuarioId = r.rows[0]?.id;
    if (!usuarioId || usuarioId === 0) {
      return res.status(400).json({ msg: 'Correo ya registrado' });
    }

    const { rows } = await pool.query(`
      SELECT
        plan_codigo        AS codigo_plan,
        con_anuncios,
        maximo_vehiculos,
        vehi_guardados,
        vehi_restantes,
        puede_agregar,
        '{}'::jsonb        AS caracteristicas
      FROM vista_usuario_entitlement_v1
      WHERE id_usuario = $1
      LIMIT 1
    `, [usuarioId]);

    const ent = rows[0] || {};
    const plan = ent.codigo_plan || 'FREE';
    const ads = !!ent.con_anuncios;
    const maxVehiculos = Number(ent.maximo_vehiculos) > 0 ? Number(ent.maximo_vehiculos) : 1;

    const token = emitirToken({ id: usuarioId, plan, ads, maxVehiculos });

    let sess = null;
    try { sess = await issueSessionDB(usuarioId, req); }
    catch (e) { console.error('[auth] issueSession error (registro):', e?.message || e); }

    const response = {
      token,
      usuario: { id: usuarioId, correo: correoCanon, nombre },
      entitlements: {
        codigo_plan: plan,
        con_anuncios: ads,
        maximo_vehiculos: maxVehiculos,
        vehi_guardados: Number(ent.vehi_guardados) || 0,
        vehi_restantes: Number(ent.vehi_restantes) || (maxVehiculos - (Number(ent.vehi_guardados) || 0)),
        puede_agregar: !!ent.puede_agregar,
        caracteristicas: ent.caracteristicas,
      },
      ...(sess || {}),
    };
    logPayload('registro', response);
    return res.json(response);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: 'Error del servidor' });
  }
};

/* ========================= registroGoogle ========================= */
const registroGoogle = async (req, res) => {
  console.log('SE SOLICITARON LOGIN GOOGLE');
  // No aplicamos CAPTCHA aquí (lo decidiste así)
  const { idToken, fcmToken } = req.body;

  try {
    const ticket = await client.verifyIdToken({ idToken, audience: clientIds });
    const payload = ticket.getPayload();
    const correo = payload.email;
    const nombre = payload.name;
    const google_uid = payload.sub;

    const result = await pool.query(
      'SELECT * FROM registro_usuario_google($1, $2, $3, $4)',
      [nombre, correo, google_uid, fcmToken]
    );
    const userId = result.rows[0].id;
    const nombreBD = result.rows[0].nombre;

    const { rows } = await pool.query(`
      SELECT
        plan_codigo        AS codigo_plan,
        con_anuncios,
        maximo_vehiculos,
        vehi_guardados,
        vehi_restantes,
        puede_agregar,
        '{}'::jsonb        AS caracteristicas
      FROM vista_usuario_entitlement_v1
      WHERE id_usuario = $1
      LIMIT 1
    `, [userId]);

    const ent = rows[0] || {};
    const plan = ent.codigo_plan || 'FREE';
    const ads = !!ent.con_anuncios;
    const maxVehiculos = Number(ent.maximo_vehiculos) > 0 ? Number(ent.maximo_vehiculos) : 1;

    const token = emitirToken({ id: userId, plan, ads, maxVehiculos });

    let sess = null;
    try { sess = await issueSessionDB(userId, req); }
    catch (e) { console.error('[auth] issueSession error (google):', e?.message || e); }

    const response = {
      token,
      usuario: { id: userId, correo, nombreBD },
      entitlements: {
        codigo_plan: plan,
        con_anuncios: ads,
        maximo_vehiculos: maxVehiculos,
        vehi_guardados: Number(ent.vehi_guardados) || 0,
        vehi_restantes: Number(ent.vehi_restantes) || (maxVehiculos - (Number(ent.vehi_guardados) || 0)),
        puede_agregar: !!ent.puede_agregar,
        caracteristicas: ent.caracteristicas,
      },
      ...(sess || {}),
    };
    logPayload('google', response);
    return res.json(response);
  } catch (error) {
    console.error('❌ Error de verificación:', error);
    return res.status(401).json({ msg: 'Token inválido o error de autenticación' });
  }
};

/* ========================= login ========================= */
const login = async (req, res) => {
  console.log('SE SOLICITARON LOGIN ');
  // captchaToken ya no se usa aquí: lo valida el middleware en rutas
  const { correo, password, fcmToken } = req.body;

  try {
    const ures = await pool.query('SELECT * FROM obtener_usuario_por_correo($1)', [correo]);
    if (ures.rows.length === 0) return res.status(401).json({ msg: 'Correo o contraseña inválidos' });
    const user = ures.rows[0];
    const esValido = await bcrypt.compare(password, user.password);
    if (!esValido) return res.status(401).json({ msg: 'Correo o contraseña inválidos' });

    if (fcmToken) await pool.query('SELECT actualizar_fcm_token($1, $2)', [user.id, fcmToken]);

    const { rows } = await pool.query(`
      SELECT
        plan_codigo        AS codigo_plan,
        con_anuncios,
        maximo_vehiculos,
        vehi_guardados,
        vehi_restantes,
        puede_agregar,
        '{}'::jsonb        AS caracteristicas
      FROM vista_usuario_entitlement_v1
      WHERE id_usuario = $1
      LIMIT 1
    `, [user.id]);

    const ent = rows[0] || {};
    const plan = ent.codigo_plan || 'FREE';
    const ads = !!ent.con_anuncios;
    const maxVehiculos = Number(ent.maximo_vehiculos) > 0 ? Number(ent.maximo_vehiculos) : 1;

    const token = emitirToken({ id: user.id, plan, ads, maxVehiculos });

    let sess = null;
    try { sess = await issueSessionDB(user.id, req); }
    catch (e) { console.error('[auth] issueSession error (login):', e?.message || e); }

    const response = {
      token,
      usuario: { id: user.id, correo: user.correo, nombre: user.nombre },
      entitlements: {
        codigo_plan: plan,
        con_anuncios: ads,
        maximo_vehiculos: maxVehiculos,
        vehi_guardados: Number(ent.vehi_guardados) || 0,
        vehi_restantes: Number(ent.vehi_restantes) || (maxVehiculos - (Number(ent.vehi_guardados) || 0)),
        puede_agregar: !!ent.puede_agregar,
        caracteristicas: ent.caracteristicas,
      },
      ...(sess || {}),
    };
    logPayload('login', response);
    return res.json(response);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: 'Error del servidor' });
  }
};

/* ========================= getUsuario ========================= */
const getUsuario = async (req, res) => {
  console.log('USUARIO AL BACK');
  try {
    const result = await pool.query('SELECT * FROM obtener_usuario_basico($1)', [req.usuarioId]);
    if (result.rows.length === 0) return res.status(404).json({ msg: 'Usuario no encontrado' });
    return res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ msg: 'Error del servidor' });
  }
};

/* ========================= existeCorreo ========================= */
const existeCorreo = async (req, res) => {
  try {
    // captchaToken ya no se valida aquí: lo hace el middleware en rutas
    const { correo } = req.body;

    const correoCanon = String(correo || '').trim().toLowerCase();
    if (!correoCanon) return res.status(400).json({ ok: false, msg: 'Correo requerido' });

    const result = await pool.query('SELECT id FROM obtener_usuario_por_correo($1)', [correoCanon]);
    const existe = result.rows.length > 0;

    if (String(process.env.HIDE_USER_ENUMERATION || '').toLowerCase() === 'true') {
      return res.json({ ok: true });
    }
    return res.json({ ok: true, existe });
  } catch (e) {
    console.error('[existeCorreo] error:', e);
    return res.status(500).json({ ok: false, msg: 'Error al verificar correo' });
  }
};

/* ========================= existeCorreoPorIdToken (Google) ========================= */
const existeCorreoPorIdToken = async (req, res) => {
  try {
    // No usamos CAPTCHA aquí (siguiendo tu decisión)
    const idToken = String(req.body?.idToken || '').trim();
    if (!idToken) return res.status(400).json({ ok: false, msg: 'idToken requerido' });

    const ticket = await client.verifyIdToken({ idToken, audience: clientIds });
    const payload = ticket.getPayload();

    const correo = String(payload.email || '').trim().toLowerCase();
    const r = await pool.query('SELECT 1 FROM obtener_usuario_por_correo($1)', [correo]);
    return res.json({ ok: true, existe: r.rows.length > 0, correo });

  } catch (err) {
    console.error('[GID:BACK] existeCorreoPorIdToken error:', err.name, err.message);
    return res.status(401).json({ ok: false, msg: 'No se pudo verificar token Google', reason: err.message });
  }
};

/* ========================= refresh (rotación) ========================= */
const refresh = async (req, res) => {
  try {
    const sessionId = String(req.body?.session_id || '').trim();
    const refreshToken = String(req.body?.refresh_token || '').trim();

    console.log('[auth:refresh] in session_id=', sessionId || null, ' refresh_token=', maskToken(refreshToken));

    if (!sessionId || !refreshToken) {
      return res.status(400).json({ msg: 'session_id y refresh_token son requeridos' });
    }

    let rot;
    try {
      const q = await pool.query(
        'SELECT * FROM public.auth_rotate_refresh($1, $2, $3, $4)',
        [sessionId, refreshToken, REFRESH_TTL_DAYS, REFRESH_ABSOLUTE_MAX_DAYS]
      );
      console.log('[auth:refresh] rotate: rowCount=', q.rowCount, ' rows=', q.rows);
      rot = q.rows?.[0];
      if (!rot?.new_refresh_token) {
        return res.status(401).json({ msg: 'Refresh inválido' });
      }
    } catch (e) {
      const em = String(e?.message || '');
      if (em.includes('ABSOLUTE_LIFETIME_REACHED')) {
        return res.status(401).json({ msg: 'Sesión vencida: requiere login de nuevo', reason: 'absolute_lifetime' });
      }
      if (em.includes('REFRESH_NOT_FOUND_OR_EXPIRED') || em.includes('INVALID_REFRESH')) {
        return res.status(401).json({ msg: 'Refresh inválido o expirado', reason: 'invalid_refresh' });
      }
      console.error('[refresh] DB error:', e);
      return res.status(500).json({ msg: 'Error al rotar refresh' });
    }

    const sres = await pool.query(
      'SELECT user_id FROM public.auth_sessions WHERE id = $1 LIMIT 1',
      [sessionId]
    );
    if (sres.rows.length === 0) {
      return res.status(401).json({ msg: 'Sesión no encontrada' });
    }
    const userId = Number(sres.rows[0].user_id);

    const { rows } = await pool.query(`
      SELECT
        plan_codigo        AS codigo_plan,
        con_anuncios,
        maximo_vehiculos,
        vehi_guardados,
        vehi_restantes,
        puede_agregar,
        '{}'::jsonb        AS caracteristicas
      FROM vista_usuario_entitlement_v1
      WHERE id_usuario = $1
      LIMIT 1
    `, [userId]);
    const ent = rows[0] || {};
    const plan = ent.codigo_plan || 'FREE';
    const ads = !!ent.con_anuncios;
    const maxVehiculos = Number(ent.maximo_vehiculos) > 0 ? Number(ent.maximo_vehiculos) : 1;

    const accessToken = emitirToken({ id: userId, plan, ads, maxVehiculos });

    const resp = {
      access_token: accessToken,
      refresh_token: rot.new_refresh_token,
      refresh_expires_at: rot.new_expires_at,
      session_id: sessionId,
      entitlements: {
        codigo_plan: plan,
        con_anuncios: ads,
        maximo_vehiculos: maxVehiculos,
        vehi_guardados: Number(ent.vehi_guardados) || 0,
        vehi_restantes: Number(ent.vehi_restantes) || (maxVehiculos - (Number(ent.vehi_guardados) || 0)),
        puede_agregar: !!ent.puede_agregar,
        caracteristicas: ent.caracteristicas,
      },
    };
    logPayload('refresh', resp);
    return res.json(resp);
  } catch (err) {
    console.error('[refresh] error:', err);
    return res.status(500).json({ msg: 'Error del servidor' });
  }
};

module.exports = {
  registro,
  registroGoogle,
  login,
  getUsuario,
  whoami,
  existeCorreo,
  existeCorreoPorIdToken,
  refresh,
};

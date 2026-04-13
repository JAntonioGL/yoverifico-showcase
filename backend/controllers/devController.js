// 📁 controllers/devController.js
const pool = require('../db/pool');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');
const { emitirToken } = require('../utils/jwt'); // tu helper

const REQUIRE_EMAIL_OTP =
  String(process.env.REQUIRE_EMAIL_OTP ?? 'true').toLowerCase() === 'true';

const SIGNUP_TICKET_AUD =
  process.env.SIGNUP_TICKET_AUDIENCE || 'yoverifico-signup';
const SIGNUP_TICKET_ISS =
  process.env.SIGNUP_TICKET_ISSUER || 'yoverifico';

async function leerEntitlements(userId) {
  const { rows } = await pool.query(
    `SELECT codigo_plan, con_anuncios, maximo_vehiculos, caracteristicas
       FROM vista_usuario_entitlement_v1
      WHERE id_usuario = $1`,
    [userId]
  );
  return rows[0];
}

// Login sin captcha (solo para pruebas)
const loginSinCaptcha = async (req, res) => {
  console.log('SE SOLICITARON LOGIN SIN CAPTCHA');
  const { correo, password, fcmToken } = req.body;

  try {
    const result = await pool.query(
      'SELECT id, password, nombre, correo FROM usuarios WHERE correo = $1',
      [correo]
    );
    if (result.rows.length === 0) {
      return res.status(401).json({ msg: 'Correo o contraseña inválidos' });
    }

    const user = result.rows[0];
    const esValido = await bcrypt.compare(password, user.password);
    if (!esValido) {
      return res.status(401).json({ msg: 'Correo o contraseña inválidos' });
    }

    if (fcmToken) {
      await pool.query('SELECT actualizar_fcm_token($1, $2)', [user.id, fcmToken]);
    }

    // 👉 ENTITLEMENTS (plan/anuncios/límite)
    const ent = await leerEntitlements(user.id);

    // 👉 JWT con plan + anuncios + límite
    const token = emitirToken({
      id: user.id,
      plan: ent.codigo_plan,              // 'FREE' | 'COLAB' | 'PLUS' | 'FLOTILLA'
      ads: ent.con_anuncios,              // true/false
      maxVehiculos: ent.maximo_vehiculos, // 1/2/4/8
      // features: ent.caracteristicas,   // opcional
    });

    return res.json({
      token,
      usuario: { id: user.id, correo: user.correo, nombre: user.nombre },
      entitlements: {
        codigo_plan: ent.codigo_plan,
        con_anuncios: ent.con_anuncios,
        maximo_vehiculos: ent.maximo_vehiculos,
        caracteristicas: ent.caracteristicas,
      },
      modo: 'dev-sin-captcha'
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: 'Error del servidor' });
  }
};


const enviarNotificacionesPendientes = async (req, res) => {
  try {
    const resultadoNotificaciones = await pool.query(
      `SELECT id, id_usuario, id_vehiculo, placa_vehiculo, titulo, mensaje, fecha_programada
       FROM notificaciones_programadas
       WHERE enviada = FALSE`
    );

    const notificacionesAEnviar = resultadoNotificaciones.rows;
    let notificacionesEnviadas = 0;

    for (const notificacion of notificacionesAEnviar) {
      const resultadoUsuario = await pool.query(
        `SELECT fcm_token FROM usuarios WHERE id = $1`,
        [notificacion.id_usuario]
      );

      const fcmToken = resultadoUsuario.rows[0]?.fcm_token;

      if (fcmToken) {
        // ✅ CÓDIGO CORREGIDO: Construye el objeto `message`
        const message = {
          token: fcmToken,
          notification: {
            title: notificacion.titulo,
            body: notificacion.mensaje
          },
          data: {
            "id": notificacion.id.toString(),
            "id_vehiculo": notificacion.id_vehiculo.toString(),
            "placa_vehiculo": notificacion.placa_vehiculo,
            "titulo": notificacion.titulo,
            "mensaje": notificacion.mensaje,
            "fecha_programada": notificacion.fecha_programada.toISOString(),
            "enviada": "true"
          }
        };

        // ✅ CÓDIGO CORREGIDO: Usa el método `send`
        await admin.messaging().send(message);
        notificacionesEnviadas++;

        await pool.query(
          `UPDATE notificaciones_programadas SET enviada = TRUE WHERE id = $1`,
          [notificacion.id]
        );
      }
    }

    res.status(200).json({
      msg: `Proceso de envío manual completado. Se enviaron ${notificacionesEnviadas} notificaciones.`,
      enviadas: notificacionesEnviadas
    });

  } catch (error) {
    console.error('Error al enviar notificaciones manualmente:', error);
    res.status(500).json({ msg: 'Error interno del servidor.' });
  }
};


// ✅ Función para enviar una notificación de prueba
const enviarNotificacionDePrueba = async (req, res) => {
  const { userId, vehiculoId } = req.body;

  if (!userId || !vehiculoId) {
    return res.status(400).json({ msg: 'userId y vehiculoId son requeridos.' });
  }

  try {
    // 1. Obtiene el token FCM del usuario
    const resultadoUsuario = await pool.query(
      `SELECT fcm_token FROM usuarios WHERE id = $1`,
      [userId]
    );

    const fcmToken = resultadoUsuario.rows[0]?.fcm_token;

    if (!fcmToken) {
      return res.status(404).json({ msg: 'Token FCM no encontrado para este usuario.' });
    }

    // 2. Construye el mensaje de prueba
    const mensaje = {
      token: fcmToken,
      notification: {
        title: "🔔 Notificación de prueba",
        body: `Se ha enviado una prueba para el vehículo con ID ${vehiculoId}.`
      },
      data: {
        // ✅ Claves que tu app de Flutter espera
        "vehiculoId": vehiculoId.toString(),
        "tipo_notificacion": "prueba",
        "mensaje_adicional": "Estos son datos adicionales."
      }
    };

    // 3. Envía la notificación con Firebase
    await admin.messaging().send(mensaje);

    res.status(200).json({
      msg: 'Notificación de prueba enviada con éxito.',
      target: { userId, vehiculoId }
    });

  } catch (error) {
    console.error('Error al enviar la notificación de prueba:', error);
    res.status(500).json({ msg: 'Error interno del servidor.' });
  }
};


// ---- handler ----
const registroSinCaptcha = async (req, res) => {
  console.log('SE SOLICITARON REGISTRO DEV');

  const { nombre, correo, password, fcmToken, ticket } = req.body;

  // 1) Ticket (si es requerido)
  let correoCanon;
  if (REQUIRE_EMAIL_OTP) {
    if (!ticket) {
      return res.status(401).json({ msg: 'Ticket de verificación requerido' });
    }
    try {
      const t = jwt.verify(ticket, process.env.JWT_SECRET, {
        audience: SIGNUP_TICKET_AUD,
        issuer: SIGNUP_TICKET_ISS,
        algorithms: ['HS256'],
      });

      // correo del ticket -> fuente de verdad
      const ticketEmailCanon = String(t.email || '').trim().toLowerCase();
      if (!ticketEmailCanon) {
        return res.status(400).json({ msg: 'Ticket inválido (sin email)' });
      }

      // si el cliente envió correo, debe coincidir
      if (correo && ticketEmailCanon !== String(correo).trim().toLowerCase()) {
        return res.status(400).json({ msg: 'Ticket inválido para este correo' });
      }

      if (t.purpose && t.purpose !== 'signup') {
        return res.status(400).json({ msg: 'Ticket con propósito inválido' });
      }

      correoCanon = ticketEmailCanon; // usamos el del ticket
    } catch (e) {
      console.warn('Ticket inválido:', e.name, e.message);
      return res.status(401).json({ msg: e.name === 'TokenExpiredError' ? 'Ticket expirado' : 'Ticket inválido' });
    }
  } else {
    // si no se exige ticket en DEV, toma el correo del body
    if (!correo) return res.status(400).json({ msg: 'Correo requerido' });
    correoCanon = String(correo).trim().toLowerCase();
  }

  if (!password) return res.status(400).json({ msg: 'Password requerido' });
  if (!nombre) return res.status(400).json({ msg: 'Nombre requerido' });

  try {
    const hashed = await bcrypt.hash(password, 10);

    // Alta vía función SQL
    const r = await pool.query(
      'SELECT registro_usuario($1, $2, $3, $4) AS id',
      [nombre, correoCanon, hashed, fcmToken]
    );

    const usuarioId = r.rows[0]?.id;
    if (!usuarioId || usuarioId === 0) {
      return res.status(400).json({ msg: 'Correo ya registrado' });
    }

    const { rows } = await pool.query(
      `SELECT codigo_plan, con_anuncios, maximo_vehiculos, caracteristicas
         FROM vista_usuario_entitlement_v1
        WHERE id_usuario = $1`,
      [usuarioId]
    );

    const ent = rows[0] || {};
    const plan = ent.codigo_plan || 'FREE';
    const ads = !!ent.con_anuncios;
    const maxVehiculos = Number(ent.maximo_vehiculos) > 0 ? Number(ent.maximo_vehiculos) : 1;

    const token = emitirToken({ id: usuarioId, plan, ads, maxVehiculos });

    return res.json({
      token,
      usuario: { id: usuarioId, correo: correoCanon, nombre },
      entitlements: {
        codigo_plan: plan,
        con_anuncios: ads,
        maximo_vehiculos: maxVehiculos,
        caracteristicas: ent.caracteristicas,
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: 'Error del servidor' });
  }
};



module.exports = {
  loginSinCaptcha,
  enviarNotificacionesPendientes,
  enviarNotificacionDePrueba,
  registroSinCaptcha // ✅ Exporta la nueva función
};
const pool = require('../db/pool');

const guardarVehiculo = async (req, res) => {
  try {
    const { placa, modelo, linea_id, color_id, estado_id } = req.body;
    const userId = req.usuarioId;

    if (!placa || modelo == null || !linea_id || !color_id || !estado_id) {
      return res.status(400).json({ msg: 'Faltan parámetros (placa, modelo, linea_id, color_id, estado_id).' });
    }

    // Normaliza tipos
    const modeloInt = parseInt(modelo, 10);
    const lineaIdInt = parseInt(linea_id, 10);
    const colorIdInt = parseInt(color_id, 10);
    const estadoIdInt = parseInt(estado_id, 10);
    const userIdInt = parseInt(userId, 10);

    // Llama a TU procedimiento (orden exacto y casteos)
    await pool.query(
      'CALL public.insertar_vehiculo($1, $2::smallint, $3::int, $4::int, $5::int, $6::int)',
      [placa.toUpperCase(), modeloInt, lineaIdInt, colorIdInt, userIdInt, estadoIdInt]
    );

    // Estándar: 200 + {ok:true} (opcional; si prefieres 201, también está bien)
    return res.status(200).json({ ok: true, msg: 'Vehículo registrado correctamente' });
  } catch (error) {
    console.error('Error al guardar vehículo:', error);
    // (Opcional) conflicto por unique (si lo tuvieras)
    if (error.code === '23505') {
      return res.status(409).json({ msg: 'La placa ya existe para este usuario.' });
    }
    return res.status(500).json({ msg: 'Error al guardar vehículo' });
  }
};



//obetener vehiculos
const obtenerVehiculosUsuario = async (req, res) => {
  console.log('SE SOLICITARON VEHICULOS AL BACK');
  try {
    const userId = req.usuarioId;

    const resultado = await pool.query(`
      SELECT *
      FROM vista_vehiculos_usuario
      WHERE id_usuario = $1
      ORDER BY id_vehiculo ASC
    `, [userId]);

    res.json(resultado.rows);
  } catch (error) {
    console.error('Error al obtener vehículos del usuario:', error);
    res.status(500).json({ msg: 'Error al obtener vehículos del usuario' });
  }
};

const eliminarVehiculo = async (req, res) => {
  console.log('SE SOLICITO ELIMINACION DE VEHICULO');
  try {
    // El id del usuario se obtiene del token JWT
    const userId = req.usuarioId;
    // Ahora se obtiene el 'id_vehiculo' de los parámetros de la URL
    const { id_vehiculo } = req.params;


    // Llamar al procedimiento almacenado
    // La lógica de verificación y excepción se maneja directamente en el procedimiento de la base de datos
    await pool.query(
      'CALL eliminar_vehiculo($1::integer, $2::integer)',
      // Se pasa el id del vehículo y el id del usuario
      [id_vehiculo, userId]
    );

    // Si la llamada al procedimiento tiene éxito, el código continúa aquí
    res.json({ msg: 'Vehículo eliminado correctamente' });

  } catch (error) {
    // Si el procedimiento de la base de datos lanza un error, se captura aquí
    console.error('Error al eliminar vehículo:', error);
    res.status(500).json({ msg: 'Error al eliminar vehículo' });
  }
};


const actualizarVerificacion = async (req, res) => {
  console.log('SE RECIBIO ACTUALIZACION VERI');

  const { id_vehiculo, placa, holograma, fecha_verificacion, fecha_limite } = req.body;
  const userId = req.usuarioId;

  // ✅ CORRECCIÓN: Se elimina la validación para 'fecha_verificacion', permitiendo que sea nulo.
  // Solo se valida que los campos estrictamente necesarios no sean nulos.
  if (!id_vehiculo || !placa || !holograma || !fecha_limite) {
    return res.status(400).json({ msg: 'Faltan datos requeridos. Asegúrate de enviar id_vehiculo, placa, holograma y fecha_limite.' });
  }

  try {
    await pool.query('BEGIN');

    // La llamada al procedimiento ahora funcionará correctamente con 'fecha_verificacion' siendo nulo.
    await pool.query(
      'CALL actualizar_verificacion($1, $2, $3, $4, $5)',
      [id_vehiculo, placa, holograma, fecha_verificacion, fecha_limite]
    );

    await pool.query(
      'SELECT eliminar_notificaciones_vehiculo($1, $2)',
      [id_vehiculo, userId]
    );

    await pool.query('COMMIT');

    res.json({ msg: 'Verificación actualizada y notificaciones eliminadas correctamente.' });
  } catch (error) {
    await pool.query('ROLLBACK');
    console.error('Error al actualizar verificación:', error);

    if (error.code === '23514') {
      return res.status(400).json({ msg: `El valor del holograma '${holograma}' no es válido.` });
    }

    res.status(500).json({ msg: 'Error al actualizar la verificación en el servidor.' });
  }
};



module.exports = {
  guardarVehiculo,
  obtenerVehiculosUsuario,
  eliminarVehiculo,
  actualizarVerificacion,
};

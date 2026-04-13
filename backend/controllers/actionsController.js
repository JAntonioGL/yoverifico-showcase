// controllers/actionsController.js

const pool = require('../db/pool');
const ADS = require('../config/adsConfig'); // debe exponer anuncios_habilitados y LOG_DETALLADO_ADS

// ------------------------------
// Helpers
// ------------------------------
function decidirReglasAccion({ nombreAccion, plan, conAnuncios }) {
    if (!ADS.anuncios_habilitados) return { requiereAnuncio: false, modo: null };
    if (!conAnuncios) return { requiereAnuncio: false, modo: null };

    const accionesConPase = new Set([
        'agregar_vehiculo',
        'consulta_avanzada',
        'actualizar_verificacion',
        'eliminar_vehiculo',
        'editar_vehiculo',            // 🔹 nueva acción bajo pase recompensado
    ]);

    if (accionesConPase.has(nombreAccion)) {
        return { requiereAnuncio: true, modo: 'recompensado' };
    }

    return { requiereAnuncio: false, modo: null };
}

// 🔹 Helper para cupo (solo se usa en agregar_vehiculo)
async function getEntitlementCompact(idUsuario) {
    const { rows } = await pool.query(`
    SELECT
      maximo_vehiculos,
      vehi_guardados,
      vehi_restantes,
      puede_agregar
    FROM vista_usuario_entitlement_v1
    WHERE id_usuario = $1
    LIMIT 1
  `, [idUsuario]);

    const r = rows[0] || {};
    return {
        max: Number(r.maximo_vehiculos) || 1,
        guardados: Number(r.vehi_guardados) || 0,
        restantes: Number(r.vehi_restantes) ||
            ((Number(r.maximo_vehiculos) || 1) - (Number(r.vehi_guardados) || 0)),
        puedeAgregar: !!r.puede_agregar,
    };
}

// ------------------------------
// PRECHEQUEO
// POST /api/acciones/:nombre_accion/prechequeo
// ------------------------------
const prechequeoAccion = async (req, res) => {
    const nombreAccion = String(req.params.nombre_accion || '').trim();
    const idUsuario = parseInt(req.usuarioId, 10);
    const conAnuncios = typeof req.ads !== 'undefined' ? !!req.ads : true;

    if (!idUsuario) return res.status(401).json({ msg: 'No autorizado' });
    if (!nombreAccion) return res.status(400).json({ msg: 'Falta nombre de la acción' });

    try {
        // 🔹 Validación de límite solo para agregar vehículo
        if (nombreAccion === 'agregar_vehiculo') {
            const ent = await getEntitlementCompact(idUsuario);
            if (!ent.puedeAgregar) {
                return res.status(403).json({
                    error: 'limite_vehiculos',
                    msg: `Tu plan actual permite ${ent.max} vehículo${ent.max > 1 ? 's' : ''}.`,
                    requiere_anuncio: false,
                    folio: null,
                });
            }
        }

        if (ADS.LOG_DETALLADO_ADS) {
            console.log('[prechequeo]', { idUsuario, nombreAccion, conAnuncios });
        }

        // Reglas de anuncio
        const reglas = decidirReglasAccion({ nombreAccion, conAnuncios });
        if (!reglas.requiereAnuncio) {
            return res.json({ requiere_anuncio: false, modo: null, folio: null });
        }

        // Crear folio de anuncio
        const { rows } = await pool.query(
            'SELECT crear_pase_anuncio($1::integer, $2::text) AS folio',
            [idUsuario, nombreAccion]
        );
        const folio = rows?.[0]?.folio;
        console.log('[ADS:1.CREAR] Folio:', folio, 'Usuario:', idUsuario, 'Acción:', nombreAccion);
        if (!folio) return res.status(500).json({ msg: 'No se pudo generar folio' });

        return res.json({ requiere_anuncio: true, modo: reglas.modo, folio });
    } catch (err) {
        console.error('❌ prechequeoAccion error:', err);
        return res.status(500).json({ msg: 'Error del servidor' });
    }
};

// ------------------------------
// EJECUTAR
// POST /api/acciones/:nombre_accion/ejecutar
// Body: { folio?, ...payload }
// ------------------------------
const ejecutarAccion = async (req, res) => {
    const nombreAccion = String(req.params.nombre_accion || '').trim();
    const idUsuario = parseInt(req.usuarioId, 10);
    const conAnuncios = typeof req.ads !== 'undefined' ? !!req.ads : true;
    const { folio, ...payload } = req.body || {};

    if (!idUsuario) return res.status(401).json({ msg: 'No autorizado' });
    if (!nombreAccion) return res.status(400).json({ msg: 'Falta nombre de la acción' });

    try {
        const reglas = decidirReglasAccion({ nombreAccion, conAnuncios });

        // 🔧 Límite de cupo SOLO para 'agregar_vehiculo' (no afectes otras acciones)
        if (!reglas.requiereAnuncio && nombreAccion === 'agregar_vehiculo') {
            const ent = await getEntitlementCompact(idUsuario);
            if (!ent.puedeAgregar) {
                return res.status(403).json({
                    error: 'limite_vehiculos',
                    msg: `Tu plan actual permite ${ent.max} vehículo${ent.max > 1 ? 's' : ''}.`,
                });
            }
        } else if (reglas.requiereAnuncio) {
            if (!folio) return res.status(400).json({ msg: 'Falta folio para esta acción' });
            console.log('[ADS:3.CONSUMO] Intentando usar Folio:', folio, 'Usuario:', idUsuario, 'Acción:', nombreAccion);

            if (ADS.modo_aplicacion === 'suave') {
                await pool.query(
                    'SELECT marcar_pase_concedido($1::uuid, $2::text) AS resultado',
                    [folio, 'soft_suave']
                );
            } else {
                const { rows } = await pool.query(
                    'SELECT validar_y_usar_pase_anuncio($1::uuid, $2::integer, $3::text) AS resultado',
                    [folio, idUsuario, nombreAccion]
                );
                const resultado = rows?.[0]?.resultado || 'pase_invalido';
                console.log('[ADS:3.CONSUMO] Resultado validación DB:', resultado, 'Folio:', folio);

                if (resultado !== 'ok') {
                    if (resultado === 'pase_pendiente')
                        return res.status(409).json({ error: 'pase_pendiente', msg: 'Debes completar el anuncio para continuar' });
                    if (resultado === 'pase_usado')
                        return res.status(409).json({ error: 'pase_usado', msg: 'El pase ya fue utilizado' });
                    return res.status(400).json({ error: 'pase_invalido', msg: 'Pase inválido para esta acción' });
                }
            }
        }

        let resultadoAccion;

        switch (nombreAccion) {
            case 'agregar_vehiculo': {
                const { placa, modelo, linea_id, color_id, estado_id, nombre } = payload || {};
                if (!placa || modelo == null || !linea_id || !color_id || !estado_id) {
                    return res.status(400).json({ msg: 'Faltan datos para agregar vehículo' });
                }

                let nombreTrim = null;
                if (typeof nombre !== 'undefined' && nombre !== null) {
                    nombreTrim = String(nombre).trim();
                    if (nombreTrim.length === 0) nombreTrim = null;
                    if (nombreTrim && nombreTrim.length > 10) {
                        return res.status(400).json({ msg: 'El nombre del vehículo debe tener máximo 10 caracteres' });
                    }
                }

                const modeloInt = parseInt(modelo, 10);
                const lineaIdInt = parseInt(linea_id, 10);
                const colorIdInt = parseInt(color_id, 10);
                const estadoIdInt = parseInt(estado_id, 10);

                await pool.query(
                    'CALL public.insertar_vehiculo($1, $2::smallint, $3::int, $4::int, $5::int, $6::int, $7::varchar)',
                    [String(placa).toUpperCase(), modeloInt, lineaIdInt, colorIdInt, idUsuario, estadoIdInt, nombreTrim]
                );

                resultadoAccion = { ok: true };
                break;
            }

            case 'consulta_avanzada': {
                const { rows } = await pool.query(
                    'SELECT * FROM vista_vehiculos_usuario WHERE id_usuario = $1 ORDER BY id_vehiculo ASC',
                    [idUsuario]
                );
                resultadoAccion = { datos: rows };
                break;
            }

            case 'actualizar_verificacion': {
                const {
                    id_vehiculo,
                    placa,
                    holograma,
                    fecha_verificacion,
                    fecha_limite,
                } = payload || {};

                if (!id_vehiculo || !placa || !holograma || !fecha_limite) {
                    return res.status(400).json({
                        msg: 'Faltan datos requeridos. Envía id_vehiculo, placa, holograma y fecha_limite.',
                    });
                }

                const idVehiculoInt = parseInt(id_vehiculo, 10);
                const placaUpper = String(placa).toUpperCase();

                try {
                    await pool.query('BEGIN');

                    // ✅ Llama al procedimiento que ya gestiona internamente notificaciones
                    await pool.query(
                        'CALL actualizar_verificacion($1, $2, $3, $4, $5)',
                        [idVehiculoInt, placaUpper, holograma, fecha_verificacion, fecha_limite]
                    );

                    await pool.query('COMMIT');
                    resultadoAccion = { ok: true };
                } catch (error) {
                    await pool.query('ROLLBACK');
                    console.error('❌ actualizar_verificacion error:', error);

                    if (error.code === '23514') {
                        return res.status(400).json({
                            msg: `El valor del holograma '${holograma}' no es válido.`,
                        });
                    }

                    return res.status(500).json({
                        msg: 'Error al actualizar la verificación',
                    });
                }

                break;
            }

            case 'eliminar_vehiculo': {
                const { id_vehiculo } = payload || {};
                if (!id_vehiculo) return res.status(400).json({ msg: 'Falta id_vehiculo' });

                const idVehiculoInt = parseInt(id_vehiculo, 10);
                if (!Number.isInteger(idVehiculoInt)) {
                    return res.status(400).json({ msg: 'id_vehiculo inválido' });
                }

                try {
                    const result = await pool.query(
                        'SELECT public.eliminar_vehiculo($1::integer, $2::integer) AS ok',
                        [idVehiculoInt, idUsuario]
                    );
                    const ok = !!result.rows[0]?.ok;
                    if (!ok) return res.status(404).json({ msg: 'Vehículo no encontrado o no autorizado' });
                    resultadoAccion = { ok: true, id_vehiculo: idVehiculoInt };
                } catch (error) {
                    console.error('❌ eliminar_vehiculo error:', error);
                    return res.status(500).json({ msg: 'Error al eliminar vehículo' });
                }
                break;
            }

            // 🔹 NUEVO: editar_vehiculo
            case 'editar_vehiculo': {
                const {
                    id_vehiculo,
                    placa,
                    nombre,    // <=10, opcional (null = no tocar)
                    linea_id,  // int, opcional
                    color_id,  // int, opcional
                    modelo,    // int, opcional
                } = payload || {};

                // Requeridos para identificar el vehículo (proc valida por usuario + id + placa)
                if (!id_vehiculo || !placa) {
                    return res.status(400).json({ msg: 'Faltan datos requeridos: id_vehiculo y placa' });
                }

                // Normalizaciones
                const idVehiculoInt = parseInt(id_vehiculo, 10);
                if (!Number.isInteger(idVehiculoInt)) {
                    return res.status(400).json({ msg: 'id_vehiculo inválido' });
                }
                const placaUpper = String(placa).toUpperCase().trim();

                // Campos editables (cualquiera puede ser NULL => no tocar)
                let nombreTrim = null;
                if (typeof nombre !== 'undefined') {
                    if (nombre === null) {
                        nombreTrim = null; // no tocar
                    } else {
                        nombreTrim = String(nombre).trim();
                        if (nombreTrim.length === 0) nombreTrim = null;
                        if (nombreTrim && nombreTrim.length > 10) {
                            return res.status(400).json({ msg: 'El nombre del vehículo debe tener máximo 10 caracteres' });
                        }
                    }
                } // si viene undefined, lo tratamos como "no tocar" => null pasa y el proc usa COALESCE

                const lineaIdInt = (typeof linea_id !== 'undefined' && linea_id !== null) ? parseInt(linea_id, 10) : null;
                const colorIdInt = (typeof color_id !== 'undefined' && color_id !== null) ? parseInt(color_id, 10) : null;
                const modeloInt = (typeof modelo !== 'undefined' && modelo !== null) ? parseInt(modelo, 10) : null;

                const todosNulos =
                    nombreTrim === null &&
                    lineaIdInt === null &&
                    colorIdInt === null &&
                    modeloInt === null;

                if (todosNulos) {
                    return res.status(400).json({ msg: 'No hay campos para actualizar' });
                }

                try {
                    await pool.query('BEGIN');

                    // Llamar al procedimiento seguro (security definer) que valida rango/ownership
                    await pool.query(
                        'CALL public.vehiculo_actualizar($1::int, $2::int, $3::text, $4::varchar, $5::int, $6::int, $7::smallint)',
                        [idUsuario, idVehiculoInt, placaUpper, nombreTrim, lineaIdInt, colorIdInt, modeloInt]
                    );

                    await pool.query('COMMIT');
                    resultadoAccion = { ok: true };
                } catch (error) {
                    await pool.query('ROLLBACK');
                    console.error('❌ editar_vehiculo error:', error);

                    // Mapeo de errores del procedimiento
                    if (error.code === 'P0002') {
                        return res.status(404).json({ msg: 'Vehículo no encontrado o no autorizado' });
                    }
                    if (error.code === '22023') {
                        // invalid_parameter_value (rango de modelo u otros)
                        return res.status(400).json({ msg: error.message || 'Parámetros inválidos' });
                    }
                    if (error.code === '23503' || error.code === '23514') {
                        // FK o CHECK
                        return res.status(400).json({ msg: 'Datos inválidos (FK/CHECK)' });
                    }
                    return res.status(500).json({ msg: 'Error al editar vehículo' });
                }

                break;
            }

            default:
                return res.status(400).json({ msg: `Acción no soportada: ${nombreAccion}` });
        }

        return res.json({ ok: true, accion: nombreAccion, resultado: resultadoAccion });
    } catch (err) {
        console.error('❌ ejecutarAccion error:', err);
        return res.status(500).json({ msg: 'Error del servidor' });
    }
};

module.exports = {
    prechequeoAccion,
    ejecutarAccion,
};

-- =============================================
-- GESTIÓN DE IDENTIDAD Y USUARIOS
-- =============================================

/**
 * registro_usuario_google
 * Gestiona el alta de usuarios vía Social Login. 
 * Implementa lógica de 'Upsert' para sincronizar el token FCM de notificaciones.
 */
CREATE OR REPLACE FUNCTION registro_usuario_google(
  p_nombre TEXT,
  p_correo TEXT,
  p_google_uid TEXT,
  p_fcm_token TEXT
) RETURNS INTEGER AS $$
DECLARE
  v_id INTEGER;
BEGIN
  -- Lógica de resolución: Busca por UID o Correo para evitar duplicidad
  SELECT u.id INTO v_id FROM usuarios u
  WHERE u.google_uid = p_google_uid OR u.correo = p_correo;

  IF v_id IS NOT NULL THEN
    UPDATE usuarios SET fcm_token = p_fcm_token WHERE id = v_id;
  ELSE
    INSERT INTO usuarios (nombre, correo, google_uid, fcm_token)
    VALUES (p_nombre, p_correo, p_google_uid, p_fcm_token)
    RETURNING id INTO v_id;
  END IF;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =============================================
-- GESTIÓN OPERATIVA DE FLOTA
-- =============================================

/**
 * insertar_vehiculo
 * Procedimiento atómico para el alta de unidades. 
 * Realiza la traducción de nombres legibles a IDs internos de catálogo.
 */
CREATE OR REPLACE PROCEDURE insertar_vehiculo(
    IN p_marca_nombre VARCHAR,
    IN p_linea_nombre VARCHAR,
    IN p_modelo SMALLINT,
    IN p_placa VARCHAR,
    IN p_color_nombre VARCHAR,
    IN p_id_usuario INTEGER
) LANGUAGE plpgsql AS $$
DECLARE
    v_linea_id INTEGER;
    v_color_id INTEGER;
BEGIN
    -- Resolución de integridad relacional (Marca + Línea)
    SELECT l.id INTO v_linea_id
    FROM lineas_vehiculos l
    JOIN marcas_vehiculos m ON l.marca_id = m.id
    WHERE m.nombre = p_marca_nombre AND l.nombre = p_linea_nombre;

    IF v_linea_id IS NULL THEN
        RAISE EXCEPTION 'Línea o marca no encontrada en catálogos maestros';
    END IF;

    -- Resolución de ID cromático
    SELECT c.id INTO v_color_id FROM colores_vehiculos c 
    WHERE c.nombre = p_color_nombre;

    -- Persistencia con normalización de placa (Uppercase)
    INSERT INTO vehiculos (placa, modelo, linea_id, color_id, id_usuario)
    VALUES (UPPER(p_placa), p_modelo, v_linea_id, v_color_id, p_id_usuario);
END;
$$;
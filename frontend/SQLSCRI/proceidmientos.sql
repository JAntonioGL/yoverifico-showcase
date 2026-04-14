-- =============================================
-- GESTIÓN DE SESIÓN Y SEGURIDAD DE USUARIOS
-- =============================================

/**
 * registro_usuario
 * Procesa el alta de nuevos usuarios con validación de existencia previa.
 * Utiliza SECURITY DEFINER para encapsular el acceso a la tabla 'usuarios'.
 */
CREATE OR REPLACE FUNCTION registro_usuario(
  p_nombre TEXT,
  p_correo TEXT,
  p_password TEXT,
  p_fcm_token TEXT
) RETURNS INTEGER AS $$
DECLARE
  v_id INTEGER;
BEGIN
  -- Verificación de correo único para evitar duplicados
  SELECT id INTO v_id FROM usuarios WHERE correo = p_correo;

  IF v_id IS NOT NULL THEN
    RETURN 0; -- Código de control para 'Usuario ya registrado'
  ELSE
    INSERT INTO usuarios (nombre, correo, password, fcm_token)
    VALUES (p_nombre, p_correo, p_password, p_fcm_token)
    RETURNING id INTO v_id;

    RETURN v_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

/**
 * obtener_usuario_por_correo
 * Función de consulta segura para flujos de autenticación.
 */
CREATE OR REPLACE FUNCTION obtener_usuario_por_correo(
  p_correo TEXT
) RETURNS TABLE(id INTEGER, password TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT u.id, u.password FROM usuarios u WHERE u.correo = p_correo;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =============================================
-- ORQUESTACIÓN DE FLOTA (INTEGRIDAD REFERENCIAL)
-- =============================================

/**
 * insertar_vehiculo
 * Gestiona el registro de unidades realizando búsquedas cruzadas entre
 * las tablas de Marcas, Líneas y Colores para garantizar datos íntegros.
 */
CREATE OR REPLACE FUNCTION insertar_vehiculo(
    p_marca_nombre VARCHAR,
    p_linea_nombre VARCHAR,
    p_modelo SMALLINT,
    p_placa VARCHAR,
    p_color_nombre VARCHAR,
    p_id_usuario INTEGER
) RETURNS VOID AS $$
DECLARE
    v_linea_id INTEGER;
    v_color_id INTEGER;
BEGIN
    -- 1. Resolución de ID de Línea vinculada a su Marca
    SELECT l.id INTO v_linea_id
    FROM Lineas_vehiculos l
    JOIN Marcas_vehiculos m ON l.marca_id = m.id
    WHERE m.nombre = p_marca_nombre AND l.nombre = p_linea_nombre;

    IF v_linea_id IS NULL THEN
        RAISE EXCEPTION 'Error: Marca o Línea no válida en el catálogo maestro';
    END IF;

    -- 2. Resolución de ID de Color por nombre amigable
    SELECT id INTO v_color_id FROM Colores_vehiculos
    WHERE nombre = p_color_nombre;

    -- 3. Persistencia con normalización de identificador (Placa)
    INSERT INTO Vehiculos (placa, modelo, linea_id, color_id, id_usuario)
    VALUES (UPPER(p_placa), p_modelo, v_linea_id, v_color_id, p_id_usuario);
END;
$$ LANGUAGE plpgsql;
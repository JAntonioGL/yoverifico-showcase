-- =============================================
-- DEFINICIÓN DE ESTRUCTURAS (DDL)
-- Resumen del esquema relacional de YoVerifico
-- =============================================

-- 1. Gestión de Identidad
CREATE TABLE public.usuarios (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    correo TEXT UNIQUE,
    password TEXT, -- Hash Bcrypt (flujo tradicional)
    google_uid TEXT, -- ID Único (social login)
    fcm_token TEXT, -- Token para Notificaciones Push
    creado_en TIMESTAMP DEFAULT NOW()
);

-- 2. Catálogos Maestros (Normalización 3NF)
CREATE TABLE public.marcas_vehiculos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE public.lineas_vehiculos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    marca_id INTEGER NOT NULL REFERENCES marcas_vehiculos(id) ON DELETE CASCADE,
    UNIQUE (nombre, marca_id)
);

CREATE TABLE public.colores_vehiculos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

-- 3. Entidad Central: Flota Vehicular
CREATE TABLE public.vehiculos (
    placa VARCHAR(10) PRIMARY KEY, -- Identificador natural normalizado
    modelo SMALLINT NOT NULL,
    linea_id INTEGER NOT NULL REFERENCES lineas_vehiculos(id) ON DELETE CASCADE,
    color_id INTEGER REFERENCES colores_vehiculos(id) ON DELETE SET NULL,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    niv VARCHAR(50),
    -- Regla de Negocio: Validar año modelo físicamente posible
    CONSTRAINT vehiculos_modelo_check 
        CHECK (modelo >= 1900 AND modelo <= EXTRACT(YEAR FROM CURRENT_DATE)::INT + 1)
);
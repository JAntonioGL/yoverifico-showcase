CREATE TABLE usuarios (
  id SERIAL PRIMARY KEY,
  nombre TEXT,
  correo TEXT UNIQUE,
  password TEXT, -- null si es usuario solo-Google
  google_uid TEXT, -- null si es usuario tradicional
  fcm_token TEXT,
  creado_en TIMESTAMP DEFAULT NOW()
);

SELECT * FROM USUARIOS;

CREATE TABLE Marcas_vehiculos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Lineas_vehiculos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    marca_id INTEGER NOT NULL,
    FOREIGN KEY (marca_id) REFERENCES Marcas_vehiculos(id) ON DELETE CASCADE
);

ALTER TABLE lineas_vehiculos
ADD CONSTRAINT unique_linea_marca UNIQUE (nombre, marca_id);


CREATE TABLE Colores_vehiculos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);


CREATE TABLE Vehiculos (
    placa VARCHAR(10) PRIMARY KEY,
    modelo SMALLINT NOT NULL CHECK (modelo BETWEEN 1900 AND EXTRACT(YEAR FROM CURRENT_DATE)::INT + 1),
    linea_id INTEGER NOT NULL,
    color_id INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,
    niv VARCHAR(50),
    FOREIGN KEY (linea_id) REFERENCES Lineas_vehiculos(id) ON DELETE CASCADE,
    FOREIGN KEY (color_id) REFERENCES Colores_vehiculos(id) ON DELETE SET NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuarios(id) ON DELETE CASCADE
);


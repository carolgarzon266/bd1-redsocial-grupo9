CREATE TABLE programa_academico (
    id_programa SERIAL PRIMARY KEY,
    nombre_programa VARCHAR(100) NOT NULL
);

CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) UNIQUE NOT NULL,
    id_programa INT REFERENCES programa_academico(id_programa),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE publicaciones (
    id_publicacion SERIAL PRIMARY KEY,
    id_usuario INT REFERENCES usuarios(id_usuario),
    contenido TEXT,
    fecha_publicacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
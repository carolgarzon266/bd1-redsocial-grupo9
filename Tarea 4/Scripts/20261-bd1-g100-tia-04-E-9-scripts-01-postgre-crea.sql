-- SGBD: PostgreSQL

-- 1. Tabla Independiente: PROGRAMAS
CREATE TABLE programas_academicos (
    id_programa SERIAL PRIMARY KEY,
    nombre_programa VARCHAR(100) NOT NULL,
    facultad VARCHAR(100)
);

-- 2. Tabla Independiente: USUARIOS
CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    nombre_completo VARCHAR(100) NOT NULL,
    correo_institucional VARCHAR(100) UNIQUE NOT NULL,
    id_programa INT REFERENCES programas_academicos(id_programa),
    tipo_usuario VARCHAR(20) DEFAULT 'estudiante', -- estudiante, docente, egresado
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabla Dependiente: PUBLICACIONES
CREATE TABLE publicaciones (
    id_publicacion SERIAL PRIMARY KEY,
    id_usuario INT REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    contenido TEXT NOT NULL,
    url_recurso VARCHAR(255),
    fecha_publicacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabla Dependiente: COMENTARIOS
CREATE TABLE comentarios (
    id_comentario SERIAL PRIMARY KEY,
    id_publicacion INT REFERENCES publicaciones(id_publicacion) ON DELETE CASCADE,
    id_usuario INT REFERENCES usuarios(id_usuario),
    texto_comentario TEXT NOT NULL,
    fecha_comentario TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Tabla Intermedia (N:M): MIEMBROS_GRUPO
CREATE TABLE grupos_estudio (
    id_grupo SERIAL PRIMARY KEY,
    nombre_grupo VARCHAR(100) NOT NULL,
    descripcion TEXT
);

CREATE TABLE miembros_grupo (
    id_usuario INT REFERENCES usuarios(id_usuario),
    id_grupo INT REFERENCES grupos_estudio(id_grupo),
    rol VARCHAR(50) DEFAULT 'miembro',
    PRIMARY KEY (id_usuario, id_grupo)
);
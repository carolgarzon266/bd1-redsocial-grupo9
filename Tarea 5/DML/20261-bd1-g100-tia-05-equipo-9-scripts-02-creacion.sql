-- ============================================================
-- PASCUALINA_DB — SCRIPT DDL: CREACIÓN DE ESTRUCTURA
-- Tarea 5 — Bases de Datos I
-- Motor: PostgreSQL (pgAdmin4)
-- Esquema: public
-- ============================================================

-- Eliminar tablas si existen (orden inverso por dependencias FK)
DROP TABLE IF EXISTS transacciones_producto   CASCADE;
DROP TABLE IF EXISTS transacciones_servicio   CASCADE;
DROP TABLE IF EXISTS productos                CASCADE;
DROP TABLE IF EXISTS servicios                CASCADE;
DROP TABLE IF EXISTS participantes_evento     CASCADE;
DROP TABLE IF EXISTS eventos                  CASCADE;
DROP TABLE IF EXISTS miembros_grupo           CASCADE;
DROP TABLE IF EXISTS grupos                   CASCADE;
DROP TABLE IF EXISTS comentarios              CASCADE;
DROP TABLE IF EXISTS publicaciones            CASCADE;
DROP TABLE IF EXISTS seguidores               CASCADE;
DROP TABLE IF EXISTS habilidades_usuario      CASCADE;
DROP TABLE IF EXISTS intereses_usuario        CASCADE;
DROP TABLE IF EXISTS habilidades              CASCADE;
DROP TABLE IF EXISTS intereses                CASCADE;
DROP TABLE IF EXISTS perfiles                 CASCADE;
DROP TABLE IF EXISTS usuarios                 CASCADE;

-- ============================================================
-- TABLA: usuarios
-- Almacena las credenciales y datos básicos de cada estudiante
-- ============================================================
CREATE TABLE usuarios (
    id_usuario      SERIAL          PRIMARY KEY,
    nombre          VARCHAR(100)    NOT NULL,
    apellido        VARCHAR(100)    NOT NULL,
    email           VARCHAR(150)    NOT NULL UNIQUE,
    contrasena_hash VARCHAR(255)    NOT NULL,
    fecha_registro  TIMESTAMP       NOT NULL DEFAULT NOW(),
    activo          BOOLEAN         NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE  usuarios              IS 'Estudiantes registrados en la red social Pascualina';
COMMENT ON COLUMN usuarios.id_usuario   IS 'Identificador único del usuario';
COMMENT ON COLUMN usuarios.email        IS 'Correo institucional, debe ser único';

-- ============================================================
-- TABLA: perfiles
-- Información académica y personal visible del estudiante
-- ============================================================
CREATE TABLE perfiles (
    id_perfil       SERIAL          PRIMARY KEY,
    id_usuario      INT             NOT NULL UNIQUE REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    area_estudio    VARCHAR(150),
    semestre        SMALLINT        CHECK (semestre BETWEEN 1 AND 12),
    biografia       TEXT,
    foto_url        VARCHAR(255),
    fecha_actualizacion TIMESTAMP   DEFAULT NOW()
);

COMMENT ON TABLE perfiles IS 'Perfil académico y personal de cada usuario';

-- ============================================================
-- TABLA: intereses
-- Catálogo de intereses disponibles en la plataforma
-- ============================================================
CREATE TABLE intereses (
    id_interes      SERIAL          PRIMARY KEY,
    nombre          VARCHAR(100)    NOT NULL UNIQUE,
    categoria       VARCHAR(80)     -- Ej: 'tecnología', 'deportes', 'arte'
);

-- ============================================================
-- TABLA: intereses_usuario
-- Relación muchos-a-muchos: usuario ↔ intereses
-- ============================================================
CREATE TABLE intereses_usuario (
    id_usuario      INT     NOT NULL REFERENCES usuarios(id_usuario)  ON DELETE CASCADE,
    id_interes      INT     NOT NULL REFERENCES intereses(id_interes) ON DELETE CASCADE,
    PRIMARY KEY (id_usuario, id_interes)
);

-- ============================================================
-- TABLA: habilidades
-- Catálogo de habilidades (disciplinas, deportes, tecnologías)
-- ============================================================
CREATE TABLE habilidades (
    id_habilidad    SERIAL          PRIMARY KEY,
    nombre          VARCHAR(100)    NOT NULL UNIQUE,
    tipo            VARCHAR(80)     -- Ej: 'técnica', 'deportiva', 'artística'
);

-- ============================================================
-- TABLA: habilidades_usuario
-- Relación muchos-a-muchos: usuario ↔ habilidades
-- ============================================================
CREATE TABLE habilidades_usuario (
    id_usuario      INT     NOT NULL REFERENCES usuarios(id_usuario)      ON DELETE CASCADE,
    id_habilidad    INT     NOT NULL REFERENCES habilidades(id_habilidad)  ON DELETE CASCADE,
    nivel           VARCHAR(30) DEFAULT 'básico', -- básico, intermedio, avanzado
    PRIMARY KEY (id_usuario, id_habilidad)
);

-- ============================================================
-- TABLA: seguidores
-- Relación de seguimiento entre estudiantes
-- ============================================================
CREATE TABLE seguidores (
    id_seguidor     INT     NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_seguido      INT     NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    fecha_seguimiento TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id_seguidor, id_seguido),
    CHECK (id_seguidor <> id_seguido)
);

COMMENT ON TABLE seguidores IS 'Un usuario sigue a otro; diferente al seguido';

-- ============================================================
-- TABLA: publicaciones
-- Contenido publicado por los estudiantes (preguntas, recursos, memes, etc.)
-- ============================================================
CREATE TABLE publicaciones (
    id_publicacion  SERIAL          PRIMARY KEY,
    id_usuario      INT             NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    tipo            VARCHAR(50)     NOT NULL DEFAULT 'general',
                    -- 'pregunta', 'recurso', 'noticia', 'meme', 'general'
    contenido       TEXT            NOT NULL,
    imagen_url      VARCHAR(255),
    fecha_publicacion TIMESTAMP     NOT NULL DEFAULT NOW(),
    cantidad_reportes INT           NOT NULL DEFAULT 0
);

COMMENT ON TABLE publicaciones IS 'Publicaciones de los estudiantes en el feed de Pascualina';

-- ============================================================
-- TABLA: comentarios
-- Comentarios sobre publicaciones
-- ============================================================
CREATE TABLE comentarios (
    id_comentario   SERIAL          PRIMARY KEY,
    id_publicacion  INT             NOT NULL REFERENCES publicaciones(id_publicacion) ON DELETE CASCADE,
    id_usuario      INT             NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    contenido       TEXT            NOT NULL,
    fecha_comentario TIMESTAMP      NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLA: grupos
-- Grupos de estudio, hackatones, clubes, etc.
-- ============================================================
CREATE TABLE grupos (
    id_grupo        SERIAL          PRIMARY KEY,
    id_creador      INT             NOT NULL REFERENCES usuarios(id_usuario) ON DELETE RESTRICT,
    nombre          VARCHAR(150)    NOT NULL,
    descripcion     TEXT,
    tipo            VARCHAR(80)     DEFAULT 'estudio',
                    -- 'estudio', 'hackaton', 'club', 'competitivo'
    fecha_creacion  TIMESTAMP       NOT NULL DEFAULT NOW(),
    activo          BOOLEAN         NOT NULL DEFAULT TRUE
);

-- ============================================================
-- TABLA: miembros_grupo
-- Relación muchos-a-muchos: usuario ↔ grupos
-- ============================================================
CREATE TABLE miembros_grupo (
    id_grupo        INT     NOT NULL REFERENCES grupos(id_grupo)   ON DELETE CASCADE,
    id_usuario      INT     NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    rol             VARCHAR(50) DEFAULT 'miembro', -- 'admin', 'miembro'
    fecha_union     TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id_grupo, id_usuario)
);

-- ============================================================
-- TABLA: eventos
-- Eventos publicados por un usuario organizador
-- ============================================================
CREATE TABLE eventos (
    id_evento       SERIAL          PRIMARY KEY,
    id_organizador  INT             NOT NULL REFERENCES usuarios(id_usuario) ON DELETE RESTRICT,
    titulo          VARCHAR(200)    NOT NULL,
    descripcion     TEXT,
    tipo            VARCHAR(80)     DEFAULT 'social',
                    -- 'estudio', 'taller', 'social', 'hackaton'
    fecha_evento    TIMESTAMP       NOT NULL,
    lugar           VARCHAR(200),
    capacidad_max   INT,
    fecha_creacion  TIMESTAMP       NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE eventos IS 'El organizador (id_organizador) es distinto a los participantes';

-- ============================================================
-- TABLA: participantes_evento
-- Usuarios que se inscriben a un evento (distinto al organizador)
-- ============================================================
CREATE TABLE participantes_evento (
    id_evento       INT     NOT NULL REFERENCES eventos(id_evento)   ON DELETE CASCADE,
    id_usuario      INT     NOT NULL REFERENCES usuarios(id_usuario)  ON DELETE CASCADE,
    estado          VARCHAR(30) DEFAULT 'inscrito', -- 'inscrito', 'confirmado', 'cancelado'
    fecha_inscripcion TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id_evento, id_usuario)
);

-- ============================================================
-- TABLA: servicios
-- Servicios ofrecidos por estudiantes (tutorías, cursos, cambalache)
-- ============================================================
CREATE TABLE servicios (
    id_servicio     SERIAL          PRIMARY KEY,
    id_ofertante    INT             NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    titulo          VARCHAR(200)    NOT NULL,
    descripcion     TEXT,
    categoria       VARCHAR(80),    -- 'tutoría', 'curso', 'cambalache', 'otro'
    precio          NUMERIC(10,2)   NOT NULL DEFAULT 0.00,
    disponible      BOOLEAN         NOT NULL DEFAULT TRUE,
    fecha_publicacion TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLA: transacciones_servicio
-- Registro de consumo de servicios entre estudiantes
-- ============================================================
CREATE TABLE transacciones_servicio (
    id_transaccion  SERIAL          PRIMARY KEY,
    id_servicio     INT             NOT NULL REFERENCES servicios(id_servicio) ON DELETE RESTRICT,
    id_comprador    INT             NOT NULL REFERENCES usuarios(id_usuario)   ON DELETE RESTRICT,
    fecha_transaccion TIMESTAMP     NOT NULL DEFAULT NOW(),
    monto_pagado    NUMERIC(10,2)   NOT NULL,
    estado          VARCHAR(30)     DEFAULT 'completada' -- 'pendiente', 'completada', 'cancelada'
);

-- ============================================================
-- TABLA: productos
-- Productos ofrecidos por estudiantes (cambalache, venta)
-- ============================================================
CREATE TABLE productos (
    id_producto     SERIAL          PRIMARY KEY,
    id_vendedor     INT             NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    nombre          VARCHAR(200)    NOT NULL,
    descripcion     TEXT,
    categoria       VARCHAR(80),    -- 'libro', 'tecnología', 'ropa', 'otro'
    precio          NUMERIC(10,2)   NOT NULL DEFAULT 0.00,
    stock           INT             NOT NULL DEFAULT 1,
    disponible      BOOLEAN         NOT NULL DEFAULT TRUE,
    fecha_publicacion TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLA: transacciones_producto
-- Registro de compra/venta de productos entre estudiantes
-- ============================================================
CREATE TABLE transacciones_producto (
    id_transaccion  SERIAL          PRIMARY KEY,
    id_producto     INT             NOT NULL REFERENCES productos(id_producto)  ON DELETE RESTRICT,
    id_comprador    INT             NOT NULL REFERENCES usuarios(id_usuario)    ON DELETE RESTRICT,
    cantidad        INT             NOT NULL DEFAULT 1,
    fecha_transaccion TIMESTAMP     NOT NULL DEFAULT NOW(),
    monto_total     NUMERIC(10,2)   NOT NULL,
    estado          VARCHAR(30)     DEFAULT 'completada'
);

-- ============================================================
-- ÍNDICES para optimizar consultas frecuentes
-- ============================================================
CREATE INDEX idx_publicaciones_usuario   ON publicaciones(id_usuario);
CREATE INDEX idx_publicaciones_fecha     ON publicaciones(fecha_publicacion DESC);
CREATE INDEX idx_comentarios_publicacion ON comentarios(id_publicacion);
CREATE INDEX idx_miembros_usuario        ON miembros_grupo(id_usuario);
CREATE INDEX idx_participantes_evento    ON participantes_evento(id_usuario);
CREATE INDEX idx_seguidores_seguido      ON seguidores(id_seguido);
CREATE INDEX idx_servicios_ofertante     ON servicios(id_ofertante);
CREATE INDEX idx_productos_vendedor      ON productos(id_vendedor);

-- ============================================================
-- FIN DEL SCRIPT DDL
-- ============================================================

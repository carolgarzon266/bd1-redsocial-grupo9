-- ============================================================
-- RED SOCIAL PASCUALINA
-- RESPALDO TAREA 6 - ARQUITECTURA HÍBRIDA (Relacional + JSONB + IoT)
-- 20261-bd1-g100-tia-06-equipo-X-respaldo-02.sql
-- ============================================================
-- Contiene:
--   PARTE 1: DDL completo (tablas base + JSONB + IoT)
--   PARTE 2: DML - INSERTs de prueba
--   PARTE 3: Vistas
--   PARTE 4: Consultas parametrizadas (PREPARE/EXECUTE)
--   PARTE 5: Agrupamientos y funciones de agregación
--   PARTE 6: Comparativa JSON vs JSONB (EXPLAIN ANALYZE)
--   PARTE 7: Simulación Big Data e IoT
-- ============================================================

-- ============================================================
-- PARTE 1: DDL - CREACIÓN DE TABLAS
-- ============================================================

-- Tablas base (igual al respaldo 01)
DROP TABLE IF EXISTS perfil           CASCADE;
DROP TABLE IF EXISTS usuario          CASCADE;
DROP TABLE IF EXISTS tipo_usuario     CASCADE;
DROP TABLE IF EXISTS rol              CASCADE;

-- Tablas nuevas de Tarea 6
DROP TABLE IF EXISTS log_actividad    CASCADE;
DROP TABLE IF EXISTS sensor_iot       CASCADE;
DROP TABLE IF EXISTS participante_evento CASCADE;
DROP TABLE IF EXISTS evento           CASCADE;
DROP TABLE IF EXISTS miembro_grupo    CASCADE;
DROP TABLE IF EXISTS grupo            CASCADE;
DROP TABLE IF EXISTS publicacion      CASCADE;
DROP TABLE IF EXISTS seguidor         CASCADE;

-- ── Tablas base ──────────────────────────────────────────────

CREATE TABLE rol (
    id_rol          INTEGER         PRIMARY KEY,
    nombre_rol      VARCHAR(30)     NOT NULL UNIQUE,
    descripcion     VARCHAR(200)
);

CREATE TABLE tipo_usuario (
    id_tipo_usuario     INTEGER         PRIMARY KEY,
    nombre_tipo_usuario VARCHAR(40)     NOT NULL UNIQUE,
    descripcion         VARCHAR(200)
);

CREATE TABLE usuario (
    id_usuario          INTEGER         PRIMARY KEY,
    codigo_usuario      VARCHAR(20)     NOT NULL UNIQUE,
    nombres             VARCHAR(80)     NOT NULL,
    apellidos           VARCHAR(80)     NOT NULL,
    correo              VARCHAR(120)    NOT NULL UNIQUE,
    direccion           VARCHAR(120),
    fecha_nacimiento    DATE            NOT NULL,
    fecha_registro      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo              BOOLEAN         NOT NULL DEFAULT TRUE,
    id_rol              INTEGER         NOT NULL REFERENCES rol(id_rol),
    id_tipo_usuario     INTEGER         NOT NULL REFERENCES tipo_usuario(id_tipo_usuario)
);

-- ── Perfil con JSONB ─────────────────────────────────────────

CREATE TABLE perfil (
    id_perfil           INTEGER         PRIMARY KEY,
    id_usuario          INTEGER         NOT NULL UNIQUE REFERENCES usuario(id_usuario),
    informacion_perfil  JSONB           NOT NULL   -- índice GIN para búsquedas rápidas
);

CREATE INDEX idx_gin_perfil
    ON perfil USING GIN (informacion_perfil);

-- ── Publicaciones con JSONB ──────────────────────────────────

CREATE TABLE publicacion (
    id_publicacion      SERIAL          PRIMARY KEY,
    id_usuario          INTEGER         NOT NULL REFERENCES usuario(id_usuario),
    tipo_contenido      VARCHAR(30)     NOT NULL DEFAULT 'texto',
    texto               TEXT,
    metadatos           JSONB,          -- likes, hashtags, vistas, etc.
    fecha_publicacion   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    eliminada           BOOLEAN         NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_gin_pub_meta
    ON publicacion USING GIN (metadatos);

CREATE INDEX idx_pub_usuario
    ON publicacion (id_usuario);

-- ── Seguidores ───────────────────────────────────────────────

CREATE TABLE seguidor (
    id_seguidor         INTEGER         NOT NULL REFERENCES usuario(id_usuario),
    id_seguido          INTEGER         NOT NULL REFERENCES usuario(id_usuario),
    fecha_seguimiento   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_seguidor, id_seguido),
    CONSTRAINT no_autofollow CHECK (id_seguidor <> id_seguido)
);

-- ── Grupos con JSONB ─────────────────────────────────────────

CREATE TABLE grupo (
    id_grupo            SERIAL          PRIMARY KEY,
    nombre_grupo        VARCHAR(100)    NOT NULL,
    descripcion         TEXT,
    id_creador          INTEGER         NOT NULL REFERENCES usuario(id_usuario),
    datos_grupo         JSONB,          -- categoría, privacidad, reglas
    activo              BOOLEAN         NOT NULL DEFAULT TRUE,
    fecha_creacion      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_gin_grupo
    ON grupo USING GIN (datos_grupo);

CREATE TABLE miembro_grupo (
    id_grupo            INTEGER         NOT NULL REFERENCES grupo(id_grupo),
    id_usuario          INTEGER         NOT NULL REFERENCES usuario(id_usuario),
    fecha_ingreso       TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_grupo, id_usuario)
);

-- ── Eventos con JSONB ────────────────────────────────────────

CREATE TABLE evento (
    id_evento           SERIAL          PRIMARY KEY,
    nombre_evento       VARCHAR(150)    NOT NULL,
    descripcion         TEXT,
    fecha_inicio        TIMESTAMP       NOT NULL,
    fecha_fin           TIMESTAMP,
    ubicacion           VARCHAR(150),
    cupo_maximo         INTEGER         NOT NULL DEFAULT 50,
    id_organizador      INTEGER         NOT NULL REFERENCES usuario(id_usuario),
    datos_evento        JSONB,          -- categoría, modalidad, costo, ponentes
    fecha_creacion      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_gin_evento
    ON evento USING GIN (datos_evento);

CREATE TABLE participante_evento (
    id_evento           INTEGER         NOT NULL REFERENCES evento(id_evento),
    id_usuario          INTEGER         NOT NULL REFERENCES usuario(id_usuario),
    fecha_inscripcion   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_evento, id_usuario)
);

-- ── Sensores IoT con JSONB ───────────────────────────────────

CREATE TABLE sensor_iot (
    id_sensor           SERIAL          PRIMARY KEY,
    ubicacion_sensor    VARCHAR(120)    NOT NULL,
    tipo_sensor         VARCHAR(50)     NOT NULL,   -- ocupacion, temperatura, humedad, ruido
    lectura             JSONB           NOT NULL,   -- valor, unidad, alerta, timestamp
    id_evento           INTEGER         REFERENCES evento(id_evento),
    creado_en           TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_gin_sensor
    ON sensor_iot USING GIN (lectura);

CREATE INDEX idx_sensor_tipo
    ON sensor_iot (tipo_sensor, creado_en DESC);

-- ── Logs de actividad con JSONB ──────────────────────────────

CREATE TABLE log_actividad (
    id_log              SERIAL          PRIMARY KEY,
    id_usuario          INTEGER         NOT NULL REFERENCES usuario(id_usuario),
    accion              VARCHAR(50)     NOT NULL,   -- login, publicar, comentar, etc.
    detalle_log         JSONB,          -- modulo, ip, dispositivo, duracion_seg
    fecha_accion        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_gin_log
    ON log_actividad USING GIN (detalle_log);

CREATE INDEX idx_log_usuario
    ON log_actividad (id_usuario, fecha_accion DESC);

-- ============================================================
-- PARTE 2: DML - INSERCIÓN DE DATOS DE PRUEBA
-- ============================================================

-- Roles y tipos
INSERT INTO rol VALUES
    (1,'administrador','Acceso total'),
    (2,'auxiliar','Apoyo administrativo'),
    (3,'miembro','Participa en la red'),
    (4,'visitante','Acceso limitado');

INSERT INTO tipo_usuario VALUES
    (1,'estudiante','Usuario estudiante'),
    (2,'docente','Usuario docente'),
    (3,'egresado','Usuario egresado'),
    (4,'empresario','Usuario empresario'),
    (5,'invitado','Usuario invitado');

-- Usuarios
INSERT INTO usuario VALUES
    (1,'USR001','Carlos', 'Ramirez','carlos@pascualina.edu.co','Medellin', '2000-05-10',CURRENT_TIMESTAMP,TRUE,3,1),
    (2,'USR002','Laura',  'Gomez',  'laura@pascualina.edu.co', 'Bello',    '1999-03-15',CURRENT_TIMESTAMP,TRUE,2,2),
    (3,'USR003','Andres', 'Torres', 'andres@pascualina.edu.co','Envigado', '1998-09-20',CURRENT_TIMESTAMP,TRUE,1,4),
    (4,'USR004','Maria',  'Perez',  'maria@pascualina.edu.co', 'Sabaneta', '2001-11-05',CURRENT_TIMESTAMP,TRUE,3,1),
    (5,'USR005','Juan',   'Lopez',  'juan@pascualina.edu.co',  'Itagui',   '2002-07-22',CURRENT_TIMESTAMP,TRUE,3,1),
    (6,'USR006','Sofia',  'Vargas', 'sofia@pascualina.edu.co', 'Medellin', '1997-04-18',CURRENT_TIMESTAMP,TRUE,2,2),
    (7,'USR007','Diego',  'Mejia',  'diego@pascualina.edu.co', 'Envigado', '1995-08-30',CURRENT_TIMESTAMP,TRUE,3,3),
    (8,'USR008','Valeria','Castro', 'valeria@pascualina.edu.co','Medellin','2003-01-14',CURRENT_TIMESTAMP,TRUE,4,5),
    (9,'USR009','Felipe', 'Morales','felipe@pascualina.edu.co','Bello',    '2000-09-09',CURRENT_TIMESTAMP,TRUE,3,1),
    (10,'USR010','Daniela','Rios',  'daniela@pascualina.edu.co','Caldas',  '1999-12-03',CURRENT_TIMESTAMP,TRUE,2,2);

-- Perfiles JSONB
INSERT INTO perfil VALUES
    (1, 1,'{"intereses":["SQL","Python"],        "deportes":["Futbol"],   "semestre":6, "ciudad":"Medellin"}'::JSONB),
    (2, 2,'{"intereses":["IoT","Big Data"],       "deportes":["Natacion"], "programa":"Sistemas","ciudad":"Bello"}'::JSONB),
    (3, 3,'{"intereses":["Marketing"],            "deportes":["Ciclismo"], "empresa":"TechCo","ciudad":"Envigado"}'::JSONB),
    (4, 4,'{"intereses":["Diseño","UX"],          "deportes":["Yoga"],     "semestre":4,"ciudad":"Sabaneta"}'::JSONB),
    (5, 5,'{"intereses":["IA","Machine Learning"],"deportes":["Tenis"],    "semestre":8,"ciudad":"Itagui"}'::JSONB),
    (6, 6,'{"intereses":["Redes","Cloud"],        "deportes":["Natacion"], "programa":"Ingenieria","ciudad":"Medellin"}'::JSONB),
    (7, 7,'{"intereses":["Emprendimiento"],       "deportes":["Futbol"],   "empresa":"StartupX","ciudad":"Envigado"}'::JSONB),
    (8, 8,'{"intereses":["Arte","Fotografia"],    "deportes":["Baile"],    "ciudad":"Medellin"}'::JSONB),
    (9, 9,'{"intereses":["SQL","PostgreSQL"],     "deportes":["Ciclismo"], "semestre":7,"ciudad":"Bello"}'::JSONB),
    (10,10,'{"intereses":["Docencia","Python"],   "deportes":["Caminata"], "programa":"Matematicas","ciudad":"Caldas"}'::JSONB);

-- Publicaciones con JSONB
INSERT INTO publicacion (id_usuario, tipo_contenido, texto, metadatos) VALUES
    (1,'texto','Proyecto de bases de datos listo 💻',
        '{"likes":45,"comentarios":12,"compartidos":8,"vistas":320,"hashtags":["#SQL","#Pascualina"],"dispositivo":"laptop"}'::JSONB),
    (2,'imagen','Campus en el otoño 🍂',
        '{"likes":130,"comentarios":47,"compartidos":25,"vistas":1850,"hashtags":["#Campus","#Pascualina"],"dispositivo":"smartphone"}'::JSONB),
    (3,'video','Resumen feria tecnológica 🤖',
        '{"likes":87,"comentarios":33,"compartidos":14,"vistas":970,"hashtags":["#FeriaTech","#IA"],"dispositivo":"smartphone"}'::JSONB),
    (4,'texto','Grupo de estudio álgebra lineal 📚',
        '{"likes":18,"comentarios":33,"compartidos":5,"vistas":210,"hashtags":["#EstudioGrupal","#Matematicas"],"urgente":true}'::JSONB),
    (5,'enlace','Recurso gratuito SQL avanzado 🔗',
        '{"likes":72,"comentarios":8,"compartidos":41,"vistas":980,"hashtags":["#SQL","#Gratis"],"url":"https://pgexercises.com"}'::JSONB),
    (1,'imagen','Selfie en el laboratorio 🔬',
        '{"likes":55,"comentarios":10,"compartidos":3,"vistas":440,"hashtags":["#Lab","#Pascualina"],"dispositivo":"smartphone"}'::JSONB),
    (6,'texto','Clase de redes muy productiva hoy ☁️',
        '{"likes":29,"comentarios":7,"compartidos":2,"vistas":185,"hashtags":["#Redes","#Cloud"]}'::JSONB),
    (9,'texto','¿Alguien más estudia PostgreSQL en UP?',
        '{"likes":61,"comentarios":22,"compartidos":9,"vistas":530,"hashtags":["#PostgreSQL","#BaseDeDatos"]}'::JSONB);

-- Seguidores
INSERT INTO seguidor (id_seguidor, id_seguido) VALUES
    (2,1),(3,1),(4,1),(5,1),(6,1),
    (1,2),(3,2),(7,2),
    (1,3),(2,3),(4,3),
    (5,4),(6,4),
    (1,5),(2,5),(9,5);

-- Grupos con JSONB
INSERT INTO grupo (id_grupo, nombre_grupo, descripcion, id_creador, datos_grupo) VALUES
    (1,'Dev & Data UP',       'Programación y bases de datos',     1,'{"categoria":"tecnologia","privacidad":"publico","temas":["SQL","Python","IA"]}'::JSONB),
    (2,'Emprendedores UP',    'Innovación y startups',             3,'{"categoria":"negocios","privacidad":"publico","temas":["Startup","Marketing"]}'::JSONB),
    (3,'Deportes Campus',     'Actividades físicas y bienestar',   4,'{"categoria":"deporte","privacidad":"publico","temas":["Futbol","Yoga","Natacion"]}'::JSONB),
    (4,'Estudio Álgebra',     'Grupo de apoyo académico',          5,'{"categoria":"estudio","privacidad":"privado","temas":["Matematicas","Algebra"]}'::JSONB);

INSERT INTO miembro_grupo (id_grupo, id_usuario) VALUES
    (1,1),(1,2),(1,5),(1,9),(1,6),
    (2,3),(2,7),(2,8),
    (3,4),(3,6),(3,2),
    (4,5),(4,4),(4,9);

-- Eventos con JSONB
INSERT INTO evento (id_evento, nombre_evento, descripcion, fecha_inicio, fecha_fin, ubicacion, cupo_maximo, id_organizador, datos_evento) VALUES
    (1,'Hackathon Pascualina 2025','Maratón de programación 24 horas',
        '2025-08-20 08:00','2025-08-21 08:00','Auditorio Central',80,1,
        '{"categoria":"tecnologia","modalidad":"presencial","costo":0,"certificado":true,"premios":["laptop","tablet"]}'::JSONB),
    (2,'Feria de Emprendimiento','Exhibición de proyectos innovadores',
        '2025-09-10 09:00','2025-09-10 18:00','Bloque B - Plazoleta',120,3,
        '{"categoria":"negocios","modalidad":"presencial","costo":0,"certificado":false}'::JSONB),
    (3,'Semana de Bienestar','Talleres de salud mental y deporte',
        '2025-09-15 08:00','2025-09-19 18:00','Auditorio Bloque B',100,6,
        '{"categoria":"bienestar","modalidad":"hibrido","costo":0,"certificado":true,"ponentes":["Dr. Alvarez","Mg. Torres"]}'::JSONB);

INSERT INTO participante_evento (id_evento, id_usuario) VALUES
    (1,1),(1,2),(1,5),(1,9),(1,4),
    (2,3),(2,7),(2,8),(2,1),
    (3,2),(3,4),(3,6),(3,8),(3,10);

-- Sensores IoT con JSONB
INSERT INTO sensor_iot (ubicacion_sensor, tipo_sensor, lectura, id_evento) VALUES
    ('Auditorio Central','ocupacion',
        '{"valor":87,"unidad":"personas","timestamp":"2025-08-20T10:00:00Z","alerta":false,"capacidad_max":80,"sensor_id":"OCP-001"}'::JSONB, 1),
    ('Auditorio Central','ocupacion',
        '{"valor":79,"unidad":"personas","timestamp":"2025-08-20T14:00:00Z","alerta":false,"capacidad_max":80,"sensor_id":"OCP-001"}'::JSONB, 1),
    ('Bloque B - Plazoleta','ocupacion',
        '{"valor":115,"unidad":"personas","timestamp":"2025-09-10T11:00:00Z","alerta":true,"capacidad_max":120,"sensor_id":"OCP-002"}'::JSONB, 2),
    ('Laboratorio 301','temperatura',
        '{"valor":24.3,"unidad":"C","timestamp":"2025-09-15T09:00:00Z","alerta":false,"umbral_max":28,"sensor_id":"TMP-301"}'::JSONB, NULL),
    ('Biblioteca Bloque A','ruido',
        '{"valor":65,"unidad":"dB","timestamp":"2025-09-15T14:00:00Z","alerta":true,"umbral_max":60,"zona":"sala_silencio","sensor_id":"RDO-BIB"}'::JSONB, NULL),
    ('Cancha Principal','humedad',
        '{"valor":78,"unidad":"%","timestamp":"2025-09-15T16:00:00Z","alerta":false,"umbral_max":85,"sensor_id":"HUM-CAN"}'::JSONB, NULL),
    ('Auditorio Bloque B','ocupacion',
        '{"valor":95,"unidad":"personas","timestamp":"2025-09-16T10:00:00Z","alerta":false,"capacidad_max":100,"sensor_id":"OCP-003"}'::JSONB, 3),
    ('Auditorio Bloque B','temperatura',
        '{"valor":27.1,"unidad":"C","timestamp":"2025-09-16T11:30:00Z","alerta":false,"umbral_max":28,"sensor_id":"TMP-AUD"}'::JSONB, 3);

-- Logs de actividad con JSONB
INSERT INTO log_actividad (id_usuario, accion, detalle_log) VALUES
    (1,'login',     '{"modulo":"autenticacion","dispositivo":"laptop","ip":"192.168.1.10","duracion_seg":5,"resultado":"exitoso"}'::JSONB),
    (1,'publicar',  '{"modulo":"publicaciones","dispositivo":"laptop","ip":"192.168.1.10","duracion_seg":30,"id_publicacion":1}'::JSONB),
    (2,'login',     '{"modulo":"autenticacion","dispositivo":"smartphone","ip":"192.168.1.22","duracion_seg":4,"resultado":"exitoso"}'::JSONB),
    (2,'comentar',  '{"modulo":"interaccion","dispositivo":"smartphone","ip":"192.168.1.22","duracion_seg":15,"id_publicacion":1}'::JSONB),
    (3,'login',     '{"modulo":"autenticacion","dispositivo":"tablet","ip":"192.168.2.5","duracion_seg":6,"resultado":"exitoso"}'::JSONB),
    (5,'login',     '{"modulo":"autenticacion","dispositivo":"laptop","ip":"10.0.0.5","duracion_seg":3,"resultado":"exitoso"}'::JSONB),
    (5,'publicar',  '{"modulo":"publicaciones","dispositivo":"laptop","ip":"10.0.0.5","duracion_seg":45,"id_publicacion":5}'::JSONB),
    (9,'publicar',  '{"modulo":"publicaciones","dispositivo":"smartphone","ip":"192.168.3.9","duracion_seg":20,"id_publicacion":8}'::JSONB);

-- ============================================================
-- PARTE 3: VISTAS
-- ============================================================

-- Vista 1: Perfil completo del usuario con contadores
CREATE OR REPLACE VIEW vw_perfil_usuario AS
SELECT
    u.id_usuario,
    u.codigo_usuario,
    u.nombres || ' ' || u.apellidos          AS nombre_completo,
    u.correo,
    tu.nombre_tipo_usuario                   AS tipo_usuario,
    r.nombre_rol                             AS rol,
    p.informacion_perfil->>'ciudad'          AS ciudad,
    p.informacion_perfil->'intereses'        AS intereses,
    p.informacion_perfil->'deportes'         AS deportes,
    COUNT(DISTINCT s.id_seguidor)            AS total_seguidores,
    COUNT(DISTINCT pub.id_publicacion)       AS total_publicaciones
FROM usuario u
JOIN tipo_usuario tu ON tu.id_tipo_usuario = u.id_tipo_usuario
JOIN rol r           ON r.id_rol           = u.id_rol
LEFT JOIN perfil p   ON p.id_usuario       = u.id_usuario
LEFT JOIN seguidor s ON s.id_seguido       = u.id_usuario
LEFT JOIN publicacion pub ON pub.id_usuario = u.id_usuario AND pub.eliminada = FALSE
WHERE u.activo = TRUE
GROUP BY u.id_usuario, u.codigo_usuario, u.nombres, u.apellidos, u.correo,
         tu.nombre_tipo_usuario, r.nombre_rol,
         p.informacion_perfil->>'ciudad',
         p.informacion_perfil->'intereses',
         p.informacion_perfil->'deportes';

-- Vista 2: Publicaciones con métricas (desde JSONB)
CREATE OR REPLACE VIEW vw_publicacion_metricas AS
SELECT
    pub.id_publicacion,
    u.nombres || ' ' || u.apellidos          AS autor,
    pub.tipo_contenido,
    pub.texto,
    (pub.metadatos->>'likes')::INT           AS likes,
    (pub.metadatos->>'comentarios')::INT     AS comentarios,
    (pub.metadatos->>'vistas')::INT          AS vistas,
    pub.metadatos->'hashtags'                AS hashtags,
    pub.fecha_publicacion
FROM publicacion pub
JOIN usuario u ON u.id_usuario = pub.id_usuario
WHERE pub.eliminada = FALSE;

-- Vista 3: Sensores IoT con alertas activas
CREATE OR REPLACE VIEW vw_sensores_alertas AS
SELECT
    s.id_sensor,
    s.ubicacion_sensor,
    s.tipo_sensor,
    (s.lectura->>'valor')::NUMERIC           AS valor,
    s.lectura->>'unidad'                     AS unidad,
    (s.lectura->>'alerta')::BOOLEAN          AS en_alerta,
    s.lectura->>'sensor_id'                  AS sensor_id,
    s.creado_en
FROM sensor_iot s
WHERE (s.lectura->>'alerta')::BOOLEAN = TRUE;

-- Vista 4: Eventos con ocupación real vs cupo
CREATE OR REPLACE VIEW vw_evento_ocupacion AS
SELECT
    e.id_evento,
    e.nombre_evento,
    e.ubicacion,
    e.fecha_inicio,
    e.cupo_maximo,
    COUNT(DISTINCT pe.id_usuario)            AS inscritos,
    e.cupo_maximo - COUNT(DISTINCT pe.id_usuario) AS cupos_disponibles,
    e.datos_evento->>'categoria'             AS categoria,
    e.datos_evento->>'modalidad'             AS modalidad
FROM evento e
LEFT JOIN participante_evento pe ON pe.id_evento = e.id_evento
GROUP BY e.id_evento, e.nombre_evento, e.ubicacion, e.fecha_inicio,
         e.cupo_maximo, e.datos_evento->>'categoria', e.datos_evento->>'modalidad';

-- ============================================================
-- PARTE 4: CONSULTAS PARAMETRIZADAS (PREPARE / EXECUTE)
-- ============================================================

-- P1: Buscar perfiles por tipo de usuario
PREPARE perfil_por_tipo(VARCHAR) AS
    SELECT * FROM vw_perfil_usuario
    WHERE tipo_usuario = $1
    ORDER BY total_seguidores DESC;

EXECUTE perfil_por_tipo('estudiante');
EXECUTE perfil_por_tipo('docente');
DEALLOCATE perfil_por_tipo;

-- P2: Publicaciones con mínimo de likes
PREPARE pub_min_likes(INT) AS
    SELECT * FROM vw_publicacion_metricas
    WHERE likes >= $1
    ORDER BY likes DESC;

EXECUTE pub_min_likes(50);
EXECUTE pub_min_likes(20);
DEALLOCATE pub_min_likes;

-- P3: Sensores en alerta por tipo
PREPARE sensores_por_tipo(VARCHAR) AS
    SELECT * FROM vw_sensores_alertas
    WHERE tipo_sensor = $1
    ORDER BY creado_en DESC;

EXECUTE sensores_por_tipo('ocupacion');
EXECUTE sensores_por_tipo('ruido');
DEALLOCATE sensores_por_tipo;

-- P4: Eventos con cupos disponibles
PREPARE eventos_con_cupo(INT) AS
    SELECT * FROM vw_evento_ocupacion
    WHERE cupos_disponibles >= $1
    ORDER BY fecha_inicio;

EXECUTE eventos_con_cupo(5);
DEALLOCATE eventos_con_cupo;

-- P5: Perfiles con interés específico (JSONB containment)
PREPARE perfiles_por_interes(TEXT) AS
    SELECT u.nombres, u.apellidos, u.correo,
           p.informacion_perfil->'intereses' AS intereses
    FROM perfil p
    JOIN usuario u ON u.id_usuario = p.id_usuario
    WHERE p.informacion_perfil->'intereses' @> to_jsonb($1::TEXT);

EXECUTE perfiles_por_interes('SQL');
EXECUTE perfiles_por_interes('IoT');
DEALLOCATE perfiles_por_interes;

-- ============================================================
-- PARTE 5: AGRUPAMIENTOS Y FUNCIONES DE AGREGACIÓN
-- ============================================================

-- AG1: Publicaciones por tipo con métricas de engagement
SELECT
    tipo_contenido,
    COUNT(*)                                 AS total_publicaciones,
    SUM((metadatos->>'likes')::INT)          AS total_likes,
    AVG((metadatos->>'likes')::INT)          AS promedio_likes,
    MAX((metadatos->>'likes')::INT)          AS max_likes,
    SUM((metadatos->>'vistas')::INT)         AS total_vistas
FROM publicacion
WHERE eliminada = FALSE
GROUP BY tipo_contenido
ORDER BY total_likes DESC;

-- AG2: Usuarios más seguidos por tipo de usuario
SELECT
    tu.nombre_tipo_usuario,
    COUNT(DISTINCT u.id_usuario)             AS cantidad_usuarios,
    SUM(sub.seguidores)                      AS total_seguidores_tipo,
    ROUND(AVG(sub.seguidores), 2)            AS promedio_seguidores
FROM usuario u
JOIN tipo_usuario tu ON tu.id_tipo_usuario = u.id_tipo_usuario
JOIN (
    SELECT id_seguido, COUNT(*) AS seguidores
    FROM seguidor
    GROUP BY id_seguido
) sub ON sub.id_seguido = u.id_usuario
WHERE u.activo = TRUE
GROUP BY tu.nombre_tipo_usuario
HAVING COUNT(DISTINCT u.id_usuario) >= 1
ORDER BY promedio_seguidores DESC;

-- AG3: Eventos con mayor participación por categoría
SELECT
    e.datos_evento->>'categoria'             AS categoria,
    COUNT(DISTINCT e.id_evento)              AS total_eventos,
    SUM(e.cupo_maximo)                       AS cupos_totales,
    COUNT(DISTINCT pe.id_usuario)            AS total_participantes,
    ROUND(COUNT(DISTINCT pe.id_usuario)::NUMERIC
          / NULLIF(SUM(e.cupo_maximo), 0) * 100, 2) AS pct_ocupacion
FROM evento e
LEFT JOIN participante_evento pe ON pe.id_evento = e.id_evento
GROUP BY e.datos_evento->>'categoria'
ORDER BY pct_ocupacion DESC;

-- AG4: Actividad de sensores IoT por tipo (alertas vs normales)
SELECT
    tipo_sensor,
    ubicacion_sensor,
    COUNT(*)                                 AS total_lecturas,
    COUNT(*) FILTER (WHERE (lectura->>'alerta')::BOOLEAN = TRUE)  AS con_alerta,
    COUNT(*) FILTER (WHERE (lectura->>'alerta')::BOOLEAN = FALSE) AS sin_alerta,
    ROUND(AVG((lectura->>'valor')::NUMERIC), 2) AS promedio_valor,
    MAX((lectura->>'valor')::NUMERIC)        AS valor_maximo
FROM sensor_iot
GROUP BY tipo_sensor, ubicacion_sensor
ORDER BY con_alerta DESC, total_lecturas DESC;

-- AG5: Grupos con más actividad y miembros
SELECT
    g.nombre_grupo,
    g.datos_grupo->>'categoria'              AS categoria,
    COUNT(DISTINCT mg.id_usuario)            AS total_miembros,
    COUNT(DISTINCT pub.id_publicacion)       AS publicaciones_totales,
    COALESCE(SUM((pub.metadatos->>'likes')::INT), 0) AS likes_totales
FROM grupo g
LEFT JOIN miembro_grupo mg ON mg.id_grupo = g.id_grupo
LEFT JOIN publicacion pub  ON pub.id_usuario IN (
    SELECT id_usuario FROM miembro_grupo WHERE id_grupo = g.id_grupo
) AND pub.eliminada = FALSE
WHERE g.activo = TRUE
GROUP BY g.id_grupo, g.nombre_grupo, g.datos_grupo->>'categoria'
HAVING COUNT(DISTINCT mg.id_usuario) >= 1
ORDER BY total_miembros DESC;

-- ============================================================
-- PARTE 6: COMPARATIVA JSON vs JSONB (rendimiento)
-- ============================================================

-- Tabla de comparación
CREATE TABLE IF NOT EXISTS comp_json  (id SERIAL PRIMARY KEY, payload JSON,  ts TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS comp_jsonb (id SERIAL PRIMARY KEY, payload JSONB, ts TIMESTAMPTZ DEFAULT NOW());
CREATE INDEX IF NOT EXISTS idx_gin_comp ON comp_jsonb USING GIN(payload);

-- Insertar 500 filas en ambas
DO $$
DECLARE i INT; v NUMERIC; a BOOLEAN; p TEXT;
BEGIN
    FOR i IN 1..500 LOOP
        v := ROUND((RANDOM()*100)::NUMERIC,2);
        a := v > 75;
        p := format('{"sensor":"SEN-%s","valor":%s,"alerta":%s,"tipo":"ocupacion"}',
                    LPAD(i::TEXT,4,'0'), v, a);
        INSERT INTO comp_json  (payload) VALUES (p::JSON);
        INSERT INTO comp_jsonb (payload) VALUES (p::JSONB);
    END LOOP;
END;$$;

-- Comparar tamaños
SELECT 'comp_json'  AS tabla, pg_size_pretty(pg_total_relation_size('comp_json'))  AS tamanio
UNION ALL
SELECT 'comp_jsonb', pg_size_pretty(pg_total_relation_size('comp_jsonb'));

-- EXPLAIN ANALYZE: JSON (sin índice — Seq Scan)
EXPLAIN (ANALYZE, FORMAT TEXT)
SELECT COUNT(*) FROM comp_json WHERE payload->>'tipo' = 'ocupacion' AND (payload->>'alerta')::BOOLEAN = TRUE;

-- EXPLAIN ANALYZE: JSONB (con índice GIN — Bitmap Index Scan)
EXPLAIN (ANALYZE, FORMAT TEXT)
SELECT COUNT(*) FROM comp_jsonb WHERE payload @> '{"tipo":"ocupacion","alerta":true}'::JSONB;

-- ============================================================
-- PARTE 7: SIMULACIÓN Big Data e IoT (ingesta masiva)
-- ============================================================

-- Tabla particionada para publicaciones masivas
CREATE TABLE IF NOT EXISTS pub_bigdata (
    id_pub         BIGSERIAL,
    id_usuario     INT           NOT NULL,
    tipo_contenido VARCHAR(30)   NOT NULL DEFAULT 'texto',
    metadatos      JSONB,
    fecha          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    eliminada      BOOLEAN       NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_pub, fecha)
) PARTITION BY RANGE (fecha);

CREATE TABLE IF NOT EXISTS pub_bigdata_2025
    PARTITION OF pub_bigdata
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE INDEX IF NOT EXISTS idx_gin_pub_bd ON pub_bigdata USING GIN(metadatos);

-- Ingesta de 10 000 publicaciones simuladas
DO $$
DECLARE
    i    INT;
    tags TEXT[] := ARRAY['#SQL','#Pascualina','#IA','#Campus','#Data'];
    v_likes INT; v_vistas INT;
BEGIN
    FOR i IN 1..10000 LOOP
        v_likes  := (RANDOM()*300)::INT;
        v_vistas := v_likes * (2 + (RANDOM()*8)::INT);
        INSERT INTO pub_bigdata (id_usuario, tipo_contenido, metadatos, fecha)
        VALUES (
            1 + (RANDOM()*9)::INT,
            CASE (RANDOM()*3)::INT WHEN 0 THEN 'texto' WHEN 1 THEN 'imagen' ELSE 'video' END,
            jsonb_build_object(
                'likes', v_likes, 'vistas', v_vistas,
                'hashtags', jsonb_build_array(tags[1+(RANDOM()*4)::INT]),
                'batch', CEIL(i::NUMERIC/1000)
            ),
            NOW() - (RANDOM() * INTERVAL '365 days')
        );
    END LOOP;
END;$$;

SELECT COUNT(*) AS total_bigdata FROM pub_bigdata;

-- Análisis de rendimiento con particiones
EXPLAIN (ANALYZE, FORMAT TEXT)
SELECT tipo_contenido, COUNT(*), AVG((metadatos->>'likes')::INT)
FROM pub_bigdata
WHERE fecha BETWEEN '2025-01-01' AND '2025-12-31'
  AND eliminada = FALSE
GROUP BY tipo_contenido;

-- ============================================================
-- VERIFICACIÓN FINAL
-- ============================================================
SELECT 'rol'               AS tabla, COUNT(*) AS registros FROM rol
UNION ALL SELECT 'tipo_usuario',    COUNT(*) FROM tipo_usuario
UNION ALL SELECT 'usuario',         COUNT(*) FROM usuario
UNION ALL SELECT 'perfil',          COUNT(*) FROM perfil
UNION ALL SELECT 'publicacion',     COUNT(*) FROM publicacion   WHERE eliminada = FALSE
UNION ALL SELECT 'seguidor',        COUNT(*) FROM seguidor
UNION ALL SELECT 'grupo',           COUNT(*) FROM grupo          WHERE activo    = TRUE
UNION ALL SELECT 'miembro_grupo',   COUNT(*) FROM miembro_grupo
UNION ALL SELECT 'evento',          COUNT(*) FROM evento
UNION ALL SELECT 'participante',    COUNT(*) FROM participante_evento
UNION ALL SELECT 'sensor_iot',      COUNT(*) FROM sensor_iot
UNION ALL SELECT 'log_actividad',   COUNT(*) FROM log_actividad
UNION ALL SELECT 'pub_bigdata',     COUNT(*) FROM pub_bigdata;

-- ============================================================
-- FIN RESPALDO 02 - TAREA 6 COMPLETA
-- ============================================================

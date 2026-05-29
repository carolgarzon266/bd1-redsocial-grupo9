-- ============================================================
-- RED SOCIAL UNIVERSITARIA PASCUALINA
-- TAREA 6 - SCRIPT 04: OPERACIONES DML CON TIPO JSONB
-- INSERT · UPDATE · DELETE · SELECT + ÍNDICES GIN
-- Nota: JSONB almacena binario, soporta índices GIN y @>
-- ============================================================

-- ============================================================
-- SECCIÓN 0 – Creación de tabla con JSONB e índices GIN
-- (Si ya existe en DDL base, este bloque muestra la estructura)
-- ============================================================

-- Tabla de publicaciones enriquecida con JSONB
CREATE TABLE IF NOT EXISTS publicaciones_jsonb (
    id_pub_jsonb       SERIAL PRIMARY KEY,
    id_autor           INT           NOT NULL REFERENCES usuarios(id_usuario),
    tipo_contenido     VARCHAR(30)   NOT NULL DEFAULT 'texto',
    texto_publicacion  TEXT,
    metadatos_b        JSONB,        -- JSONB: indexable, eficiente en filtros
    fecha_publicacion  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    eliminada          BOOLEAN       NOT NULL DEFAULT FALSE
);

-- Índice GIN general sobre metadatos_b (soporta @>, ?, ?|, ?&)
CREATE INDEX IF NOT EXISTS idx_gin_metadatos_b
    ON publicaciones_jsonb USING GIN (metadatos_b);

-- Índice GIN solo sobre el arreglo de hashtags (jsonb_path_ops)
CREATE INDEX IF NOT EXISTS idx_gin_hashtags_b
    ON publicaciones_jsonb USING GIN ((metadatos_b -> 'hashtags'));

-- Índice B-Tree sobre campo extraído: likes (para ORDER BY rápido)
CREATE INDEX IF NOT EXISTS idx_btree_likes_jsonb
    ON publicaciones_jsonb (((metadatos_b->>'likes')::INT) DESC);

-- Tabla de sensores IoT con JSONB
CREATE TABLE IF NOT EXISTS sensores_jsonb (
    id_sensor_b    SERIAL PRIMARY KEY,
    ubicacion      VARCHAR(100)  NOT NULL,
    tipo_sensor    VARCHAR(50)   NOT NULL,
    lectura_b      JSONB,        -- lecturas IoT en JSONB
    id_evento      INT           REFERENCES eventos(id_evento),
    creado_en      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_gin_lectura_b
    ON sensores_jsonb USING GIN (lectura_b);

-- ============================================================
-- SECCIÓN 1 – INSERT con JSONB
-- ============================================================

-- JB-INS-1: Publicaciones con metadatos JSONB
INSERT INTO publicaciones_jsonb
    (id_autor, tipo_contenido, texto_publicacion, metadatos_b)
VALUES
(1, 'imagen',
 'Entrega del proyecto de bases de datos — ¡listo! 💻',
 '{"likes":45, "comentarios":12, "compartidos":8, "vistas":320,
   "hashtags":["#BaseDeDatos","#Pascualina","#SistemasUP"],
   "ubicacion":"Laboratorio 301",
   "dispositivo":"laptop",
   "tipo_media":"imagen/jpeg",
   "resolucion":"1920x1080",
   "etiquetas_personas":[2,3]}'::JSONB),

(2, 'video',
 'Resumen de la feria tecnológica — impresionante 🤖',
 '{"likes":130, "comentarios":47, "compartidos":25, "vistas":1850,
   "hashtags":["#FeriaTech","#IA","#Innovacion","#Pascualina"],
   "ubicacion":"Auditorio Central",
   "dispositivo":"smartphone",
   "duracion_seg":92,
   "resolucion":"4K",
   "subtitulos":true}'::JSONB),

(3, 'texto',
 'Buscamos compañeros para grupo de estudio de álgebra lineal 📚',
 '{"likes":18, "comentarios":33, "compartidos":5, "vistas":210,
   "hashtags":["#EstudioGrupal","#Matematicas","#AlgebraLineal"],
   "ubicacion":null,
   "dispositivo":"tablet",
   "urgente":true,
   "horario_propuesto":"Lunes 3pm"}'::JSONB),

(1, 'enlace',
 'Recurso gratuito de SQL avanzado — imprescindible 🔗',
 '{"likes":72, "comentarios":8, "compartidos":41, "vistas":980,
   "hashtags":["#SQL","#BaseDeDatos","#Gratis"],
   "url":"https://pgexercises.com",
   "dominio":"pgexercises.com",
   "dispositivo":"laptop"}'::JSONB);

-- JB-INS-2: Lecturas de sensores IoT (JSONB)
INSERT INTO sensores_jsonb
    (ubicacion, tipo_sensor, lectura_b, id_evento)
VALUES
('Auditorio Central - Piso 1', 'ocupacion',
 '{"valor":87, "unidad":"personas",
   "timestamp":"2025-09-15T10:00:00Z",
   "alerta":false, "capacidad_max":120,
   "pct_ocupacion":72.5, "sensor_id":"OCP-001"}'::JSONB, 1),

('Auditorio Central - Piso 1', 'ocupacion',
 '{"valor":115, "unidad":"personas",
   "timestamp":"2025-09-15T11:30:00Z",
   "alerta":true, "capacidad_max":120,
   "pct_ocupacion":95.8, "sensor_id":"OCP-001"}'::JSONB, 1),

('Laboratorio 301', 'temperatura',
 '{"valor":24.3, "unidad":"°C",
   "timestamp":"2025-09-15T09:45:00Z",
   "alerta":false, "umbral_max":28,
   "sensor_id":"TMP-301"}'::JSONB, NULL),

('Biblioteca Bloque A', 'ruido',
 '{"valor":62, "unidad":"dB",
   "timestamp":"2025-09-15T14:00:00Z",
   "alerta":true, "umbral_max":60,
   "zona":"sala_silencio",
   "sensor_id":"RDO-BIB-A"}'::JSONB, NULL),

('Cancha Principal', 'humedad',
 '{"valor":78, "unidad":"%",
   "timestamp":"2025-09-15T16:00:00Z",
   "alerta":false, "umbral_max":85,
   "sensor_id":"HUM-CAN-01"}'::JSONB, NULL);

-- ============================================================
-- SECCIÓN 2 – SELECT eficiente con JSONB (usa índices GIN)
-- ============================================================

-- JB-SEL-1: Containment @> — publicaciones con hashtag específico
--           (usa idx_gin_hashtags_b)
SELECT
    id_pub_jsonb,
    texto_publicacion,
    metadatos_b->>'likes'        AS likes,
    metadatos_b->'hashtags'      AS hashtags
FROM publicaciones_jsonb
WHERE metadatos_b->'hashtags' @> '["#Pascualina"]'::JSONB
  AND eliminada = FALSE
ORDER BY (metadatos_b->>'likes')::INT DESC;

-- JB-SEL-2: Key existence ? — publicaciones que tienen campo 'url'
SELECT
    id_pub_jsonb,
    texto_publicacion,
    metadatos_b->>'url'          AS url,
    metadatos_b->>'dominio'      AS dominio
FROM publicaciones_jsonb
WHERE metadatos_b ? 'url'
  AND eliminada = FALSE;

-- JB-SEL-3: Any key ?| — sensores con campo 'zona' o 'pct_ocupacion'
SELECT
    id_sensor_b,
    ubicacion,
    tipo_sensor,
    lectura_b
FROM sensores_jsonb
WHERE lectura_b ?| ARRAY['zona', 'pct_ocupacion'];

-- JB-SEL-4: All keys ?& — lecturas que tienen 'alerta' Y 'umbral_max'
SELECT
    id_sensor_b,
    ubicacion,
    tipo_sensor,
    (lectura_b->>'valor')::NUMERIC   AS valor,
    lectura_b->>'unidad'             AS unidad,
    (lectura_b->>'alerta')::BOOLEAN  AS en_alerta
FROM sensores_jsonb
WHERE lectura_b ?& ARRAY['alerta', 'umbral_max']
  AND (lectura_b->>'alerta')::BOOLEAN = TRUE;

-- JB-SEL-5: jsonb_each — expander todos los campos de metadatos
SELECT
    id_pub_jsonb,
    clave,
    valor
FROM publicaciones_jsonb,
LATERAL jsonb_each_text(metadatos_b) AS j(clave, valor)
WHERE id_pub_jsonb = 1
ORDER BY clave;

-- JB-SEL-6: jsonb_array_elements — expandir hashtags como filas
SELECT
    p.id_pub_jsonb,
    p.texto_publicacion,
    tag.hashtag
FROM publicaciones_jsonb p,
LATERAL jsonb_array_elements_text(p.metadatos_b->'hashtags') AS tag(hashtag)
WHERE p.eliminada = FALSE
ORDER BY p.id_pub_jsonb, tag.hashtag;

-- JB-SEL-7: jsonb_path_query (SQL/JSON Path — PostgreSQL 12+)
--           Obtener publicaciones donde likes > 50
SELECT
    id_pub_jsonb,
    texto_publicacion,
    jsonb_path_query_first(metadatos_b, '$.likes')::INT AS likes
FROM publicaciones_jsonb
WHERE jsonb_path_exists(metadatos_b, '$.likes ? (@ > 50)')
  AND eliminada = FALSE
ORDER BY likes DESC;

-- JB-SEL-8: Sensores en alerta con occupancy > 90%
SELECT
    ubicacion,
    tipo_sensor,
    (lectura_b->>'valor')::INT             AS personas,
    (lectura_b->>'capacidad_max')::INT     AS capacidad,
    (lectura_b->>'pct_ocupacion')::NUMERIC AS pct_ocupacion,
    lectura_b->>'sensor_id'               AS sensor_id
FROM sensores_jsonb
WHERE tipo_sensor = 'ocupacion'
  AND (lectura_b->>'pct_ocupacion')::NUMERIC > 90;

-- ============================================================
-- SECCIÓN 3 – UPDATE con operadores JSONB (||, -)
-- ============================================================

-- JB-UPD-1: Concatenar (||) para agregar/sobrescribir campo
UPDATE publicaciones_jsonb
SET metadatos_b = metadatos_b || '{"verificado":true, "likes":160}'::JSONB
WHERE id_pub_jsonb = 2;

-- JB-UPD-2: Eliminar clave con operador -
UPDATE publicaciones_jsonb
SET metadatos_b = metadatos_b - 'urgente'
WHERE id_pub_jsonb = 3;

-- JB-UPD-3: Actualizar campo anidado con jsonb_set
UPDATE publicaciones_jsonb
SET metadatos_b = jsonb_set(
    metadatos_b,
    '{ubicacion}',
    '"Sala de Reuniones B204"'::JSONB,
    true   -- crear si no existe
)
WHERE id_pub_jsonb = 3;

-- JB-UPD-4: Incrementar likes usando jsonb_set + cast
UPDATE publicaciones_jsonb
SET metadatos_b = jsonb_set(
    metadatos_b,
    '{likes}',
    to_jsonb((metadatos_b->>'likes')::INT + 5)
)
WHERE tipo_contenido = 'texto'
  AND eliminada = FALSE;

-- JB-UPD-5: Agregar campo 'revisado' en sensores en alerta
UPDATE sensores_jsonb
SET lectura_b = lectura_b || '{"revisado":false, "requiere_accion":true}'::JSONB
WHERE (lectura_b->>'alerta')::BOOLEAN = TRUE;

-- ============================================================
-- SECCIÓN 4 – DELETE con condiciones JSONB
-- ============================================================

-- JB-DEL-1: Eliminar publicaciones sin vistas (campo JSONB)
DELETE FROM publicaciones_jsonb
WHERE (metadatos_b->>'vistas')::INT = 0
  AND eliminada = FALSE;

-- JB-DEL-2: Borrar lecturas de sensores revisadas y antiguas
DELETE FROM sensores_jsonb
WHERE (lectura_b->>'revisado')::BOOLEAN = TRUE
  AND creado_en < NOW() - INTERVAL '30 days';

-- JB-DEL-3: Baja lógica — marcar como eliminada publicaciones sin hashtags
UPDATE publicaciones_jsonb
SET eliminada = TRUE
WHERE NOT (metadatos_b ? 'hashtags')
   OR metadatos_b->'hashtags' = '[]'::JSONB;

-- ============================================================
-- VERIFICACIÓN CON EXPLAIN ANALYZE (rendimiento JSONB)
-- ============================================================
EXPLAIN ANALYZE
SELECT *
FROM publicaciones_jsonb
WHERE metadatos_b @> '{"hashtags":["#Pascualina"]}'::JSONB
  AND eliminada = FALSE;

-- ============================================================
-- FIN SCRIPT 04 - OPERACIONES DML JSONB
-- ============================================================

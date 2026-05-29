-- ============================================================
-- RED SOCIAL UNIVERSITARIA PASCUALINA
-- TAREA 6 - SCRIPT 06: BIG DATA E IoT
-- Ingesta masiva · EXPLAIN ANALYZE · Optimización de rendimiento
-- ============================================================
-- Objetivo: simular escenarios de Big Data e IoT:
--   1. Ingesta masiva de publicaciones (100k filas)
--   2. Ingesta de lecturas de sensores IoT (50k filas)
--   3. Medición de rendimiento antes/después de índices
--   4. Análisis con EXPLAIN ANALYZE
--   5. Particionamiento para Big Data
-- ============================================================

-- ============================================================
-- FASE 1: TABLAS OPTIMIZADAS PARA Big Data e IoT
-- ============================================================

-- 1a. Tabla de publicaciones para Big Data (JSONB + partición por mes)
CREATE TABLE IF NOT EXISTS pub_bigdata (
    id_pub         BIGSERIAL,
    id_autor       INT           NOT NULL,
    tipo_contenido VARCHAR(30)   NOT NULL DEFAULT 'texto',
    texto          TEXT,
    metadatos      JSONB,
    fecha          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    eliminada      BOOLEAN       NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_pub, fecha)
) PARTITION BY RANGE (fecha);

-- Particiones mensuales (2024-2025)
CREATE TABLE IF NOT EXISTS pub_bigdata_2024_q3
    PARTITION OF pub_bigdata
    FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');

CREATE TABLE IF NOT EXISTS pub_bigdata_2024_q4
    PARTITION OF pub_bigdata
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');

CREATE TABLE IF NOT EXISTS pub_bigdata_2025_q1
    PARTITION OF pub_bigdata
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');

CREATE TABLE IF NOT EXISTS pub_bigdata_2025_q2
    PARTITION OF pub_bigdata
    FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');

CREATE TABLE IF NOT EXISTS pub_bigdata_2025_q3
    PARTITION OF pub_bigdata
    FOR VALUES FROM ('2025-07-01') TO ('2025-10-01');

-- Índices sobre la tabla particionada
CREATE INDEX IF NOT EXISTS idx_pub_bd_autor
    ON pub_bigdata (id_autor);

CREATE INDEX IF NOT EXISTS idx_pub_bd_fecha
    ON pub_bigdata (fecha DESC);

CREATE INDEX IF NOT EXISTS idx_pub_bd_meta_gin
    ON pub_bigdata USING GIN (metadatos);

-- 1b. Tabla de lecturas IoT (time-series, particionada por día)
CREATE TABLE IF NOT EXISTS iot_lecturas (
    id_lectura     BIGSERIAL,
    sensor_id      VARCHAR(20)   NOT NULL,
    tipo_sensor    VARCHAR(50)   NOT NULL,
    ubicacion      VARCHAR(100)  NOT NULL,
    lectura        JSONB         NOT NULL,
    procesada      BOOLEAN       NOT NULL DEFAULT FALSE,
    ts             TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id_lectura, ts)
) PARTITION BY RANGE (ts);

-- Particiones para sept 2025 (ejemplo campus)
CREATE TABLE IF NOT EXISTS iot_lecturas_sep2025
    PARTITION OF iot_lecturas
    FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

CREATE TABLE IF NOT EXISTS iot_lecturas_oct2025
    PARTITION OF iot_lecturas
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

CREATE TABLE IF NOT EXISTS iot_lecturas_nov2025
    PARTITION OF iot_lecturas
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

-- Índice GIN en lecturas IoT
CREATE INDEX IF NOT EXISTS idx_iot_gin_lectura
    ON iot_lecturas USING GIN (lectura);

CREATE INDEX IF NOT EXISTS idx_iot_sensor_ts
    ON iot_lecturas (sensor_id, ts DESC);

-- ============================================================
-- FASE 2: INGESTA MASIVA — PUBLICACIONES (100 000 filas)
-- ============================================================

-- Registrar tiempo de inicio
DO $$ BEGIN RAISE NOTICE 'Inicio ingesta publicaciones: %', NOW(); END $$;

DO $$
DECLARE
    i           INT;
    tipos       TEXT[] := ARRAY['texto','imagen','video','enlace','evento'];
    hashtags    TEXT[] := ARRAY[
        '#Pascualina','#Campus','#Ingenieria','#Sistemas','#Ciencias',
        '#Bienestar','#IA','#Data','#EstudioGrupal','#TFG'
    ];
    v_likes     INT;
    v_vistas    INT;
    v_tipo      TEXT;
    v_tag1      TEXT;
    v_tag2      TEXT;
    v_fecha     TIMESTAMPTZ;
BEGIN
    FOR i IN 1..100000 LOOP
        v_likes  := (RANDOM() * 500)::INT;
        v_vistas := v_likes * (2 + (RANDOM() * 10)::INT);
        v_tipo   := tipos[1 + (RANDOM() * 4)::INT];
        v_tag1   := hashtags[1 + (RANDOM() * 9)::INT];
        v_tag2   := hashtags[1 + (RANDOM() * 9)::INT];
        v_fecha  := NOW() - (RANDOM() * INTERVAL '365 days');

        INSERT INTO pub_bigdata (id_autor, tipo_contenido, texto, metadatos, fecha)
        VALUES (
            1 + (RANDOM() * 9)::INT,   -- autores 1-10
            v_tipo,
            'Publicación de prueba BigData #' || i,
            jsonb_build_object(
                'likes',        v_likes,
                'comentarios',  (RANDOM() * 100)::INT,
                'compartidos',  (RANDOM() * 50)::INT,
                'vistas',       v_vistas,
                'hashtags',     jsonb_build_array(v_tag1, v_tag2),
                'dispositivo',  CASE WHEN RANDOM() > 0.5 THEN 'móvil' ELSE 'laptop' END,
                'batch',        CEIL(i::NUMERIC / 10000)
            ),
            v_fecha
        );
    END LOOP;
    RAISE NOTICE 'Fin ingesta publicaciones: %', NOW();
END;
$$;

SELECT COUNT(*) AS total_pub_bigdata FROM pub_bigdata;

-- ============================================================
-- FASE 3: INGESTA MASIVA — LECTURAS IoT (50 000 filas)
-- ============================================================

DO $$ BEGIN RAISE NOTICE 'Inicio ingesta IoT: %', NOW(); END $$;

DO $$
DECLARE
    i           INT;
    sensores    TEXT[] := ARRAY[
        'OCP-A01','OCP-A02','OCP-B01','OCP-B02',
        'TMP-301','TMP-302','HUM-CAN','RDO-BIB','CO2-LAB'
    ];
    tipos       TEXT[] := ARRAY[
        'ocupacion','ocupacion','ocupacion','ocupacion',
        'temperatura','temperatura','humedad','ruido','co2'
    ];
    ubicaciones TEXT[] := ARRAY[
        'Aula-101','Aula-102','Aula-201','Aula-202',
        'Lab-301','Lab-302','Cancha','Biblioteca','Lab-Quimica'
    ];
    v_valor     NUMERIC;
    v_alerta    BOOLEAN;
    v_idx       INT;
    v_ts        TIMESTAMPTZ;
BEGIN
    FOR i IN 1..50000 LOOP
        v_idx   := 1 + (RANDOM() * 8)::INT;
        v_valor := ROUND((RANDOM() * 100)::NUMERIC, 2);
        v_alerta:= v_valor > 80;
        v_ts    := NOW() - (RANDOM() * INTERVAL '90 days');

        INSERT INTO iot_lecturas (sensor_id, tipo_sensor, ubicacion, lectura, ts)
        VALUES (
            sensores[v_idx],
            tipos[v_idx],
            ubicaciones[v_idx],
            jsonb_build_object(
                'valor',         v_valor,
                'unidad',        CASE tipos[v_idx]
                                    WHEN 'temperatura' THEN '°C'
                                    WHEN 'humedad'     THEN '%'
                                    WHEN 'ruido'       THEN 'dB'
                                    WHEN 'co2'         THEN 'ppm'
                                    ELSE 'personas' END,
                'alerta',        v_alerta,
                'sensor_id',     sensores[v_idx],
                'procesada',     FALSE,
                'bateria_pct',   (50 + (RANDOM() * 50)::INT),
                'seq',           i
            ),
            v_ts
        );
    END LOOP;
    RAISE NOTICE 'Fin ingesta IoT: %', NOW();
END;
$$;

SELECT COUNT(*) AS total_iot FROM iot_lecturas;

-- ============================================================
-- FASE 4: EXPLAIN ANALYZE — Medir rendimiento
-- ============================================================

-- 4a. SIN índice GIN: búsqueda textual lenta (Seq Scan)
--     Temporal: desactivar índice para comparar
SET enable_indexscan  = OFF;
SET enable_bitmapscan = OFF;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT COUNT(*)
FROM pub_bigdata
WHERE metadatos @> '{"hashtags":["#Pascualina"]}'::JSONB
  AND eliminada = FALSE;

-- Restaurar uso de índices
SET enable_indexscan  = ON;
SET enable_bitmapscan = ON;

-- 4b. CON índice GIN: Bitmap Index Scan (mucho más rápido)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT COUNT(*)
FROM pub_bigdata
WHERE metadatos @> '{"hashtags":["#Pascualina"]}'::JSONB
  AND eliminada = FALSE;

-- 4c. Consulta con pruning de particiones (solo lee partición relevante)
EXPLAIN (ANALYZE, FORMAT TEXT)
SELECT COUNT(*)
FROM pub_bigdata
WHERE fecha BETWEEN '2025-04-01' AND '2025-07-01';

-- 4d. Top 10 publicaciones más virales (vistas) — BigData
EXPLAIN (ANALYZE, FORMAT TEXT)
SELECT
    id_pub,
    id_autor,
    tipo_contenido,
    (metadatos->>'vistas')::INT   AS vistas,
    (metadatos->>'likes')::INT    AS likes
FROM pub_bigdata
WHERE eliminada = FALSE
ORDER BY (metadatos->>'vistas')::INT DESC
LIMIT 10;

-- 4e. Lecturas IoT en alerta por sensor — últimas 24 h
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    sensor_id,
    tipo_sensor,
    ubicacion,
    (lectura->>'valor')::NUMERIC    AS valor,
    lectura->>'unidad'              AS unidad,
    ts
FROM iot_lecturas
WHERE (lectura->>'alerta')::BOOLEAN = TRUE
  AND ts >= NOW() - INTERVAL '24 hours'
ORDER BY ts DESC;

-- ============================================================
-- FASE 5: CONSULTAS ANALÍTICAS Big Data
-- ============================================================

-- 5a. Publicaciones por mes y tipo (partición eficiente)
SELECT
    DATE_TRUNC('month', fecha)         AS mes,
    tipo_contenido,
    COUNT(*)                           AS total,
    SUM((metadatos->>'likes')::INT)    AS likes_totales,
    AVG((metadatos->>'vistas')::INT)   AS vistas_promedio
FROM pub_bigdata
WHERE fecha >= '2025-01-01'
  AND eliminada = FALSE
GROUP BY DATE_TRUNC('month', fecha), tipo_contenido
ORDER BY mes DESC, total DESC;

-- 5b. Hora pico de actividad IoT por tipo de sensor
SELECT
    tipo_sensor,
    EXTRACT(HOUR FROM ts)              AS hora,
    COUNT(*)                           AS lecturas,
    AVG((lectura->>'valor')::NUMERIC)  AS promedio,
    COUNT(*) FILTER (
        WHERE (lectura->>'alerta')::BOOLEAN = TRUE
    )                                  AS alertas
FROM iot_lecturas
GROUP BY tipo_sensor, EXTRACT(HOUR FROM ts)
ORDER BY tipo_sensor, alertas DESC;

-- 5c. Sensor con más alertas por ubicación
SELECT
    ubicacion,
    sensor_id,
    tipo_sensor,
    COUNT(*) FILTER (
        WHERE (lectura->>'alerta')::BOOLEAN = TRUE
    )                                  AS total_alertas,
    COUNT(*)                           AS total_lecturas,
    ROUND(
        COUNT(*) FILTER (
            WHERE (lectura->>'alerta')::BOOLEAN = TRUE
        )::NUMERIC / COUNT(*) * 100, 2
    )                                  AS pct_alertas
FROM iot_lecturas
GROUP BY ubicacion, sensor_id, tipo_sensor
HAVING COUNT(*) FILTER (
    WHERE (lectura->>'alerta')::BOOLEAN = TRUE
) > 0
ORDER BY pct_alertas DESC
LIMIT 10;

-- 5d. Correlación likes-vistas en publicaciones Big Data
SELECT
    tipo_contenido,
    ROUND(CORR(
        (metadatos->>'likes')::NUMERIC,
        (metadatos->>'vistas')::NUMERIC
    )::NUMERIC, 4)                     AS correlacion_likes_vistas,
    COUNT(*)                           AS muestra
FROM pub_bigdata
WHERE eliminada = FALSE
  AND (metadatos->>'likes')::INT > 0
GROUP BY tipo_contenido
ORDER BY correlacion_likes_vistas DESC;

-- ============================================================
-- FASE 6: MANTENIMIENTO Y OPTIMIZACIÓN
-- ============================================================

-- Actualizar estadísticas del planificador
ANALYZE pub_bigdata;
ANALYZE iot_lecturas;

-- Ver tamaño de tablas particionadas e índices
SELECT
    relname                                        AS tabla_o_indice,
    pg_size_pretty(pg_total_relation_size(oid))   AS tamanio_total,
    pg_size_pretty(pg_relation_size(oid))         AS tamanio_datos,
    pg_size_pretty(
        pg_total_relation_size(oid)
        - pg_relation_size(oid)
    )                                              AS tamanio_indices
FROM pg_class
WHERE relname LIKE 'pub_bigdata%'
   OR relname LIKE 'iot_lecturas%'
ORDER BY pg_total_relation_size(oid) DESC;

-- Ver índices creados y su tamaño
SELECT
    indexname,
    pg_size_pretty(pg_relation_size(indexname::REGCLASS)) AS tamanio_indice
FROM pg_indexes
WHERE tablename IN ('pub_bigdata','iot_lecturas')
ORDER BY pg_relation_size(indexname::REGCLASS) DESC;

-- ============================================================
-- FASE 7: PROCESO DE MARCADO BATCH (DML masivo IoT)
-- ============================================================

-- Marcar como procesadas las lecturas más antiguas de 1 hora
UPDATE iot_lecturas
SET procesada = TRUE,
    lectura   = lectura || '{"procesada":true}'::JSONB
WHERE procesada = FALSE
  AND ts < NOW() - INTERVAL '1 hour';

-- Contar procesadas vs pendientes
SELECT
    procesada,
    COUNT(*)  AS total
FROM iot_lecturas
GROUP BY procesada;

-- ============================================================
-- FIN SCRIPT 06 - BIG DATA e IoT
-- ============================================================

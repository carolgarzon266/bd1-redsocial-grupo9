-- ============================================================
-- RED SOCIAL UNIVERSITARIA PASCUALINA
-- TAREA 6 - SCRIPT 05: COMPARATIVA JSON vs JSONB
-- Rendimiento, diferencias de almacenamiento y operadores
-- ============================================================
-- Objetivo: demostrar cuándo y por qué usar JSONB sobre JSON
-- Método: mismos datos insertados en ambos tipos, luego
--         comparación de planes de ejecución con EXPLAIN ANALYZE
-- ============================================================

-- ============================================================
-- PASO 1: Crear tablas gemelas (JSON vs JSONB)
-- ============================================================

-- Tabla con tipo JSON (texto sin procesar)
CREATE TABLE IF NOT EXISTS comp_json (
    id        SERIAL PRIMARY KEY,
    payload   JSON,
    creado_en TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla con tipo JSONB (binario, deduplicado, indexable)
CREATE TABLE IF NOT EXISTS comp_jsonb (
    id        SERIAL PRIMARY KEY,
    payload   JSONB,
    creado_en TIMESTAMPTZ DEFAULT NOW()
);

-- Índice GIN solo en la tabla JSONB
CREATE INDEX IF NOT EXISTS idx_gin_comp_jsonb
    ON comp_jsonb USING GIN (payload);

-- ============================================================
-- PASO 2: Inserción masiva de datos de prueba (1 000 filas)
-- ============================================================

-- Función auxiliar para generar JSON de sensores aleatorios
-- Inserta en AMBAS tablas simultáneamente
DO $$
DECLARE
    i         INT;
    tipos     TEXT[] := ARRAY['ocupacion','temperatura','humedad','ruido','co2'];
    aulas     TEXT[] := ARRAY['Aula-101','Aula-202','Lab-301','Bib-A','Auditorio'];
    v_valor   NUMERIC;
    v_alerta  BOOLEAN;
    v_payload TEXT;
BEGIN
    FOR i IN 1..1000 LOOP
        v_valor  := ROUND((RANDOM() * 100)::NUMERIC, 2);
        v_alerta := v_valor > 80;
        v_payload := format(
            '{"sensor_id":"SEN-%s","tipo":"%s","ubicacion":"%s",'
            '"valor":%s,"unidad":"unidad","alerta":%s,'
            '"timestamp":"%s","batch":%s}',
            LPAD(i::TEXT, 5, '0'),
            tipos[1 + (RANDOM()*4)::INT],
            aulas[1 + (RANDOM()*4)::INT],
            v_valor,
            v_alerta,
            NOW() - (RANDOM() * INTERVAL '30 days'),
            CEIL(i::NUMERIC / 100)
        );

        INSERT INTO comp_json  (payload) VALUES (v_payload::JSON);
        INSERT INTO comp_jsonb (payload) VALUES (v_payload::JSONB);
    END LOOP;
END;
$$;

-- Verificar conteos
SELECT 'comp_json'  AS tabla, COUNT(*) AS filas FROM comp_json
UNION ALL
SELECT 'comp_jsonb', COUNT(*)              FROM comp_jsonb;

-- ============================================================
-- PASO 3: Comparativa de TAMAÑO en disco
-- ============================================================
SELECT
    'comp_json'                           AS tabla,
    pg_size_pretty(pg_total_relation_size('comp_json'))  AS tamanio_total,
    pg_size_pretty(pg_relation_size('comp_json'))        AS tamanio_datos
UNION ALL
SELECT
    'comp_jsonb',
    pg_size_pretty(pg_total_relation_size('comp_jsonb')),
    pg_size_pretty(pg_relation_size('comp_jsonb'));

-- ============================================================
-- PASO 4: Comparativa de RENDIMIENTO con EXPLAIN ANALYZE
-- ============================================================

-- 4a. Filtro en JSON (sin índice — Seq Scan obligatorio)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT id, payload->>'sensor_id' AS sensor, payload->>'valor' AS valor
FROM comp_json
WHERE payload->>'tipo' = 'ocupacion'
  AND (payload->>'alerta')::BOOLEAN = TRUE;

-- 4b. Mismo filtro en JSONB (puede usar índice GIN)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT id, payload->>'sensor_id' AS sensor, payload->>'valor' AS valor
FROM comp_jsonb
WHERE payload @> '{"tipo":"ocupacion","alerta":true}'::JSONB;

-- 4c. Búsqueda de clave existente: JSON
EXPLAIN (ANALYZE, FORMAT TEXT)
SELECT COUNT(*) FROM comp_json
WHERE payload->>'sensor_id' IS NOT NULL;

-- 4d. Búsqueda de clave existente: JSONB (operador ?)
EXPLAIN (ANALYZE, FORMAT TEXT)
SELECT COUNT(*) FROM comp_jsonb
WHERE payload ? 'sensor_id';

-- ============================================================
-- PASO 5: Operadores exclusivos de JSONB
-- ============================================================

-- 5a. Containment @> (no disponible en JSON)
SELECT COUNT(*)
FROM comp_jsonb
WHERE payload @> '{"alerta":true}'::JSONB;

-- 5b. Key existence ? (no disponible en JSON)
SELECT COUNT(*)
FROM comp_jsonb
WHERE payload ? 'batch';

-- 5c. Any key ?| (no disponible en JSON)
SELECT COUNT(*)
FROM comp_jsonb
WHERE payload ?| ARRAY['zona','pct_ocupacion'];

-- 5d. JSON Path Query (PostgreSQL 12+, solo JSONB)
SELECT id, jsonb_path_query_first(payload, '$.valor') AS val
FROM comp_jsonb
WHERE jsonb_path_exists(payload, '$.valor ? (@ > 90)')
ORDER BY val DESC
LIMIT 10;

-- ============================================================
-- PASO 6: Operadores comunes disponibles en AMBOS tipos
-- ============================================================

-- 6a. Extracción de campo con ->
SELECT id, payload->'sensor_id' AS sensor_json_obj FROM comp_json  LIMIT 3;
SELECT id, payload->'sensor_id' AS sensor_jsonb_obj FROM comp_jsonb LIMIT 3;

-- 6b. Extracción como texto con ->>
SELECT id, payload->>'ubicacion' AS ubi FROM comp_json  LIMIT 3;
SELECT id, payload->>'ubicacion' AS ubi FROM comp_jsonb LIMIT 3;

-- 6c. Acceso por ruta #>> (solo comparativo)
SELECT id, payload#>>'{sensor_id}' AS sid FROM comp_json  LIMIT 3;
SELECT id, payload#>>'{sensor_id}' AS sid FROM comp_jsonb LIMIT 3;

-- ============================================================
-- PASO 7: Funciones de inspección JSONB
-- ============================================================

-- 7a. Tipo de estructura raíz
SELECT DISTINCT jsonb_typeof(payload) FROM comp_jsonb;

-- 7b. Claves del primer registro
SELECT jsonb_object_keys(payload) AS clave
FROM comp_jsonb
WHERE id = 1;

-- 7c. jsonb_pretty para lectura legible
SELECT jsonb_pretty(payload)
FROM comp_jsonb
WHERE id = 1;

-- 7d. Número de claves
SELECT id, jsonb_array_length(CASE
    WHEN jsonb_typeof(payload) = 'array' THEN payload
    ELSE NULL END) AS largo
FROM comp_jsonb
LIMIT 5;

-- ============================================================
-- PASO 8: Resumen comparativo (tabla resumen de resultados)
-- ============================================================
/*
  CARACTERÍSTICA          | JSON                | JSONB
  ──────────────────────────────────────────────────────────────
  Almacenamiento          | Texto original      | Binario compacto
  Orden de claves         | Preservado          | No preservado
  Claves duplicadas       | Permitidas          | Descartadas
  Índice GIN              | ✗ No soportado      | ✓ Soportado
  Operador @>             | ✗                   | ✓
  Operador ?  ?| ?&       | ✗                   | ✓
  JSON Path Query         | ✗                   | ✓
  Velocidad de escritura  | Más rápida          | Ligeramente más lenta
  Velocidad de lectura    | Secuencial          | Indexada (hasta 100x)
  Caso de uso ideal       | Logs, auditoría,    | Búsquedas, filtros,
                          | datos en tránsito   | analítica, IoT
*/

-- ============================================================
-- LIMPIEZA OPCIONAL (comentar si se desea conservar los datos)
-- ============================================================
-- DROP TABLE IF EXISTS comp_json;
-- DROP TABLE IF EXISTS comp_jsonb;

-- ============================================================
-- FIN SCRIPT 05 - COMPARATIVA JSON vs JSONB
-- ============================================================

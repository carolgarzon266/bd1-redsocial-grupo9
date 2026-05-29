-- ============================================================
-- RED SOCIAL UNIVERSITARIA PASCUALINA
-- TAREA 6 - SCRIPT 02: AGRUPAMIENTOS Y FUNCIONES DE AGREGACIÓN
-- WHERE · GROUP BY · HAVING · funciones de ventana
-- ============================================================

-- -------------------------------------------------------
-- A1. Total de publicaciones por tipo de contenido
-- (solo tipos con más de 2 publicaciones activas)
-- -------------------------------------------------------
SELECT
    p.tipo_contenido,
    COUNT(*)                                AS total_publicaciones,
    AVG((p.metadatos->>'likes')::INT)       AS promedio_likes,
    MAX((p.metadatos->>'likes')::INT)       AS max_likes,
    SUM((p.metadatos->>'comentarios')::INT) AS total_comentarios,
    SUM((p.metadatos->>'vistas')::INT)      AS total_vistas
FROM publicaciones p
WHERE p.eliminada = FALSE
GROUP BY p.tipo_contenido
HAVING COUNT(*) > 2
ORDER BY total_publicaciones DESC;

-- -------------------------------------------------------
-- A2. Usuarios con más seguidores por programa académico
-- (solo programas con al menos 2 usuarios)
-- -------------------------------------------------------
SELECT
    u.programa_academico,
    COUNT(DISTINCT u.id_usuario)            AS cantidad_usuarios,
    MAX(sub.seguidores)                     AS max_seguidores_programa,
    AVG(sub.seguidores)                     AS promedio_seguidores,
    SUM(sub.seguidores)                     AS total_seguidores_programa
FROM usuarios u
JOIN (
    SELECT s.id_seguido AS id_usuario, COUNT(*) AS seguidores
    FROM seguidores s
    GROUP BY s.id_seguido
) sub ON sub.id_usuario = u.id_usuario
WHERE u.activo = TRUE
GROUP BY u.programa_academico
HAVING COUNT(DISTINCT u.id_usuario) >= 2
ORDER BY promedio_seguidores DESC;

-- -------------------------------------------------------
-- A3. Eventos por mes: inscripciones y ocupación IoT
-- -------------------------------------------------------
SELECT
    DATE_TRUNC('month', e.fecha_inicio)         AS mes_evento,
    COUNT(DISTINCT e.id_evento)                 AS total_eventos,
    SUM(e.cupo_maximo)                          AS cupos_totales,
    COUNT(DISTINCT pe.id_usuario)               AS total_inscritos,
    ROUND(
        COUNT(DISTINCT pe.id_usuario)::NUMERIC
        / NULLIF(SUM(e.cupo_maximo), 0) * 100, 2
    )                                            AS pct_ocupacion,
    AVG((s.lectura->>'valor')::NUMERIC)         AS promedio_sensor_ocupacion
FROM eventos e
LEFT JOIN participantes_evento pe ON pe.id_evento  = e.id_evento
LEFT JOIN sensores_iot s          ON s.id_evento   = e.id_evento
                                 AND s.tipo_sensor = 'ocupacion'
WHERE e.fecha_inicio >= NOW() - INTERVAL '1 year'
GROUP BY DATE_TRUNC('month', e.fecha_inicio)
ORDER BY mes_evento ASC;

-- -------------------------------------------------------
-- A4. Top grupos por volumen de publicaciones (30 días)
-- Muestra grupos con al menos 1 publicación reciente
-- -------------------------------------------------------
SELECT
    g.nombre_grupo,
    g.datos_grupo->>'categoria'                  AS categoria,
    COUNT(DISTINCT mg.id_usuario)               AS miembros,
    COUNT(DISTINCT p.id_publicacion)            AS publicaciones_mes,
    SUM((p.metadatos->>'likes')::INT)           AS likes_totales,
    ROUND(
        SUM((p.metadatos->>'likes')::INT)::NUMERIC
        / NULLIF(COUNT(DISTINCT p.id_publicacion), 0), 2
    )                                            AS likes_por_publicacion
FROM grupos g
JOIN miembros_grupo mg   ON mg.id_grupo = g.id_grupo
LEFT JOIN publicaciones p ON p.id_grupo  = g.id_grupo
    AND p.fecha_publicacion >= NOW() - INTERVAL '30 days'
    AND p.eliminada = FALSE
WHERE g.activo = TRUE
GROUP BY g.id_grupo, g.nombre_grupo, g.datos_grupo->>'categoria'
HAVING COUNT(DISTINCT p.id_publicacion) >= 1
ORDER BY publicaciones_mes DESC;

-- -------------------------------------------------------
-- A5. Actividad diaria de usuarios (logs) – últimos 30 días
-- Identifica picos de uso por día y por acción
-- -------------------------------------------------------
SELECT
    DATE_TRUNC('day', l.fecha_accion)           AS dia,
    l.accion,
    COUNT(*)                                    AS total_acciones,
    COUNT(DISTINCT l.id_usuario)                AS usuarios_unicos,
    AVG((l.detalle_log->>'duracion_seg')::NUMERIC) AS duracion_media_seg
FROM logs_actividad l
WHERE l.fecha_accion >= NOW() - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', l.fecha_accion), l.accion
HAVING COUNT(*) > 1
ORDER BY dia DESC, total_acciones DESC;

-- -------------------------------------------------------
-- A6. Semestres con mayor participación en eventos
-- -------------------------------------------------------
SELECT
    u.semestre_actual,
    COUNT(DISTINCT pe.id_evento)                AS eventos_asistidos,
    COUNT(DISTINCT pe.id_usuario)               AS participantes,
    ROUND(
        COUNT(DISTINCT pe.id_evento)::NUMERIC
        / NULLIF(COUNT(DISTINCT pe.id_usuario), 0), 2
    )                                            AS eventos_por_persona
FROM participantes_evento pe
JOIN usuarios u ON u.id_usuario = pe.id_usuario
GROUP BY u.semestre_actual
HAVING COUNT(DISTINCT pe.id_evento) >= 1
ORDER BY eventos_por_persona DESC;

-- -------------------------------------------------------
-- A7. Comparativa JSON vs JSONB: lecturas IoT por tipo sensor
-- Agrupadas por hora para detección de picos
-- -------------------------------------------------------
SELECT
    s.tipo_sensor,
    DATE_TRUNC('hour', (s.lectura->>'timestamp')::TIMESTAMPTZ) AS hora,
    COUNT(*)                                                    AS lecturas,
    AVG((s.lectura->>'valor')::NUMERIC)                        AS promedio_valor,
    MIN((s.lectura->>'valor')::NUMERIC)                        AS min_valor,
    MAX((s.lectura->>'valor')::NUMERIC)                        AS max_valor,
    COUNT(*) FILTER (WHERE s.lectura->>'alerta' = 'true')      AS alertas
FROM sensores_iot s
WHERE (s.lectura->>'timestamp')::TIMESTAMPTZ
          >= NOW() - INTERVAL '7 days'
GROUP BY s.tipo_sensor, DATE_TRUNC('hour', (s.lectura->>'timestamp')::TIMESTAMPTZ)
HAVING COUNT(*) > 0
ORDER BY hora DESC, tipo_sensor;

-- -------------------------------------------------------
-- A8. Usuarios más activos: publicaciones + likes + eventos
-- Ranking compuesto (HAVING filtra usuarios con actividad real)
-- -------------------------------------------------------
SELECT
    u.id_usuario,
    u.nombre_completo,
    u.programa_academico,
    COUNT(DISTINCT p.id_publicacion)             AS publicaciones,
    COALESCE(SUM((p.metadatos->>'likes')::INT),0) AS likes_recibidos,
    COUNT(DISTINCT pe.id_evento)                 AS eventos_asistidos,
    COUNT(DISTINCT mg.id_grupo)                  AS grupos_miembro,
    -- Índice de actividad ponderado
    (
        COUNT(DISTINCT p.id_publicacion) * 3
        + COALESCE(SUM((p.metadatos->>'likes')::INT), 0) * 0.1
        + COUNT(DISTINCT pe.id_evento) * 2
        + COUNT(DISTINCT mg.id_grupo)
    )                                             AS indice_actividad
FROM usuarios u
LEFT JOIN publicaciones p     ON p.id_autor  = u.id_usuario AND p.eliminada = FALSE
LEFT JOIN participantes_evento pe ON pe.id_usuario = u.id_usuario
LEFT JOIN miembros_grupo mg   ON mg.id_usuario = u.id_usuario
WHERE u.activo = TRUE
GROUP BY u.id_usuario, u.nombre_completo, u.programa_academico
HAVING (
    COUNT(DISTINCT p.id_publicacion)
    + COUNT(DISTINCT pe.id_evento)
    + COUNT(DISTINCT mg.id_grupo)
) > 0
ORDER BY indice_actividad DESC
LIMIT 10;

-- -------------------------------------------------------
-- A9. Uso de hashtags más populares (campo JSON)
-- -------------------------------------------------------
SELECT
    hashtag_norm                                AS hashtag,
    COUNT(*)                                    AS usos,
    SUM((p.metadatos->>'likes')::INT)           AS likes_totales,
    AVG((p.metadatos->>'likes')::INT)           AS likes_promedio
FROM publicaciones p,
LATERAL (
    SELECT LOWER(TRIM(elem)) AS hashtag_norm
    FROM jsonb_array_elements_text(
        CASE
            WHEN jsonb_typeof(p.metadatos->'hashtags') = 'array'
                THEN p.metadatos->'hashtags'
            ELSE '[]'::jsonb
        END
    ) AS elem
) h
WHERE p.eliminada = FALSE
GROUP BY hashtag_norm
HAVING COUNT(*) >= 1
ORDER BY usos DESC
LIMIT 15;

-- -------------------------------------------------------
-- A10. Función ventana: ranking de publicaciones por autor
-- -------------------------------------------------------
SELECT
    u.nombre_completo,
    p.tipo_contenido,
    p.fecha_publicacion,
    (p.metadatos->>'likes')::INT                AS likes,
    RANK() OVER (
        PARTITION BY p.id_autor
        ORDER BY (p.metadatos->>'likes')::INT DESC
    )                                            AS rank_en_autor,
    SUM((p.metadatos->>'likes')::INT) OVER (
        PARTITION BY p.id_autor
    )                                            AS likes_totales_autor
FROM publicaciones p
JOIN usuarios u ON u.id_usuario = p.id_autor
WHERE p.eliminada = FALSE
ORDER BY u.nombre_completo, rank_en_autor;

-- ============================================================
-- FIN SCRIPT 02 - AGRUPAMIENTOS Y FUNCIONES DE AGREGACIÓN
-- ============================================================

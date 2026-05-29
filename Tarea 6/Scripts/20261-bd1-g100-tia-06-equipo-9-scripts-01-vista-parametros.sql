-- ============================================================
-- RED SOCIAL UNIVERSITARIA PASCUALINA
-- TAREA 6 - SCRIPT 01: VISTAS Y CONSULTAS PARAMETRIZADAS
-- PREPARE / EXECUTE sobre VIEWS
-- ============================================================
-- PRERREQUISITO: ejecutar DDL y DML de inserciones previas
-- Base de datos: pascualina_db
-- ============================================================

-- -------------------------------------------------------
-- 1. VISTA: Perfil público de usuarios activos
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_perfil_usuario AS
SELECT
    u.id_usuario,
    u.nombre_completo,
    u.correo_institucional,
    u.programa_academico,
    u.semestre_actual,
    u.datos_perfil->>'ciudad_origen'          AS ciudad_origen,
    u.datos_perfil->>'intereses'              AS intereses,
    u.datos_perfil->'redes_sociales'->>'instagram' AS instagram,
    COUNT(DISTINCT s.id_seguidor)             AS total_seguidores,
    COUNT(DISTINCT p.id_publicacion)          AS total_publicaciones
FROM usuarios u
LEFT JOIN seguidores s  ON s.id_seguido   = u.id_usuario
LEFT JOIN publicaciones p ON p.id_autor   = u.id_usuario
WHERE u.activo = TRUE
GROUP BY
    u.id_usuario, u.nombre_completo, u.correo_institucional,
    u.programa_academico, u.semestre_actual,
    u.datos_perfil->>'ciudad_origen',
    u.datos_perfil->>'intereses',
    u.datos_perfil->'redes_sociales'->>'instagram';

-- -------------------------------------------------------
-- 2. VISTA: Publicaciones con métricas de interacción
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_publicaciones_metricas AS
SELECT
    p.id_publicacion,
    p.id_autor,
    u.nombre_completo                              AS autor,
    p.tipo_contenido,
    p.texto_publicacion,
    p.metadatos->>'hashtags'                       AS hashtags,
    p.metadatos->>'ubicacion'                      AS ubicacion,
    (p.metadatos->>'likes')::INT                   AS likes,
    (p.metadatos->>'comentarios')::INT             AS comentarios,
    (p.metadatos->>'compartidos')::INT             AS compartidos,
    (p.metadatos->>'vistas')::INT                  AS vistas,
    p.fecha_publicacion
FROM publicaciones p
JOIN usuarios u ON u.id_usuario = p.id_autor
WHERE p.eliminada = FALSE;

-- -------------------------------------------------------
-- 3. VISTA: Eventos con ocupación y sensores IoT
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_eventos_iot AS
SELECT
    e.id_evento,
    e.nombre_evento,
    e.descripcion,
    e.fecha_inicio,
    e.fecha_fin,
    e.ubicacion,
    e.cupo_maximo,
    COUNT(DISTINCT pe.id_usuario)               AS inscritos,
    e.cupo_maximo - COUNT(DISTINCT pe.id_usuario) AS cupos_disponibles,
    AVG((s.lectura->>'valor')::NUMERIC)         AS promedio_ocupacion_sensor,
    MAX((s.lectura->>'valor')::NUMERIC)         AS pico_ocupacion_sensor,
    e.datos_evento->>'categoria'                AS categoria,
    e.datos_evento->>'modalidad'                AS modalidad
FROM eventos e
LEFT JOIN participantes_evento pe ON pe.id_evento = e.id_evento
LEFT JOIN sensores_iot s          ON s.id_evento  = e.id_evento
                                 AND s.tipo_sensor = 'ocupacion'
GROUP BY
    e.id_evento, e.nombre_evento, e.descripcion,
    e.fecha_inicio, e.fecha_fin, e.ubicacion,
    e.cupo_maximo,
    e.datos_evento->>'categoria',
    e.datos_evento->>'modalidad';

-- -------------------------------------------------------
-- 4. VISTA: Ranking de grupos por actividad
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_grupos_actividad AS
SELECT
    g.id_grupo,
    g.nombre_grupo,
    g.descripcion,
    g.datos_grupo->>'categoria'                AS categoria,
    g.datos_grupo->>'privacidad'               AS privacidad,
    COUNT(DISTINCT mg.id_usuario)              AS total_miembros,
    COUNT(DISTINCT p.id_publicacion)           AS publicaciones_30dias,
    MAX(p.fecha_publicacion)                   AS ultima_publicacion
FROM grupos g
LEFT JOIN miembros_grupo mg   ON mg.id_grupo = g.id_grupo
LEFT JOIN publicaciones p     ON p.id_grupo  = g.id_grupo
    AND p.fecha_publicacion >= NOW() - INTERVAL '30 days'
    AND p.eliminada = FALSE
WHERE g.activo = TRUE
GROUP BY
    g.id_grupo, g.nombre_grupo, g.descripcion,
    g.datos_grupo->>'categoria',
    g.datos_grupo->>'privacidad';

-- -------------------------------------------------------
-- 5. VISTA: Actividad IoT por aula/sensor últimas 24 h
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_sensores_recientes AS
SELECT
    s.id_sensor,
    s.ubicacion_sensor,
    s.tipo_sensor,
    s.lectura->>'valor'                        AS valor_lectura,
    s.lectura->>'unidad'                       AS unidad,
    (s.lectura->>'timestamp')::TIMESTAMPTZ    AS ts_lectura,
    s.lectura->>'alerta'                       AS alerta,
    s.id_evento
FROM sensores_iot s
WHERE (s.lectura->>'timestamp')::TIMESTAMPTZ
          >= NOW() - INTERVAL '24 hours'
ORDER BY ts_lectura DESC;

-- -------------------------------------------------------
-- 6. VISTA: Logs de actividad por usuario (últimos 7 días)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_logs_usuario AS
SELECT
    l.id_log,
    l.id_usuario,
    u.nombre_completo,
    l.accion,
    l.detalle_log->>'modulo'                   AS modulo,
    l.detalle_log->>'dispositivo'              AS dispositivo,
    l.detalle_log->>'ip'                       AS ip,
    l.detalle_log->>'duracion_seg'             AS duracion_seg,
    l.fecha_accion
FROM logs_actividad l
JOIN usuarios u ON u.id_usuario = l.id_usuario
WHERE l.fecha_accion >= NOW() - INTERVAL '7 days'
ORDER BY l.fecha_accion DESC;

-- ============================================================
-- CONSULTAS PARAMETRIZADAS CON PREPARE / EXECUTE
-- ============================================================

-- -------------------------------------------------------
-- P1. Buscar perfil de usuario por programa académico
-- -------------------------------------------------------
PREPARE buscar_por_programa(VARCHAR) AS
    SELECT *
    FROM vw_perfil_usuario
    WHERE programa_academico = $1
    ORDER BY total_seguidores DESC;

EXECUTE buscar_por_programa('Ingeniería de Sistemas');
EXECUTE buscar_por_programa('Administración de Empresas');

DEALLOCATE buscar_por_programa;

-- -------------------------------------------------------
-- P2. Publicaciones con más likes entre dos fechas
-- -------------------------------------------------------
PREPARE publicaciones_periodo(DATE, DATE, INT) AS
    SELECT *
    FROM vw_publicaciones_metricas
    WHERE fecha_publicacion BETWEEN $1 AND $2
      AND likes >= $3
    ORDER BY likes DESC;

EXECUTE publicaciones_periodo('2025-01-01', '2025-12-31', 10);
EXECUTE publicaciones_periodo('2024-06-01', '2024-12-31', 5);

DEALLOCATE publicaciones_periodo;

-- -------------------------------------------------------
-- P3. Eventos con cupos disponibles por categoría
-- -------------------------------------------------------
PREPARE eventos_con_cupo(VARCHAR, INT) AS
    SELECT *
    FROM vw_eventos_iot
    WHERE categoria   = $1
      AND cupos_disponibles >= $2
    ORDER BY fecha_inicio ASC;

EXECUTE eventos_con_cupo('académico', 1);
EXECUTE eventos_con_cupo('cultural', 0);

DEALLOCATE eventos_con_cupo;

-- -------------------------------------------------------
-- P4. Grupos más activos por categoría y mínimo miembros
-- -------------------------------------------------------
PREPARE grupos_activos(VARCHAR, INT) AS
    SELECT *
    FROM vw_grupos_actividad
    WHERE categoria     = $1
      AND total_miembros >= $2
    ORDER BY publicaciones_30dias DESC;

EXECUTE grupos_activos('estudio', 2);
EXECUTE grupos_activos('deporte', 1);

DEALLOCATE grupos_activos;

-- -------------------------------------------------------
-- P5. Alertas IoT por tipo de sensor
-- -------------------------------------------------------
PREPARE alertas_sensor(VARCHAR) AS
    SELECT *
    FROM vw_sensores_recientes
    WHERE tipo_sensor = $1
      AND alerta      = 'true'
    ORDER BY ts_lectura DESC;

EXECUTE alertas_sensor('ocupacion');
EXECUTE alertas_sensor('temperatura');

DEALLOCATE alertas_sensor;

-- -------------------------------------------------------
-- P6. Logs de usuario específico (id + acción)
-- -------------------------------------------------------
PREPARE logs_por_usuario(INT, VARCHAR) AS
    SELECT *
    FROM vw_logs_usuario
    WHERE id_usuario = $1
      AND accion     = $2
    ORDER BY fecha_accion DESC;

EXECUTE logs_por_usuario(1, 'login');
EXECUTE logs_por_usuario(2, 'publicar');

DEALLOCATE logs_por_usuario;

-- -------------------------------------------------------
-- P7. Usuarios sin publicaciones (inner join vs vista)
-- -------------------------------------------------------
PREPARE usuarios_sin_publicaciones(INT) AS
    SELECT vp.*
    FROM vw_perfil_usuario vp
    WHERE vp.total_publicaciones = 0
      AND vp.semestre_actual >= $1
    ORDER BY vp.nombre_completo;

EXECUTE usuarios_sin_publicaciones(3);

DEALLOCATE usuarios_sin_publicaciones;

-- -------------------------------------------------------
-- P8. Top N eventos por promedio de ocupación IoT
-- -------------------------------------------------------
PREPARE top_eventos_ocupacion(INT) AS
    SELECT *
    FROM vw_eventos_iot
    WHERE promedio_ocupacion_sensor IS NOT NULL
    ORDER BY promedio_ocupacion_sensor DESC
    LIMIT $1;

EXECUTE top_eventos_ocupacion(5);

DEALLOCATE top_eventos_ocupacion;

-- ============================================================
-- FIN SCRIPT 01 - VISTAS Y CONSULTAS PARAMETRIZADAS
-- ============================================================

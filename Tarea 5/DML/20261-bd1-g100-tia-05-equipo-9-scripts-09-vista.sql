-- ============================================================
-- PASCUALINA_DB — SCRIPT DML: VISTAS (VIEWS)
-- Tarea 5 — Bases de Datos I
-- Motor: PostgreSQL (pgAdmin4)
-- ============================================================

-- Eliminar vistas si existen (en orden por dependencias)
DROP VIEW IF EXISTS v_resumen_economico        CASCADE;
DROP VIEW IF EXISTS v_eventos_con_ocupacion    CASCADE;
DROP VIEW IF EXISTS v_grupos_con_miembros      CASCADE;
DROP VIEW IF EXISTS v_publicaciones_activas    CASCADE;
DROP VIEW IF EXISTS v_mentores_disponibles     CASCADE;
DROP VIEW IF EXISTS v_perfil_completo_usuario  CASCADE;

-- ============================================================
-- VISTA 1: v_perfil_completo_usuario
-- Objetivo: Consolida el perfil de cada estudiante junto con
-- sus intereses y habilidades. Facilita consultas de mentoría,
-- recomendaciones de grupos y matching de intereses sin
-- necesidad de escribir JOINs complejos cada vez.
-- ============================================================
CREATE VIEW v_perfil_completo_usuario AS
SELECT
    u.id_usuario,
    u.nombre || ' ' || u.apellido           AS nombre_completo,
    u.email,
    p.area_estudio,
    p.semestre,
    p.biografia,
    STRING_AGG(DISTINCT i.nombre, ', ' ORDER BY i.nombre)   AS intereses,
    STRING_AGG(DISTINCT h.nombre, ', ' ORDER BY h.nombre)   AS habilidades,
    u.fecha_registro,
    u.activo
FROM usuarios u
INNER JOIN perfiles p               ON u.id_usuario    = p.id_usuario
LEFT  JOIN intereses_usuario iu     ON u.id_usuario    = iu.id_usuario
LEFT  JOIN intereses i              ON iu.id_interes    = i.id_interes
LEFT  JOIN habilidades_usuario hu   ON u.id_usuario    = hu.id_usuario
LEFT  JOIN habilidades h            ON hu.id_habilidad = h.id_habilidad
WHERE u.activo = TRUE
GROUP BY u.id_usuario, u.nombre, u.apellido, u.email,
         p.area_estudio, p.semestre, p.biografia, u.fecha_registro, u.activo;

-- Consultar la vista
SELECT * FROM v_perfil_completo_usuario ORDER BY nombre_completo;

-- Ejemplo analítico: ¿Quién estudia Ingeniería de Sistemas?
SELECT nombre_completo, semestre, intereses, habilidades
FROM v_perfil_completo_usuario
WHERE area_estudio ILIKE '%sistemas%'
ORDER BY semestre DESC;

-- ============================================================
-- VISTA 2: v_mentores_disponibles
-- Objetivo: Identifica estudiantes que tienen interés en
-- Programación Competitiva o IA con habilidades en nivel
-- avanzado. Apoya el módulo de mentorías de la red social.
-- ============================================================
CREATE VIEW v_mentores_disponibles AS
SELECT
    u.id_usuario,
    u.nombre || ' ' || u.apellido   AS mentor,
    p.area_estudio,
    p.semestre,
    i.nombre                        AS area_mentoria,
    STRING_AGG(h.nombre || ' (' || hu.nivel || ')', ', ')
                                    AS habilidades_destacadas
FROM usuarios u
INNER JOIN perfiles p               ON u.id_usuario     = p.id_usuario
INNER JOIN intereses_usuario iu     ON u.id_usuario     = iu.id_usuario
INNER JOIN intereses i              ON iu.id_interes     = i.id_interes
INNER JOIN habilidades_usuario hu   ON u.id_usuario     = hu.id_usuario
INNER JOIN habilidades h            ON hu.id_habilidad  = h.id_habilidad
WHERE hu.nivel IN ('avanzado', 'intermedio')
  AND p.semestre >= 4
  AND u.activo = TRUE
GROUP BY u.id_usuario, u.nombre, u.apellido,
         p.area_estudio, p.semestre, i.nombre;

-- Consultar la vista
SELECT * FROM v_mentores_disponibles ORDER BY semestre DESC;

-- Ejemplo analítico: ¿Quién puede mentorizar en Python?
SELECT mentor, semestre, habilidades_destacadas
FROM v_mentores_disponibles
WHERE habilidades_destacadas ILIKE '%python%';

-- ============================================================
-- VISTA 3: v_publicaciones_activas
-- Objetivo: Muestra el feed de publicaciones junto con el
-- nombre del autor, la cantidad de comentarios recibidos y
-- el semestre del autor. Útil para el módulo de analítica de
-- contenido y detección de temas populares.
-- ============================================================
CREATE VIEW v_publicaciones_activas AS
SELECT
    pub.id_publicacion,
    u.nombre || ' ' || u.apellido   AS autor,
    p.area_estudio,
    p.semestre                      AS semestre_autor,
    pub.tipo,
    pub.contenido,
    pub.fecha_publicacion,
    pub.cantidad_reportes,
    COUNT(c.id_comentario)          AS total_comentarios
FROM publicaciones pub
INNER JOIN usuarios u       ON pub.id_usuario     = u.id_usuario
INNER JOIN perfiles p       ON u.id_usuario       = p.id_usuario
LEFT  JOIN comentarios c    ON pub.id_publicacion = c.id_publicacion
WHERE pub.cantidad_reportes <= 5
GROUP BY pub.id_publicacion, u.nombre, u.apellido,
         p.area_estudio, p.semestre, pub.tipo, pub.contenido,
         pub.fecha_publicacion, pub.cantidad_reportes;

-- Consultar la vista
SELECT autor, tipo, LEFT(contenido,60)||'...' AS resumen,
       total_comentarios, fecha_publicacion
FROM v_publicaciones_activas
ORDER BY total_comentarios DESC, fecha_publicacion DESC;

-- Ejemplo analítico: publicaciones tipo 'pregunta'
SELECT autor, LEFT(contenido,80)||'...' AS pregunta, total_comentarios
FROM v_publicaciones_activas
WHERE tipo = 'pregunta'
ORDER BY total_comentarios DESC;

-- ============================================================
-- VISTA 4: v_grupos_con_miembros
-- Objetivo: Resume la actividad de los grupos con el nombre
-- del creador, la cantidad de miembros y el tipo de grupo.
-- Potencial analítico: detectar grupos más activos, tendencias
-- por tipo (estudio vs hackaton vs club).
-- ============================================================
CREATE VIEW v_grupos_con_miembros AS
SELECT
    g.id_grupo,
    g.nombre                        AS nombre_grupo,
    g.tipo,
    u.nombre || ' ' || u.apellido   AS creador,
    p.area_estudio                  AS area_creador,
    COUNT(mg.id_usuario)            AS total_miembros,
    g.fecha_creacion,
    g.activo
FROM grupos g
INNER JOIN usuarios u       ON g.id_creador  = u.id_usuario
INNER JOIN perfiles p       ON u.id_usuario  = p.id_usuario
LEFT  JOIN miembros_grupo mg ON g.id_grupo   = mg.id_grupo
WHERE g.activo = TRUE
GROUP BY g.id_grupo, g.nombre, g.tipo, u.nombre, u.apellido,
         p.area_estudio, g.fecha_creacion, g.activo;

-- Consultar la vista
SELECT * FROM v_grupos_con_miembros ORDER BY total_miembros DESC;

-- Ejemplo analítico: ¿Qué tipos de grupos son más populares?
SELECT tipo, COUNT(*) AS cantidad_grupos, SUM(total_miembros) AS total_participantes
FROM v_grupos_con_miembros
GROUP BY tipo
ORDER BY total_participantes DESC;

-- ============================================================
-- VISTA 5: v_eventos_con_ocupacion
-- Objetivo: Combina la información de eventos con el número
-- de inscritos, cupos disponibles y el nombre del organizador.
-- Permite construir un panel de control de eventos y enviar
-- notificaciones cuando un evento está lleno.
-- ============================================================
CREATE VIEW v_eventos_con_ocupacion AS
SELECT
    e.id_evento,
    e.titulo,
    e.tipo,
    org.nombre || ' ' || org.apellido   AS organizador,
    e.fecha_evento,
    e.lugar,
    e.capacidad_max,
    COUNT(pe.id_usuario)                AS total_inscritos,
    COALESCE(e.capacidad_max - COUNT(pe.id_usuario), 0)
                                        AS cupos_disponibles,
    CASE
        WHEN e.capacidad_max IS NULL THEN 'sin límite'
        WHEN COUNT(pe.id_usuario) >= e.capacidad_max THEN 'lleno'
        WHEN COUNT(pe.id_usuario) >= e.capacidad_max * 0.8 THEN 'casi lleno'
        ELSE 'disponible'
    END                                 AS estado_ocupacion
FROM eventos e
INNER JOIN usuarios org         ON e.id_organizador = org.id_usuario
LEFT  JOIN participantes_evento pe ON e.id_evento   = pe.id_evento
   AND pe.estado IN ('inscrito','confirmado')
GROUP BY e.id_evento, e.titulo, e.tipo, org.nombre, org.apellido,
         e.fecha_evento, e.lugar, e.capacidad_max;

-- Consultar la vista
SELECT * FROM v_eventos_con_ocupacion ORDER BY fecha_evento ASC;

-- Ejemplo analítico: eventos próximos con cupos disponibles
SELECT titulo, organizador, fecha_evento, total_inscritos,
       cupos_disponibles, estado_ocupacion
FROM v_eventos_con_ocupacion
WHERE fecha_evento > NOW()
  AND estado_ocupacion <> 'lleno'
ORDER BY fecha_evento;

-- ============================================================
-- VISTA 6: v_resumen_economico
-- Objetivo: Consolida ingresos por servicios y productos de
-- cada estudiante. Es la vista de mayor potencial analítico:
-- permite identificar los estudiantes más activos en el
-- ecosistema de intercambio de Pascualina y el volumen total
-- de transacciones de la plataforma.
-- ============================================================
CREATE VIEW v_resumen_economico AS
SELECT
    u.id_usuario,
    u.nombre || ' ' || u.apellido           AS estudiante,
    p.area_estudio,
    -- Ingresos por servicios
    COALESCE(SUM(ts.monto_pagado), 0)       AS ingresos_servicios_cop,
    COALESCE(COUNT(DISTINCT ts.id_transaccion), 0) AS transac_servicios,
    -- Ingresos por productos
    COALESCE(SUM(tp.monto_total), 0)        AS ingresos_productos_cop,
    COALESCE(COUNT(DISTINCT tp.id_transaccion), 0) AS transac_productos,
    -- Totales
    COALESCE(SUM(ts.monto_pagado),0) + COALESCE(SUM(tp.monto_total),0)
                                            AS ingresos_totales_cop
FROM usuarios u
INNER JOIN perfiles p ON u.id_usuario = p.id_usuario
LEFT  JOIN servicios s              ON u.id_usuario   = s.id_ofertante
LEFT  JOIN transacciones_servicio ts ON s.id_servicio = ts.id_servicio
   AND ts.estado = 'completada'
LEFT  JOIN productos pr             ON u.id_usuario   = pr.id_vendedor
LEFT  JOIN transacciones_producto tp ON pr.id_producto = tp.id_producto
   AND tp.estado = 'completada'
WHERE u.activo = TRUE
GROUP BY u.id_usuario, u.nombre, u.apellido, p.area_estudio;

-- Consultar la vista
SELECT * FROM v_resumen_economico ORDER BY ingresos_totales_cop DESC;

-- Ejemplo analítico: top 5 estudiantes con mayores ingresos
SELECT estudiante, area_estudio,
       ingresos_servicios_cop, ingresos_productos_cop, ingresos_totales_cop
FROM v_resumen_economico
ORDER BY ingresos_totales_cop DESC
LIMIT 5;

-- ============================================================
-- FIN DEL SCRIPT DE VISTAS
-- ============================================================

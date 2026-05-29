-- ============================================================
-- PASCUALINA_DB — SCRIPT DML: CONSULTAS SELECT (LISTADOS)
-- Tarea 5 — Bases de Datos I
-- Motor: PostgreSQL (pgAdmin4)
-- ============================================================

-- ============================================================
-- CONSULTA 1
-- Pregunta de negocio: ¿Cuál es el perfil completo de cada
-- estudiante, incluyendo su área y semestre?
-- ============================================================
SELECT
    u.id_usuario,
    u.nombre || ' ' || u.apellido  AS nombre_completo,
    u.email,
    p.area_estudio,
    p.semestre,
    p.biografia,
    u.fecha_registro
FROM usuarios u
INNER JOIN perfiles p ON u.id_usuario = p.id_usuario
WHERE u.activo = TRUE
ORDER BY u.apellido, u.nombre;

-- ============================================================
-- CONSULTA 2
-- Pregunta de negocio: ¿Qué intereses y habilidades tiene
-- cada estudiante registrado en la plataforma?
-- ============================================================
SELECT
    u.nombre || ' ' || u.apellido   AS nombre_completo,
    p.area_estudio,
    STRING_AGG(DISTINCT i.nombre, ', ' ORDER BY i.nombre)  AS intereses,
    STRING_AGG(DISTINCT h.nombre   , ', ' ORDER BY h.nombre)  AS habilidades
FROM usuarios u
INNER JOIN perfiles p           ON u.id_usuario     = p.id_usuario
LEFT  JOIN intereses_usuario iu ON u.id_usuario     = iu.id_usuario
LEFT  JOIN intereses i          ON iu.id_interes     = i.id_interes
LEFT  JOIN habilidades_usuario hu ON u.id_usuario   = hu.id_usuario
LEFT  JOIN habilidades h        ON hu.id_habilidad  = h.id_habilidad
WHERE u.activo = TRUE
GROUP BY u.id_usuario, u.nombre, u.apellido, p.area_estudio
ORDER BY nombre_completo;

-- ============================================================
-- CONSULTA 3
-- Pregunta de negocio: ¿Cuántos estudiantes están interesados
-- en cada área temática?
-- ============================================================
SELECT
    i.nombre                    AS interes,
    i.categoria,
    COUNT(iu.id_usuario)        AS total_estudiantes
FROM intereses i
LEFT JOIN intereses_usuario iu ON i.id_interes = iu.id_interes
GROUP BY i.id_interes, i.nombre, i.categoria
ORDER BY total_estudiantes DESC;

-- ============================================================
-- CONSULTA 4
-- Pregunta de negocio: ¿Quiénes son los estudiantes más
-- seguidos en la red social?
-- ============================================================
SELECT
    u.nombre || ' ' || u.apellido   AS estudiante,
    p.area_estudio,
    COUNT(s.id_seguidor)            AS total_seguidores
FROM usuarios u
INNER JOIN perfiles p   ON u.id_usuario  = p.id_usuario
LEFT  JOIN seguidores s ON u.id_usuario  = s.id_seguido
GROUP BY u.id_usuario, u.nombre, u.apellido, p.area_estudio
ORDER BY total_seguidores DESC;

-- ============================================================
-- CONSULTA 5
-- Pregunta de negocio: ¿Cuáles son las publicaciones con
-- más comentarios en la plataforma?
-- ============================================================
SELECT
    pub.id_publicacion,
    u.nombre || ' ' || u.apellido   AS autor,
    pub.tipo,
    LEFT(pub.contenido, 60) || '...' AS resumen_contenido,
    pub.fecha_publicacion,
    COUNT(c.id_comentario)          AS total_comentarios
FROM publicaciones pub
INNER JOIN usuarios u       ON pub.id_usuario    = u.id_usuario
LEFT  JOIN comentarios c    ON pub.id_publicacion = c.id_publicacion
GROUP BY pub.id_publicacion, u.nombre, u.apellido, pub.tipo,
         pub.contenido, pub.fecha_publicacion
ORDER BY total_comentarios DESC
LIMIT 10;

-- ============================================================
-- CONSULTA 6
-- Pregunta de negocio: ¿Cuántos miembros tiene cada grupo
-- y quién es su creador?
-- ============================================================
SELECT
    g.id_grupo,
    g.nombre                        AS nombre_grupo,
    g.tipo,
    u.nombre || ' ' || u.apellido   AS creador,
    COUNT(mg.id_usuario)            AS total_miembros,
    g.fecha_creacion
FROM grupos g
INNER JOIN usuarios u       ON g.id_creador  = u.id_usuario
LEFT  JOIN miembros_grupo mg ON g.id_grupo   = mg.id_grupo
WHERE g.activo = TRUE
GROUP BY g.id_grupo, g.nombre, g.tipo, u.nombre, u.apellido, g.fecha_creacion
ORDER BY total_miembros DESC;

-- ============================================================
-- CONSULTA 7
-- Pregunta de negocio: ¿Cuáles son los próximos eventos y
-- cuántos participantes tiene cada uno?
-- ============================================================
SELECT
    e.id_evento,
    e.titulo,
    e.tipo,
    org.nombre || ' ' || org.apellido   AS organizador,
    e.fecha_evento,
    e.lugar,
    e.capacidad_max,
    COUNT(pe.id_usuario)                AS inscritos,
    e.capacidad_max - COUNT(pe.id_usuario) AS cupos_disponibles
FROM eventos e
INNER JOIN usuarios org         ON e.id_organizador = org.id_usuario
LEFT  JOIN participantes_evento pe ON e.id_evento   = pe.id_evento
WHERE e.fecha_evento > NOW()
  AND pe.estado IN ('inscrito','confirmado')
GROUP BY e.id_evento, e.titulo, e.tipo, org.nombre, org.apellido,
         e.fecha_evento, e.lugar, e.capacidad_max
ORDER BY e.fecha_evento ASC;

-- ============================================================
-- CONSULTA 8
-- Pregunta de negocio: ¿Qué servicios están disponibles y
-- cuál es su precio?
-- ============================================================
SELECT
    s.id_servicio,
    u.nombre || ' ' || u.apellido   AS ofertante,
    p.area_estudio,
    s.titulo,
    s.categoria,
    s.precio                        AS precio_cop,
    COUNT(ts.id_transaccion)        AS veces_contratado
FROM servicios s
INNER JOIN usuarios u       ON s.id_ofertante    = u.id_usuario
INNER JOIN perfiles p       ON u.id_usuario      = p.id_usuario
LEFT  JOIN transacciones_servicio ts ON s.id_servicio = ts.id_servicio
WHERE s.disponible = TRUE
GROUP BY s.id_servicio, u.nombre, u.apellido, p.area_estudio,
         s.titulo, s.categoria, s.precio
ORDER BY veces_contratado DESC, s.precio ASC;

-- ============================================================
-- CONSULTA 9
-- Pregunta de negocio: ¿Cuáles son los productos disponibles
-- para comprar actualmente?
-- ============================================================
SELECT
    pr.id_producto,
    u.nombre || ' ' || u.apellido   AS vendedor,
    pr.nombre                       AS producto,
    pr.categoria,
    pr.precio                       AS precio_cop,
    pr.stock,
    pr.fecha_publicacion
FROM productos pr
INNER JOIN usuarios u ON pr.id_vendedor = u.id_usuario
WHERE pr.disponible = TRUE
  AND pr.stock > 0
ORDER BY pr.fecha_publicacion DESC;

-- ============================================================
-- CONSULTA 10
-- Pregunta de negocio: ¿Qué estudiantes podrían ser mentores
-- de Programación Competitiva? (tienen ese interés en nivel avanzado)
-- ============================================================
SELECT
    u.nombre || ' ' || u.apellido   AS posible_mentor,
    p.area_estudio,
    p.semestre,
    h.nombre                        AS habilidad,
    hu.nivel
FROM usuarios u
INNER JOIN perfiles p           ON u.id_usuario     = p.id_usuario
INNER JOIN habilidades_usuario hu ON u.id_usuario   = hu.id_usuario
INNER JOIN habilidades h        ON hu.id_habilidad  = h.id_habilidad
INNER JOIN intereses_usuario iu ON u.id_usuario     = iu.id_usuario
INNER JOIN intereses i          ON iu.id_interes     = i.id_interes
WHERE i.nombre = 'Programación Competitiva'
  AND hu.nivel = 'avanzado'
ORDER BY p.semestre DESC;

-- ============================================================
-- CONSULTA 11
-- Pregunta de negocio: ¿Cuánto dinero ha generado cada
-- ofertante de servicios?
-- ============================================================
SELECT
    u.nombre || ' ' || u.apellido       AS ofertante,
    COUNT(ts.id_transaccion)            AS transacciones_completadas,
    SUM(ts.monto_pagado)                AS ingresos_totales_cop,
    AVG(ts.monto_pagado)                AS ingreso_promedio_cop
FROM usuarios u
INNER JOIN servicios s          ON u.id_usuario   = s.id_ofertante
INNER JOIN transacciones_servicio ts ON s.id_servicio = ts.id_servicio
WHERE ts.estado = 'completada'
GROUP BY u.id_usuario, u.nombre, u.apellido
ORDER BY ingresos_totales_cop DESC;

-- ============================================================
-- CONSULTA 12
-- Pregunta de negocio: ¿Cuáles son los estudiantes que
-- participan en más grupos de estudio?
-- ============================================================
SELECT
    u.nombre || ' ' || u.apellido   AS estudiante,
    p.area_estudio,
    COUNT(mg.id_grupo)              AS grupos_en_los_que_participa
FROM usuarios u
INNER JOIN perfiles p       ON u.id_usuario  = p.id_usuario
INNER JOIN miembros_grupo mg ON u.id_usuario = mg.id_usuario
INNER JOIN grupos g         ON mg.id_grupo   = g.id_grupo
WHERE g.activo = TRUE
GROUP BY u.id_usuario, u.nombre, u.apellido, p.area_estudio
ORDER BY grupos_en_los_que_participa DESC;

-- ============================================================
-- FIN DEL SCRIPT DE CONSULTAS
-- ============================================================

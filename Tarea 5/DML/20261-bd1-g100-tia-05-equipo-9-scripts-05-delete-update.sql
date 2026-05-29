-- ============================================================
-- PASCUALINA_DB — SCRIPT DML: UPDATE Y DELETE
-- Tarea 5 — Bases de Datos I
-- Motor: PostgreSQL (pgAdmin4)
-- ============================================================

-- ============================================================
-- UPDATES — ACTUALIZACIÓN DE DATOS
-- ============================================================

-- UPDATE 1
-- Pregunta de negocio: Actualizar el semestre y la biografía
-- del perfil de un estudiante cuando avanza en la carrera.
UPDATE perfiles
SET
    semestre            = 6,
    biografia           = 'Desarrolladora web con experiencia en React y PostgreSQL. Interesada en IA aplicada.',
    fecha_actualizacion = NOW()
WHERE id_usuario = 1;

-- Verificar el cambio
SELECT id_usuario, semestre, biografia, fecha_actualizacion
FROM perfiles
WHERE id_usuario = 1;

-- ============================================================

-- UPDATE 2
-- Pregunta de negocio: Marcar un servicio como no disponible
-- cuando el estudiante ya no puede ofrecerlo.
UPDATE servicios
SET disponible = FALSE
WHERE id_servicio = 5;  -- Diseño de Logo (oferta gratuita cerrada)

-- Verificar
SELECT id_servicio, titulo, disponible FROM servicios WHERE id_servicio = 5;

-- ============================================================

-- UPDATE 3
-- Pregunta de negocio: Actualizar el estado de inscripción
-- de participantes a un evento (confirmar asistencia).
UPDATE participantes_evento
SET estado = 'confirmado'
WHERE id_evento  = 4
  AND id_usuario IN (6, 9, 10);

-- Verificar
SELECT id_evento, id_usuario, estado
FROM participantes_evento
WHERE id_evento = 4;

-- ============================================================

-- UPDATE 4
-- Pregunta de negocio: Reducir el stock de un producto
-- después de una venta completada.
UPDATE productos
SET
    stock       = stock - 1,
    disponible  = CASE WHEN stock - 1 <= 0 THEN FALSE ELSE TRUE END
WHERE id_producto = 1;

-- Verificar
SELECT id_producto, nombre, stock, disponible FROM productos WHERE id_producto = 1;

-- ============================================================

-- UPDATE 5
-- Pregunta de negocio: Marcar una publicación como eliminada
-- aumentando su contador de reportes (moderación).
UPDATE publicaciones
SET cantidad_reportes = cantidad_reportes + 1
WHERE id_publicacion = 6;

-- Verificar
SELECT id_publicacion, tipo, cantidad_reportes FROM publicaciones WHERE id_publicacion = 6;

-- ============================================================

-- UPDATE 6
-- Pregunta de negocio: Actualizar el nivel de habilidad de
-- un estudiante después de demostrar mayor destreza.
UPDATE habilidades_usuario
SET nivel = 'avanzado'
WHERE id_usuario   = 6
  AND id_habilidad = 1;  -- Felipe: Python básico → avanzado

-- Verificar
SELECT u.nombre, h.nombre AS habilidad, hu.nivel
FROM habilidades_usuario hu
INNER JOIN usuarios    u ON hu.id_usuario    = u.id_usuario
INNER JOIN habilidades h ON hu.id_habilidad  = h.id_habilidad
WHERE hu.id_usuario = 6;

-- ============================================================
-- DELETES — ELIMINACIÓN DE DATOS
-- ============================================================

-- DELETE 1
-- Pregunta de negocio: Eliminar un comentario específico
-- (por moderación o solicitud del autor).
-- Guardamos el ID antes de borrar para verificar
DO $$
DECLARE v_id INT;
BEGIN
    SELECT id_comentario INTO v_id FROM comentarios
    WHERE id_publicacion = 2 AND id_usuario = 6 LIMIT 1;
    RAISE NOTICE 'Eliminando comentario ID: %', v_id;
END $$;

DELETE FROM comentarios
WHERE id_publicacion = 2
  AND id_usuario     = 6;

-- Verificar que ya no existe
SELECT * FROM comentarios WHERE id_publicacion = 2 AND id_usuario = 6;

-- ============================================================

-- DELETE 2
-- Pregunta de negocio: Eliminar publicaciones con más de
-- 5 reportes (moderación automática de contenido).
DELETE FROM publicaciones
WHERE cantidad_reportes > 5;

-- Verificar: no deben quedar publicaciones con más de 5 reportes
SELECT id_publicacion, tipo, cantidad_reportes
FROM publicaciones
WHERE cantidad_reportes > 5;

-- ============================================================

-- DELETE 3
-- Pregunta de negocio: Cancelar la inscripción de un usuario
-- a un evento antes de que se realice.
DELETE FROM participantes_evento
WHERE id_evento  = 5
  AND id_usuario = 2;

-- Verificar
SELECT id_evento, id_usuario, estado
FROM participantes_evento
WHERE id_evento = 5;

-- ============================================================

-- DELETE 4
-- Pregunta de negocio: Remover a un estudiante de un grupo
-- cuando decide salirse.
DELETE FROM miembros_grupo
WHERE id_grupo   = 5
  AND id_usuario = 6;

-- Verificar
SELECT id_grupo, id_usuario, rol
FROM miembros_grupo
WHERE id_grupo = 5;

-- ============================================================

-- DELETE 5
-- Pregunta de negocio: Eliminar transacciones de servicio
-- que fueron canceladas (limpieza de datos históricos).
DELETE FROM transacciones_servicio
WHERE estado = 'cancelada';

-- Verificar
SELECT estado, COUNT(*) AS total
FROM transacciones_servicio
GROUP BY estado;

-- ============================================================

-- DELETE 6
-- Pregunta de negocio: Desvincular un interés de un usuario
-- cuando actualiza su perfil.
DELETE FROM intereses_usuario
WHERE id_usuario = 7
  AND id_interes = 3;  -- Daniela ya no está interesada en Videojuegos

-- Verificar intereses restantes de ese usuario
SELECT u.nombre, i.nombre AS interes
FROM intereses_usuario iu
INNER JOIN usuarios  u ON iu.id_usuario = u.id_usuario
INNER JOIN intereses i ON iu.id_interes  = i.id_interes
WHERE iu.id_usuario = 7;

-- ============================================================
-- FIN DEL SCRIPT UPDATE / DELETE
-- ============================================================

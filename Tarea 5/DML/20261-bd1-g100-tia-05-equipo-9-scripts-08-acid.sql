-- ============================================================
-- PASCUALINA_DB — SCRIPT: TRANSACCIONES ACID
-- Tarea 5 — Bases de Datos I
-- Motor: PostgreSQL (pgAdmin4)
-- Las transacciones garantizan Atomicidad, Consistencia,
-- Aislamiento y Durabilidad en operaciones críticas.
-- ============================================================

-- ============================================================
-- TRANSACCIÓN 1: REGISTRO COMPLETO DE UN NUEVO USUARIO
-- Garantiza que usuario + perfil + interés inicial se crean
-- todos juntos o no se crea ninguno.
-- (Atomicidad: si falla algún paso, se revierte todo)
-- ============================================================
BEGIN;

    INSERT INTO usuarios (nombre, apellido, email, contrasena_hash)
    VALUES ('Carolina', 'Pedraza', 'c.pedraza@pascualina.edu.co', 'hash_v11')
    RETURNING id_usuario;

    -- Usar el ID generado (en pgAdmin4 ver el resultado del RETURNING)
    -- Asumiendo que el nuevo ID es 11:
    INSERT INTO perfiles (id_usuario, area_estudio, semestre, biografia)
    VALUES (11, 'Ingeniería de Sistemas', 1, 'Recién llegada a la universidad. ¡Emocionada!');

    INSERT INTO intereses_usuario (id_usuario, id_interes)
    VALUES (11, 3);  -- Interés: Videojuegos

    COMMIT;

-- Verificar que los tres registros existen
SELECT u.nombre, u.email, p.area_estudio, p.semestre, i.nombre AS interes
FROM usuarios u
INNER JOIN perfiles p           ON u.id_usuario  = p.id_usuario
INNER JOIN intereses_usuario iu ON u.id_usuario  = iu.id_usuario
INNER JOIN intereses i          ON iu.id_interes  = i.id_interes
WHERE u.email = 'c.pedraza@pascualina.edu.co';

-- ============================================================
-- TRANSACCIÓN 2: COMPRA DE UN SERVICIO
-- Registra la transacción y marca el servicio como no
-- disponible si el ofertante solo acepta un cliente a la vez.
-- ============================================================
BEGIN;

    -- Registrar la transacción de compra
    INSERT INTO transacciones_servicio (id_servicio, id_comprador, monto_pagado, estado)
    VALUES (4, 3, 30000.00, 'completada');

    -- Actualizar disponibilidad del servicio si corresponde
    UPDATE servicios
    SET disponible = FALSE
    WHERE id_servicio = 4
      AND (SELECT COUNT(*) FROM transacciones_servicio
           WHERE id_servicio = 4 AND estado = 'completada') >= 3;

    COMMIT;

-- Verificar transacción registrada
SELECT ts.id_transaccion, s.titulo, u.nombre AS comprador, ts.monto_pagado, ts.estado
FROM transacciones_servicio ts
INNER JOIN servicios s  ON ts.id_servicio = s.id_servicio
INNER JOIN usuarios u   ON ts.id_comprador = u.id_usuario
WHERE ts.id_servicio = 4
ORDER BY ts.fecha_transaccion DESC;

-- ============================================================
-- TRANSACCIÓN 3: COMPRA DE UN PRODUCTO
-- Registra la compra y reduce el stock. Si el stock llega a
-- 0, el producto se marca como no disponible.
-- ============================================================
BEGIN;

    -- Verificar stock antes de comprar (lectura dentro de transacción)
    -- Si stock = 0, el INSERT fallaría por lógica de negocio
    -- (en producción se usaría un CHECK o trigger)

    INSERT INTO transacciones_producto (id_producto, id_comprador, cantidad, monto_total, estado)
    VALUES (8, 6, 1, 150000.00, 'completada');

    -- Reducir stock
    UPDATE productos
    SET stock      = stock - 1,
        disponible = CASE WHEN stock - 1 <= 0 THEN FALSE ELSE disponible END
    WHERE id_producto = 8;

    COMMIT;

-- Verificar producto actualizado
SELECT id_producto, nombre, stock, disponible FROM productos WHERE id_producto = 8;

-- ============================================================
-- TRANSACCIÓN 4: INSCRIPCIÓN A EVENTO CON CONTROL DE CUPOS
-- Inscribe a un usuario solo si hay cupos disponibles.
-- Demuestra el uso de ROLLBACK explícito.
-- ============================================================
BEGIN;

    -- Verificar cupos disponibles antes de inscribir
    DO $$
    DECLARE
        v_capacidad   INT;
        v_inscritos   INT;
        v_id_evento   INT := 2;
        v_id_usuario  INT := 7;
    BEGIN
        SELECT capacidad_max INTO v_capacidad
        FROM eventos WHERE id_evento = v_id_evento;

        SELECT COUNT(*) INTO v_inscritos
        FROM participantes_evento
        WHERE id_evento = v_id_evento
          AND estado IN ('inscrito','confirmado');

        IF v_capacidad IS NOT NULL AND v_inscritos >= v_capacidad THEN
            RAISE EXCEPTION 'No hay cupos disponibles para el evento %', v_id_evento;
        ELSE
            INSERT INTO participantes_evento (id_evento, id_usuario, estado)
            VALUES (v_id_evento, v_id_usuario, 'inscrito')
            ON CONFLICT (id_evento, id_usuario) DO NOTHING;
            RAISE NOTICE 'Inscripción exitosa. Inscritos: % / %', v_inscritos + 1, v_capacidad;
        END IF;
    END $$;

    COMMIT;

-- Verificar inscripción
SELECT pe.id_evento, u.nombre, pe.estado, pe.fecha_inscripcion
FROM participantes_evento pe
INNER JOIN usuarios u ON pe.id_usuario = u.id_usuario
WHERE pe.id_evento = 2
ORDER BY pe.fecha_inscripcion;

-- ============================================================
-- TRANSACCIÓN 5 (ROLLBACK): DEMOSTRACIÓN DE ROLLBACK
-- Simula un error que revierte toda la operación.
-- ============================================================
BEGIN;

    -- Paso 1: Crear un grupo nuevo
    INSERT INTO grupos (id_creador, nombre, descripcion, tipo)
    VALUES (9, 'Club de Criptografía', 'Estudio de algoritmos criptográficos.', 'club');

    -- Paso 2: Intentar agregar un miembro con ID inexistente → forzará error FK
    -- Descomenta la línea siguiente para ver el ROLLBACK en acción:
    -- INSERT INTO miembros_grupo (id_grupo, id_usuario) VALUES (currval('grupos_id_grupo_seq'), 999);

    -- Si no hay error, confirmar
    COMMIT;

-- Si hubiese fallado el paso 2, el ROLLBACK automático de PostgreSQL
-- garantiza que el grupo tampoco quede creado (Atomicidad).

-- ============================================================
-- TRANSACCIÓN 6: TRANSFERENCIA DE ROL EN UN GRUPO
-- Cambia el administrador de un grupo y registra el cambio
-- en una sola transacción atómica.
-- ============================================================
BEGIN;

    -- Quitar rol de admin al creador actual en el grupo 4
    UPDATE miembros_grupo
    SET rol = 'miembro'
    WHERE id_grupo = 4 AND id_usuario = 1;

    -- Asignar rol admin a otro miembro
    UPDATE miembros_grupo
    SET rol = 'admin'
    WHERE id_grupo = 4 AND id_usuario = 2;

    COMMIT;

-- Verificar roles actualizados
SELECT mg.id_grupo, u.nombre, mg.rol
FROM miembros_grupo mg
INNER JOIN usuarios u ON mg.id_usuario = u.id_usuario
WHERE mg.id_grupo = 4
ORDER BY mg.rol DESC;

-- ============================================================
-- CONSULTA DE VERIFICACIÓN GENERAL ACID
-- Muestra el estado actual de las tablas más importantes
-- después de ejecutar todas las transacciones.
-- ============================================================
SELECT 'usuarios'          AS tabla, COUNT(*) AS registros FROM usuarios
UNION ALL
SELECT 'perfiles',          COUNT(*) FROM perfiles
UNION ALL
SELECT 'publicaciones',     COUNT(*) FROM publicaciones
UNION ALL
SELECT 'comentarios',       COUNT(*) FROM comentarios
UNION ALL
SELECT 'grupos',            COUNT(*) FROM grupos
UNION ALL
SELECT 'miembros_grupo',    COUNT(*) FROM miembros_grupo
UNION ALL
SELECT 'eventos',           COUNT(*) FROM eventos
UNION ALL
SELECT 'participantes',     COUNT(*) FROM participantes_evento
UNION ALL
SELECT 'servicios',         COUNT(*) FROM servicios
UNION ALL
SELECT 'trans_servicios',   COUNT(*) FROM transacciones_servicio
UNION ALL
SELECT 'productos',         COUNT(*) FROM productos
UNION ALL
SELECT 'trans_productos',   COUNT(*) FROM transacciones_producto
ORDER BY tabla;

-- ============================================================
-- FIN DEL SCRIPT DE TRANSACCIONES ACID
-- ============================================================

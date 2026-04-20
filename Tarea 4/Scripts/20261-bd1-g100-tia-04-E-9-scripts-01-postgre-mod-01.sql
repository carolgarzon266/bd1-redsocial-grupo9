--

-- 1. Crear tabla coherente con el sistema
CREATE TABLE laboratorios_provisionales (
    id_lab SERIAL PRIMARY KEY,
    nombre_lab VARCHAR(50) NOT NULL,
    capacidad_max INT,
    ubicacion TEXT
);

-- 3. Quitar uno de los campos
ALTER TABLE laboratorios_provisionales DROP COLUMN ubicacion;

-- 4. Cambiar nombre de la tabla
ALTER TABLE laboratorios_provisionales RENAME TO recursos_academicos;

-- 5. Agregar campo único
ALTER TABLE recursos_academicos ADD COLUMN codigo_inventario VARCHAR(20) UNIQUE;

-- 6. Fechas con control de orden
ALTER TABLE recursos_academicos 
ADD COLUMN fecha_asignacion TIMESTAMP,
ADD COLUMN fecha_devolucion TIMESTAMP,
ADD CONSTRAINT check_fechas_recurso CHECK (fecha_devolucion > fecha_asignacion);

-- 7. Campo entero no negativo
ALTER TABLE recursos_academicos 
ADD COLUMN horas_uso INT,
ADD CONSTRAINT check_horas_positivas CHECK (horas_uso >= 0);

-- 8. Modificar tamaño de campo texto
ALTER TABLE recursos_academicos ALTER COLUMN nombre_lab TYPE VARCHAR(150);

-- 9. Control de rango
ALTER TABLE recursos_academicos 
ADD CONSTRAINT check_rango_capacidad CHECK (capacidad_max BETWEEN 1 AND 50);

-- 10. Agregar índice
CREATE INDEX idx_codigo_recurso ON recursos_academicos(codigo_inventario);
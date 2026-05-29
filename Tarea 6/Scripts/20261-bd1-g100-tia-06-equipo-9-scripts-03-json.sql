-- ============================================================
-- RED SOCIAL UNIVERSITARIA PASCUALINA
-- TAREA 6 - SCRIPT 03: OPERACIONES DML CON TIPO JSON
-- INSERT · UPDATE · DELETE · SELECT sobre campos JSON
-- Nota: JSON almacena texto plano (sin índices GIN)
-- ============================================================

-- ============================================================
-- SECCIÓN 1 – INSERT con campos JSON
-- ============================================================

-- J-INS-1: Insertar usuario con datos_perfil JSON
INSERT INTO usuarios (
    nombre_completo,
    correo_institucional,
    contrasena_hash,
    programa_academico,
    semestre_actual,
    tipo_usuario,
    datos_perfil   -- tipo JSON
)
VALUES (
    'Laura Sofía Mendoza Ríos',
    'lsmendoza@pascal.edu.co',
    'hashed_pass_demo_001',
    'Psicología',
    4,
    'estudiante',
    '{"ciudad_origen":"Manizales",
      "intereses":["arte","bienestar","lectura"],
      "redes_sociales":{"instagram":"@laurasofia_art","twitter":"@lsm_psico"},
      "habilidades":["escucha activa","redacción","empatía"],
      "disponibilidad":"tardes"}'::JSON
);

-- J-INS-2: Publicación con metadatos JSON (texto, sin índice)
INSERT INTO publicaciones (
    id_autor,
    tipo_contenido,
    texto_publicacion,
    metadatos       -- tipo JSON
)
VALUES (
    (SELECT id_usuario FROM usuarios WHERE correo_institucional = 'lsmendoza@pascal.edu.co'),
    'texto',
    'Primer día en el campus Pascualina — increíble la energía del lugar 🎓',
    '{"likes":0,
      "comentarios":0,
      "compartidos":0,
      "vistas":0,
      "hashtags":["#PrimerDia","#Pascualina","#Psicologia"],
      "ubicacion":"Campus principal",
      "dispositivo":"móvil"}'::JSON
);

-- J-INS-3: Evento académico con datos_evento JSON
INSERT INTO eventos (
    nombre_evento,
    descripcion,
    fecha_inicio,
    fecha_fin,
    ubicacion,
    cupo_maximo,
    id_organizador,
    datos_evento    -- tipo JSON
)
VALUES (
    'Semana de la Salud Mental 2025',
    'Charlas, talleres y actividades de bienestar universitario.',
    '2025-09-15 08:00:00',
    '2025-09-19 18:00:00',
    'Auditorio Bloque B',
    120,
    1,
    '{"categoria":"bienestar",
      "modalidad":"presencial",
      "ponentes":["Dr. Álvarez","Mg. Torres","Lic. Ríos"],
      "recursos":["proyector","microfono","folletos"],
      "costo":0,
      "certificado":true}'::JSON
);

-- J-INS-4: Grupo de estudio con datos_grupo JSON
INSERT INTO grupos (
    nombre_grupo,
    descripcion,
    id_creador,
    datos_grupo     -- tipo JSON
)
VALUES (
    'Bienestar y Mindfulness UP',
    'Espacio para prácticas de meditación, yoga y salud mental estudiantil.',
    1,
    '{"categoria":"bienestar",
      "privacidad":"publico",
      "reglas":["Respeto","Sin spam","Participación activa"],
      "temas_principales":["meditación","yoga","estrés académico"],
      "frecuencia_reuniones":"semanal"}'::JSON
);

-- J-INS-5: Log de actividad con detalle JSON
INSERT INTO logs_actividad (
    id_usuario,
    accion,
    detalle_log     -- tipo JSON
)
VALUES (
    (SELECT id_usuario FROM usuarios WHERE correo_institucional = 'lsmendoza@pascal.edu.co'),
    'registro',
    '{"modulo":"autenticacion",
      "dispositivo":"móvil",
      "sistema_operativo":"Android 14",
      "ip":"192.168.1.55",
      "duracion_seg":12,
      "resultado":"exitoso",
      "version_app":"2.4.1"}'::JSON
);

-- ============================================================
-- SECCIÓN 2 – SELECT con operadores JSON
-- ============================================================

-- J-SEL-1: Extraer campo simple con operador ->>'campo'
SELECT
    id_usuario,
    nombre_completo,
    datos_perfil->>'ciudad_origen'         AS ciudad,
    datos_perfil->>'intereses'             AS intereses,
    datos_perfil->>'disponibilidad'        AS disponibilidad
FROM usuarios
WHERE datos_perfil IS NOT NULL
ORDER BY nombre_completo;

-- J-SEL-2: Acceso anidado: redes sociales dentro de datos_perfil
SELECT
    nombre_completo,
    datos_perfil->'redes_sociales'->>'instagram'  AS instagram,
    datos_perfil->'redes_sociales'->>'twitter'    AS twitter
FROM usuarios
WHERE datos_perfil->'redes_sociales' IS NOT NULL;

-- J-SEL-3: Filtrar por valor dentro de JSON (cast a text)
SELECT
    nombre_completo,
    programa_academico,
    datos_perfil->>'disponibilidad' AS disponibilidad
FROM usuarios
WHERE datos_perfil->>'disponibilidad' = 'tardes';

-- J-SEL-4: Publicaciones con más de 5 likes (extraído de JSON)
SELECT
    p.id_publicacion,
    u.nombre_completo,
    p.texto_publicacion,
    (p.metadatos->>'likes')::INT           AS likes,
    p.metadatos->>'hashtags'              AS hashtags,
    p.metadatos->>'ubicacion'             AS ubicacion
FROM publicaciones p
JOIN usuarios u ON u.id_usuario = p.id_autor
WHERE (p.metadatos->>'likes')::INT > 5
  AND p.eliminada = FALSE
ORDER BY likes DESC;

-- J-SEL-5: Eventos por categoría usando JSON
SELECT
    nombre_evento,
    fecha_inicio,
    cupo_maximo,
    datos_evento->>'categoria'            AS categoria,
    datos_evento->>'modalidad'            AS modalidad,
    datos_evento->>'costo'                AS costo,
    datos_evento->>'certificado'          AS certificado
FROM eventos
WHERE datos_evento->>'categoria' = 'bienestar';

-- J-SEL-6: Logs de acción 'registro' con detalle JSON completo
SELECT
    l.id_log,
    u.nombre_completo,
    l.accion,
    l.detalle_log->>'modulo'              AS modulo,
    l.detalle_log->>'dispositivo'         AS dispositivo,
    l.detalle_log->>'ip'                  AS ip,
    l.detalle_log->>'resultado'           AS resultado,
    l.fecha_accion
FROM logs_actividad l
JOIN usuarios u ON u.id_usuario = l.id_usuario
WHERE l.accion = 'registro'
ORDER BY l.fecha_accion DESC;

-- ============================================================
-- SECCIÓN 3 – UPDATE sobre campos JSON
-- ============================================================

-- J-UPD-1: Actualizar todo el JSON de datos_perfil
UPDATE usuarios
SET datos_perfil = '{
    "ciudad_origen":"Manizales",
    "intereses":["arte","bienestar","lectura","fotografía"],
    "redes_sociales":{
        "instagram":"@laurasofia_updated",
        "twitter":"@lsm_psico",
        "linkedin":"laurasofiam"
    },
    "habilidades":["escucha activa","redacción","empatía","fotografía"],
    "disponibilidad":"mañanas y tardes"
}'::JSON
WHERE correo_institucional = 'lsmendoza@pascal.edu.co';

-- J-UPD-2: Actualizar metadatos de publicación (incrementar likes)
UPDATE publicaciones
SET metadatos = (
    '{"likes":'
    || ((metadatos->>'likes')::INT + 10)::TEXT
    || ',"comentarios":'
    || (metadatos->>'comentarios')
    || ',"compartidos":'
    || (metadatos->>'compartidos')
    || ',"vistas":'
    || ((metadatos->>'vistas')::INT + 100)::TEXT
    || ',"hashtags":["#PrimerDia","#Pascualina","#Psicologia"]'
    || ',"ubicacion":"Campus principal","dispositivo":"móvil"}'
)::JSON
WHERE id_autor = (
    SELECT id_usuario FROM usuarios
    WHERE correo_institucional = 'lsmendoza@pascal.edu.co'
)
AND tipo_contenido = 'texto';

-- J-UPD-3: Cambiar categoría y añadir campo en datos_evento
UPDATE eventos
SET datos_evento = '{
    "categoria":"bienestar_mental",
    "modalidad":"hibrido",
    "ponentes":["Dr. Álvarez","Mg. Torres","Lic. Ríos","Dr. Herrera"],
    "recursos":["proyector","microfono","folletos","plataforma_virtual"],
    "costo":0,
    "certificado":true,
    "transmision_online":"https://meet.pascal.edu.co/smm2025"
}'::JSON
WHERE nombre_evento = 'Semana de la Salud Mental 2025';

-- ============================================================
-- SECCIÓN 4 – DELETE con condiciones sobre JSON
-- ============================================================

-- J-DEL-1: Eliminar publicaciones sin likes (JSON = 0)
DELETE FROM publicaciones
WHERE (metadatos->>'likes')::INT = 0
  AND eliminada = FALSE
  AND fecha_publicacion < NOW() - INTERVAL '30 days';

-- J-DEL-2: Eliminar logs de 'registro' con resultado 'fallido'
DELETE FROM logs_actividad
WHERE accion = 'registro'
  AND detalle_log->>'resultado' = 'fallido'
  AND fecha_accion < NOW() - INTERVAL '7 days';

-- J-DEL-3: Baja lógica de grupos con privacidad 'privado' y sin miembros
UPDATE grupos
SET activo = FALSE
WHERE datos_grupo->>'privacidad' = 'privado'
  AND id_grupo NOT IN (
      SELECT DISTINCT id_grupo FROM miembros_grupo
  );

-- ============================================================
-- VERIFICACIÓN FINAL
-- ============================================================
SELECT
    'usuarios'         AS tabla,
    COUNT(*) AS total FROM usuarios
UNION ALL
SELECT 'publicaciones',  COUNT(*) FROM publicaciones WHERE eliminada = FALSE
UNION ALL
SELECT 'eventos',        COUNT(*) FROM eventos
UNION ALL
SELECT 'grupos',         COUNT(*) FROM grupos WHERE activo = TRUE
UNION ALL
SELECT 'logs_actividad', COUNT(*) FROM logs_actividad;

-- ============================================================
-- FIN SCRIPT 03 - OPERACIONES DML JSON
-- ============================================================

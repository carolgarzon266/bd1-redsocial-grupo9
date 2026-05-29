-- ============================================================
-- PASCUALINA_DB — SCRIPT DML: POBLAMIENTO (INSERT)
-- Tarea 5 — Bases de Datos I
-- Motor: PostgreSQL (pgAdmin4)
-- Ejecutar DESPUÉS del script DDL de creación
-- ============================================================

-- ============================================================
-- USUARIOS (10 estudiantes)
-- ============================================================
INSERT INTO usuarios (nombre, apellido, email, contrasena_hash) VALUES
    ('Valentina', 'Ríos',      'v.rios@pascualina.edu.co',      'hash_v1'),
    ('Sebastián', 'Mora',      's.mora@pascualina.edu.co',      'hash_v2'),
    ('Camila',    'Torres',    'c.torres@pascualina.edu.co',    'hash_v3'),
    ('Andrés',    'Gómez',     'a.gomez@pascualina.edu.co',     'hash_v4'),
    ('Luisa',     'Herrera',   'l.herrera@pascualina.edu.co',   'hash_v5'),
    ('Felipe',    'Vargas',    'f.vargas@pascualina.edu.co',    'hash_v6'),
    ('Daniela',   'Castillo',  'd.castillo@pascualina.edu.co',  'hash_v7'),
    ('Mateo',     'Jiménez',   'm.jimenez@pascualina.edu.co',   'hash_v8'),
    ('Sara',      'Ospina',    's.ospina@pascualina.edu.co',    'hash_v9'),
    ('Juan',      'Navarro',   'j.navarro@pascualina.edu.co',   'hash_v10');

-- ============================================================
-- PERFILES
-- ============================================================
INSERT INTO perfiles (id_usuario, area_estudio, semestre, biografia) VALUES
    (1,  'Ingeniería de Sistemas',    5,  'Apasionada por el desarrollo web y la IA.'),
    (2,  'Ingeniería de Sistemas',    7,  'Desarrollador backend, amante de Python.'),
    (3,  'Diseño Gráfico',            3,  'UX/UI y arte digital.'),
    (4,  'Ingeniería de Software',    9,  'Arquitectura de software y DevOps.'),
    (5,  'Ciencia de Datos',          6,  'Machine learning y visualización de datos.'),
    (6,  'Ingeniería de Sistemas',    2,  'Primer semestre, aprendiendo programación.'),
    (7,  'Administración de Empresas',4,  'Emprendimiento tecnológico.'),
    (8,  'Ingeniería de Software',    8,  'Seguridad informática y redes.'),
    (9,  'Matemáticas',               4,  'Álgebra lineal y criptografía.'),
    (10, 'Ingeniería de Sistemas',    6,  'Programación competitiva y algoritmos.');

-- ============================================================
-- INTERESES
-- ============================================================
INSERT INTO intereses (nombre, categoria) VALUES
    ('Programación Competitiva', 'tecnología'),
    ('Inteligencia Artificial',  'tecnología'),
    ('Videojuegos',              'entretenimiento'),
    ('Diseño UX/UI',             'tecnología'),
    ('Ciencia de Datos',         'tecnología'),
    ('Emprendimiento',           'negocios'),
    ('Deportes',                 'deporte'),
    ('Música',                   'arte'),
    ('Seguridad Informática',    'tecnología'),
    ('Robótica',                 'tecnología');

-- ============================================================
-- INTERESES POR USUARIO
-- ============================================================
INSERT INTO intereses_usuario (id_usuario, id_interes) VALUES
    (1, 1), (1, 2), (1, 4),
    (2, 1), (2, 2), (2, 5),
    (3, 4), (3, 8),
    (4, 9), (4, 2),
    (5, 2), (5, 5),
    (6, 1), (6, 3),
    (7, 6), (7, 3),
    (8, 9), (8, 1),
    (9, 1), (9, 5),
    (10,1), (10,2);

-- ============================================================
-- HABILIDADES
-- ============================================================
INSERT INTO habilidades (nombre, tipo) VALUES
    ('Python',          'técnica'),
    ('JavaScript',      'técnica'),
    ('PostgreSQL',      'técnica'),
    ('Machine Learning','técnica'),
    ('Diseño Figma',    'técnica'),
    ('Fútbol',          'deportiva'),
    ('Guitarra',        'artística'),
    ('Docker',          'técnica'),
    ('C++',             'técnica'),
    ('React',           'técnica');

-- ============================================================
-- HABILIDADES POR USUARIO
-- ============================================================
INSERT INTO habilidades_usuario (id_usuario, id_habilidad, nivel) VALUES
    (1, 1, 'avanzado'),  (1, 2, 'intermedio'), (1, 3, 'básico'),
    (2, 1, 'avanzado'),  (2, 3, 'avanzado'),   (2, 8, 'intermedio'),
    (3, 5, 'avanzado'),  (3, 2, 'básico'),
    (4, 8, 'avanzado'),  (4, 1, 'intermedio'),
    (5, 4, 'avanzado'),  (5, 1, 'avanzado'),   (5, 3, 'intermedio'),
    (6, 1, 'básico'),    (6, 9, 'básico'),
    (7, 2, 'básico'),
    (8, 9, 'avanzado'),  (8, 8, 'avanzado'),
    (9, 9, 'intermedio'),(9, 3, 'básico'),
    (10,9, 'avanzado'),  (10,1,'intermedio');

-- ============================================================
-- SEGUIDORES (relaciones de seguimiento)
-- ============================================================
INSERT INTO seguidores (id_seguidor, id_seguido) VALUES
    (1, 2), (1, 4), (1, 5),
    (2, 1), (2, 5), (2, 10),
    (3, 1), (3, 7),
    (4, 2), (4, 8),
    (5, 1), (5, 2),
    (6, 1), (6, 2), (6, 10),
    (7, 3), (7, 6),
    (8, 4), (8, 9),
    (9, 5), (9, 10),
    (10,1), (10,8);

-- ============================================================
-- PUBLICACIONES
-- ============================================================
INSERT INTO publicaciones (id_usuario, tipo, contenido) VALUES
    (1,  'pregunta', '¿Alguien puede explicarme cómo funcionan los índices en PostgreSQL?'),
    (2,  'recurso',  'Comparto este repo con ejercicios de SQL para practicar: github.com/ejemplo'),
    (3,  'general',  '¡Acabo de terminar mi primer prototipo en Figma! ¿Feedback?'),
    (4,  'noticia',  'Docker Desktop ya soporta Apple Silicon de forma nativa. Un cambio enorme.'),
    (5,  'recurso',  'Notebook de Jupyter con introducción a Pandas: colab.research.google.com/xxx'),
    (6,  'meme',     'Cuando el profe dice "entreguen para mañana" el domingo a las 11 pm 😂'),
    (7,  'general',  'Buscamos co-fundadores para startup de edtech. ¡Escríbanos!'),
    (8,  'pregunta', '¿Cuál es la diferencia práctica entre simétrico y asimétrico en criptografía?'),
    (9,  'recurso',  'Lista de problemas de álgebra lineal con soluciones paso a paso.'),
    (10, 'general',  'Primer lugar en el simulacro de ICPC regional. ¡Seguimos entrenando!'),
    (1,  'pregunta', '¿Cómo manejan las migraciones de base de datos en proyectos grandes?'),
    (2,  'noticia',  'PostgreSQL 17 fue lanzado con mejoras importantes en particionamiento.'),
    (5,  'recurso',  'Curso gratuito de Scikit-Learn en Kaggle: kaggle.com/learn'),
    (4,  'general',  'Próximamente taller de CI/CD con GitHub Actions. ¡Estén pendientes!');

-- ============================================================
-- COMENTARIOS
-- ============================================================
INSERT INTO comentarios (id_publicacion, id_usuario, contenido) VALUES
    (1, 2,  'Los índices B-Tree son los más comunes; mejoran lecturas pero añaden costo en escrituras.'),
    (1, 5,  'Te recomiendo el capítulo 11 del libro "PostgreSQL: Up and Running".'),
    (2, 6,  'Gracias, justo lo que necesitaba para practicar antes del parcial.'),
    (3, 1,  '¡Queda increíble! Me encantó la paleta de colores.'),
    (4, 2,  'Sí, lo probé y funciona perfecto. Mucho más estable que con Rosetta.'),
    (5, 1,  'Excelente recurso, lo voy a compartir con mi grupo de estudio.'),
    (8, 9,  'La diferencia principal está en cómo se comparten las claves. Simétrico usa la misma clave.'),
    (8, 4,  'Para la práctica, RSA es el ejemplo clásico de asimétrico.'),
    (10,6,  '¡Felicitaciones! ¿Hacen entrenamientos abiertos?'),
    (10,1,  'Increíble logro. ¿Qué plataforma usan para entrenar?'),
    (11,4,  'Nosotros usamos Flyway y Liquibase. Muy recomendados.'),
    (12,5,  'Sí, el nuevo particionamiento declarativo es un antes y un después.');

-- ============================================================
-- GRUPOS
-- ============================================================
INSERT INTO grupos (id_creador, nombre, descripcion, tipo) VALUES
    (10, 'Club de Programación Competitiva',   'Entrenamiento para ICPC y Codeforces.',             'competitivo'),
    (5,  'Ciencia de Datos Pascualina',        'Aprendizaje colaborativo de ML y análisis.',         'estudio'),
    (4,  'DevOps & Cloud',                     'Docker, Kubernetes, CI/CD y servicios cloud.',       'estudio'),
    (1,  'Grupo de Bases de Datos',            'Repaso de SQL, modelado y optimización.',            'estudio'),
    (7,  'Emprendedores Pascualina',           'Ideas de negocio, pitches y networking.',            'club'),
    (3,  'Diseño UX/UI',                       'Prototipado, research y diseño de interfaces.',      'club'),
    (8,  'Seguridad Informática',              'CTFs, hacking ético y criptografía aplicada.',       'club'),
    (2,  'Hackaton 2025',                      'Equipo para el hackaton de innovación social 2025.', 'hackaton');

-- ============================================================
-- MIEMBROS DE GRUPOS
-- ============================================================
INSERT INTO miembros_grupo (id_grupo, id_usuario, rol) VALUES
    (1, 10,'admin'),  (1, 6,'miembro'), (1, 9,'miembro'), (1, 8,'miembro'), (1, 1,'miembro'),
    (2, 5, 'admin'),  (2, 1,'miembro'), (2, 2,'miembro'), (2, 9,'miembro'),
    (3, 4, 'admin'),  (3, 2,'miembro'), (3, 8,'miembro'),
    (4, 1, 'admin'),  (4, 2,'miembro'), (4, 5,'miembro'), (4, 9,'miembro'), (4, 6,'miembro'),
    (5, 7, 'admin'),  (5, 3,'miembro'), (5, 6,'miembro'),
    (6, 3, 'admin'),  (6, 1,'miembro'), (6, 7,'miembro'),
    (7, 8, 'admin'),  (7, 4,'miembro'), (7, 9,'miembro'), (7, 10,'miembro'),
    (8, 2, 'admin'),  (8, 1,'miembro'), (8, 4,'miembro'), (8, 5,'miembro');

-- ============================================================
-- EVENTOS
-- ============================================================
INSERT INTO eventos (id_organizador, titulo, descripcion, tipo, fecha_evento, lugar, capacidad_max) VALUES
    (4,  'Taller de Docker y Kubernetes',       'Introducción práctica a contenedores.',          'taller', '2025-07-15 10:00', 'Sala B-201', 30),
    (10, 'Simulacro ICPC Regional',             'Competencia simulada de 5 horas.',               'estudio', '2025-07-20 08:00', 'Lab C-105',  20),
    (5,  'Workshop Machine Learning con Python','Desde regresión hasta redes neuronales.',        'taller', '2025-08-05 14:00', 'Aula 310',   25),
    (1,  'Sesión de Repaso SQL',                'Repaso grupal de consultas y optimización.',     'estudio', '2025-07-10 16:00', 'Online',     50),
    (7,  'Pitch Night Pascualina',              'Presenta tu idea de negocio en 3 minutos.',      'social',  '2025-08-12 18:00', 'Auditorio',  100),
    (8,  'CTF Introductorio',                   'Capture The Flag para principiantes.',           'taller', '2025-07-25 09:00', 'Lab C-202',  20),
    (3,  'Meetup UX/UI Design',                 'Revisión de portafolios y feedback colectivo.',  'social',  '2025-08-01 15:00', 'Sala Diseño', 20),
    (2,  'Kick-off Hackaton 2025',              'Reunión inicial del equipo para el hackaton.',   'estudio', '2025-07-08 17:00', 'Online',     10);

-- ============================================================
-- PARTICIPANTES EN EVENTOS (distintos al organizador)
-- ============================================================
INSERT INTO participantes_evento (id_evento, id_usuario, estado) VALUES
    (1, 2,'confirmado'), (1, 8,'confirmado'), (1, 1,'inscrito'),  (1, 5,'inscrito'),
    (2, 6,'confirmado'), (2, 9,'confirmado'), (2, 1,'inscrito'),  (2, 8,'inscrito'),
    (3, 1,'confirmado'), (3, 2,'inscrito'),   (3, 9,'inscrito'),
    (4, 2,'confirmado'), (4, 5,'confirmado'), (4, 6,'inscrito'),  (4, 9,'inscrito'), (4, 10,'inscrito'),
    (5, 1,'inscrito'),   (5, 2,'inscrito'),   (5, 3,'confirmado'),(5, 6,'inscrito'),
    (6, 4,'confirmado'), (6, 9,'inscrito'),   (6, 10,'inscrito'),
    (7, 1,'inscrito'),   (7, 6,'inscrito'),
    (8, 1,'confirmado'), (8, 4,'confirmado'), (8, 5,'inscrito');

-- ============================================================
-- SERVICIOS
-- ============================================================
INSERT INTO servicios (id_ofertante, titulo, descripcion, categoria, precio) VALUES
    (2,  'Tutoría de PostgreSQL',         'Clases personalizadas de SQL y modelado.',         'tutoría',    25000.00),
    (5,  'Curso de Python para Datos',    'Pandas, NumPy y visualización en 8 sesiones.',     'curso',      80000.00),
    (4,  'Asesoría en Arquitectura SW',   'Revisión de diseño y buenas prácticas.',           'tutoría',    40000.00),
    (10, 'Entrenamiento Competitivo',     'Mentoría en algoritmos y estructuras de datos.',   'tutoría',    30000.00),
    (3,  'Diseño de Logo',                'Diseño de identidad visual para tu proyecto.',     'cambalache',  0.00),
    (8,  'Auditoría de Seguridad Básica', 'Revisión de vulnerabilidades en apps web.',        'curso',      50000.00),
    (1,  'Consultoría BD',                'Optimización de consultas SQL y modelo de datos.',  'tutoría',   35000.00),
    (7,  'Mentoría en Emprendimiento',    'Validación de idea, lean canvas y pitch.',         'curso',      20000.00);

-- ============================================================
-- TRANSACCIONES DE SERVICIOS
-- ============================================================
INSERT INTO transacciones_servicio (id_servicio, id_comprador, monto_pagado, estado) VALUES
    (1, 1,  25000.00, 'completada'),
    (1, 6,  25000.00, 'completada'),
    (2, 1,  80000.00, 'completada'),
    (2, 9,  80000.00, 'completada'),
    (3, 2,  40000.00, 'completada'),
    (4, 6,  30000.00, 'completada'),
    (4, 1,  30000.00, 'pendiente'),
    (6, 4,  50000.00, 'completada'),
    (7, 6,  35000.00, 'completada'),
    (8, 3,  20000.00, 'completada');

-- ============================================================
-- PRODUCTOS
-- ============================================================
INSERT INTO productos (id_vendedor, nombre, descripcion, categoria, precio, stock) VALUES
    (2,  'Libro: Clean Code',               'Robert C. Martin, edición 2008, buen estado.',   'libro',      25000.00, 1),
    (4,  'Teclado Mecánico Redragon',       'Switch azul, usado 6 meses.',                    'tecnología', 90000.00, 1),
    (5,  'Fundamentos de ML - Aurélien',    'Libro en perfecto estado.',                      'libro',      45000.00, 1),
    (9,  'Álgebra Lineal - Grossman',       'Libro con notas y subrayados propios.',          'libro',      15000.00, 1),
    (10, 'Mouse Logitech G203',             'Mouse gaming, usado 1 año, funciona perfecto.',  'tecnología', 35000.00, 1),
    (3,  'Pack de Íconos UI (licencia)',    'Set premium de 2000 íconos vectoriales.',        'tecnología',  8000.00, 5),
    (7,  'Camiseta "I code therefore I am"','Talla M, algodón, nueva.',                      'ropa',       18000.00, 2),
    (1,  'Raspberry Pi 4 (4GB)',            'Con carcasa y fuente, en perfecto estado.',      'tecnología',150000.00, 1);

-- ============================================================
-- TRANSACCIONES DE PRODUCTOS
-- ============================================================
INSERT INTO transacciones_producto (id_producto, id_comprador, cantidad, monto_total, estado) VALUES
    (1, 6,  1, 25000.00,  'completada'),
    (3, 1,  1, 45000.00,  'completada'),
    (5, 9,  1, 35000.00,  'completada'),
    (6, 1,  2, 16000.00,  'completada'),
    (6, 3,  1,  8000.00,  'completada'),
    (7, 6,  1, 18000.00,  'pendiente'),
    (4, 2,  1, 90000.00,  'completada'),
    (2, 5,  1, 25000.00,  'pendiente');

-- ============================================================
-- FIN DEL SCRIPT DE POBLAMIENTO
-- ============================================================

--

-- 1. Datos para Big Data en Usuarios
ALTER TABLE usuarios ADD COLUMN perfil_usuario JSONB;

INSERT INTO usuarios (nombre, correo, perfil_usuario) 
VALUES ('Julian Mesa', 'j.mesa@pascual.edu.co', 
'{"intereses": ["Sistemas", "IA"], "idiomas": [{"ingles": "B2"}, {"aleman": "A1"}]}');

-- 2. Datos para IoT en Publicaciones (Telemetría)
ALTER TABLE publicaciones ADD COLUMN metadatos_dispositivo JSONB;

INSERT INTO publicaciones (id_usuario, contenido, metadatos_dispositivo)
VALUES (1, 'Iniciando sesión en laboratorio', 
'{"dispositivo": "Sensor_Aula_102", "geolocalización": {"lat": 6.24, "long": -75.58}, "ip": "192.168.1.45"}');

-- 3. Consultas
SELECT nombre, perfil_usuario->>'intereses' as intereses FROM usuarios;
SELECT contenido FROM publicaciones WHERE metadatos_dispositivo->>'dispositivo' = 'Sensor_Aula_102';
-- SGBD: MySQL

-- 1. Tabla Independiente: PROGRAMAS
CREATE TABLE programas_academicos (
    id_programa INT AUTO_INCREMENT PRIMARY KEY,
    nombre_programa VARCHAR(100) NOT NULL,
    facultad VARCHAR(100)
) ENGINE=InnoDB;

-- 2. Tabla Independiente: USUARIOS
CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre_completo VARCHAR(100) NOT NULL,
    correo_institucional VARCHAR(100) UNIQUE NOT NULL,
    id_programa INT,
    tipo_usuario VARCHAR(20) DEFAULT 'estudiante',
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuario_programa FOREIGN KEY (id_programa) 
        REFERENCES programas_academicos(id_programa)
) ENGINE=InnoDB;

-- 3. Tabla Dependiente: PUBLICACIONES
CREATE TABLE publicaciones (
    id_publicacion INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    contenido TEXT NOT NULL,
    url_recurso VARCHAR(255),
    fecha_publicacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pub_usuario FOREIGN KEY (id_usuario) 
        REFERENCES usuarios(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4. Tabla Dependiente: COMENTARIOS
CREATE TABLE comentarios (
    id_comentario INT AUTO_INCREMENT PRIMARY KEY,
    id_publicacion INT NOT NULL,
    id_usuario INT NOT NULL,
    texto_comentario TEXT NOT NULL,
    fecha_comentario DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_com_publicacion FOREIGN KEY (id_publicacion) 
        REFERENCES publicaciones(id_publicacion) ON DELETE CASCADE,
    CONSTRAINT fk_com_usuario FOREIGN KEY (id_usuario) 
        REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB;

-- 5. Tablas para Grupos
CREATE TABLE grupos_estudio (
    id_grupo INT AUTO_INCREMENT PRIMARY KEY,
    nombre_grupo VARCHAR(100) NOT NULL,
    descripcion TEXT
) ENGINE=InnoDB;

CREATE TABLE miembros_grupo (
    id_usuario INT NOT NULL,
    id_grupo INT NOT NULL,
    rol VARCHAR(50) DEFAULT 'miembro',
    PRIMARY KEY (id_usuario, id_grupo),
    CONSTRAINT fk_m_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    CONSTRAINT fk_m_grupo FOREIGN KEY (id_grupo) REFERENCES grupos_estudio(id_grupo)
) ENGINE=InnoDB;
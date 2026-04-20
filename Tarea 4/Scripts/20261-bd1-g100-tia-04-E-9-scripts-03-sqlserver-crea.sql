-- SGBD: MS SQL Server

-- 1. Tabla Independiente: PROGRAMAS
CREATE TABLE programas_academicos (
    id_programa INT IDENTITY(1,1) PRIMARY KEY,
    nombre_programa NVARCHAR(100) NOT NULL,
    facultad NVARCHAR(100)
);

-- 2. Tabla Independiente: USUARIOS
CREATE TABLE usuarios (
    id_usuario INT IDENTITY(1,1) PRIMARY KEY,
    nombre_completo NVARCHAR(100) NOT NULL,
    correo_institucional NVARCHAR(100) UNIQUE NOT NULL,
    id_programa INT,
    tipo_usuario NVARCHAR(20) DEFAULT 'estudiante',
    fecha_registro DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Usuario_Programa FOREIGN KEY (id_programa) 
        REFERENCES programas_academicos(id_programa)
);

-- 3. Tabla Dependiente: PUBLICACIONES
CREATE TABLE publicaciones (
    id_publicacion INT IDENTITY(1,1) PRIMARY KEY,
    id_usuario INT NOT NULL,
    contenido NVARCHAR(MAX) NOT NULL,
    url_recurso NVARCHAR(255),
    fecha_publicacion DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Pub_Usuario FOREIGN KEY (id_usuario) 
        REFERENCES usuarios(id_usuario) ON DELETE CASCADE
);

-- 4. Tabla Dependiente: COMENTARIOS
CREATE TABLE comentarios (
    id_comentario INT IDENTITY(1,1) PRIMARY KEY,
    id_publicacion INT NOT NULL,
    id_usuario INT NOT NULL,
    texto_comentario NVARCHAR(MAX) NOT NULL,
    fecha_comentario DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Com_Publicacion FOREIGN KEY (id_publicacion) 
        REFERENCES publicaciones(id_publicacion) ON DELETE CASCADE,
    CONSTRAINT FK_Com_Usuario FOREIGN KEY (id_usuario) 
        REFERENCES usuarios(id_usuario)
);

-- 5. Tablas para Grupos
CREATE TABLE grupos_estudio (
    id_grupo INT IDENTITY(1,1) PRIMARY KEY,
    nombre_grupo NVARCHAR(100) NOT NULL,
    descripcion NVARCHAR(MAX)
);

CREATE TABLE miembros_grupo (
    id_usuario INT NOT NULL,
    id_grupo INT NOT NULL,
    rol NVARCHAR(50) DEFAULT 'miembro',
    PRIMARY KEY (id_usuario, id_grupo),
    CONSTRAINT FK_M_Usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    CONSTRAINT FK_M_Grupo FOREIGN KEY (id_grupo) REFERENCES grupos_estudio(id_grupo)
);
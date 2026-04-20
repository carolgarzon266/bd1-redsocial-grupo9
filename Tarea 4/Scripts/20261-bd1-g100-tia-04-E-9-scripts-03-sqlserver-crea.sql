CREATE TABLE publicacion (
    id_publicacion INT IDENTITY(1,1) PRIMARY KEY,
    id_usuario INT,
    contenido NVARCHAR(MAX),
    metadatos_iot NVARCHAR(MAX), -- Almacena JSON con restricción ISJSON
    CONSTRAINT FK_Usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);


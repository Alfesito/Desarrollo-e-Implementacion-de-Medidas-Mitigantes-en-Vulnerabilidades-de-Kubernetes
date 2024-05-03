-- Crear base de datos
CREATE DATABASE IF NOT EXISTS datos_usuarios;

-- Seleccionar la base de datos
USE datos_usuarios;

-- Crear tabla para datos personales (GDPR)
CREATE TABLE IF NOT EXISTS datos_personales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    apellido VARCHAR(100),
    email VARCHAR(255),
    telefono VARCHAR(20),
    direccion VARCHAR(255)
);

-- Insertar datos de usuarios
INSERT INTO datos_personales (nombre, apellido, email, telefono, direccion) VALUES
('Juan', 'Pérez', 'juan.perez@example.com', '123456789', 'Calle Principal 123'),
('María', 'García', 'maria.garcia@example.com', '987654321', 'Avenida Central 456'),
('Roberto', 'Rodríguez', 'roberto.rodriguez@example.com', '555555555', 'Calle Secundaria 789'),
('Ana', 'Martínez', 'ana.martinez@example.com', '777777777', 'Plaza Mayor 101'),
('David', 'Fernández', 'david.fernandez@example.com', '999999999', 'Paseo de la Libertad 222'),
('Laura', 'López', 'laura.lopez@example.com', '111111111', 'Calle Ancha 333'),
('Carlos', 'Sánchez', 'carlos.sanchez@example.com', '333333333', 'Avenida Reforma 444'),
('Sandra', 'Gómez', 'sandra.gomez@example.com', '444444444', 'Carrera 5ta 555'),
('Daniel', 'Pérez', 'daniel.perez@example.com', '666666666', 'Calle del Sol 666'),
('Marta', 'González', 'marta.gonzalez@example.com', '888888888', 'Avenida del Mar 777');

-- Crear tabla para información de tarjetas de pago (PCI DSS)
CREATE TABLE IF NOT EXISTS tarjetas_pago (
    id INT AUTO_INCREMENT PRIMARY KEY,
    numero_tarjeta VARCHAR(20),
    nombre_tarjeta VARCHAR(100),
    fecha_expiracion DATE,
    codigo_seguridad VARCHAR(4),
    usuario_id INT,
    FOREIGN KEY (usuario_id) REFERENCES datos_personales(id)
);

-- Insertar datos de tarjetas de pago
INSERT INTO tarjetas_pago (numero_tarjeta, nombre_tarjeta, fecha_expiracion, codigo_seguridad, usuario_id) VALUES
('1234567890123456', 'Juan Pérez', '2025-12-31', '123', 1),
('9876543210987654', 'María García', '2024-11-30', '456', 2),
('4567890123456789', 'Roberto Rodríguez', '2023-10-31', '789', 3),
('7890123456789012', 'Ana Martínez', '2022-09-30', '012', 4),
('3456789012345678', 'David Fernández', '2025-08-31', '345', 5),
('9012345678901234', 'Laura López', '2024-07-31', '678', 6),
('5678901234567890', 'Carlos Sánchez', '2023-06-30', '901', 7),
('2345678901234567', 'Sandra Gómez', '2022-05-31', '234', 8),
('6789012345678901', 'Daniel Pérez', '2025-04-30', '567', 9),
('0123456789012345', 'Marta González', '2024-03-31', '890', 10);

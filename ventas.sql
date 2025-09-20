-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 21-09-2025 a las 01:38:09
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `ventas`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_asignar_distrito_defecto` ()   BEGIN
    DECLARE primer_distrito INT;
    
    -- Obtener el ID del primer distrito
    SELECT id_distrito INTO primer_distrito FROM Distrito ORDER BY id_distrito LIMIT 1;
    
    -- Actualizar vendedores sin distrito
    UPDATE Vendedor SET id_distrito = primer_distrito WHERE id_distrito IS NULL;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_buscar_por_tipo_paginado` (IN `p_search` VARCHAR(50), IN `p_tipo` VARCHAR(20), IN `p_limite` INT, IN `p_offset` INT)   BEGIN
    IF p_search IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El término de búsqueda no puede estar vacío';
    END IF;
    
    CASE p_tipo
        WHEN 'nombre' THEN
            SELECT 
                v.*,
                COALESCE(d.nombre, 'Sin distrito') as distrito
            FROM Vendedor v
            LEFT JOIN Distrito d ON v.id_distrito = d.id_distrito
            WHERE v.nom_ven LIKE CONCAT('%', p_search, '%')
            ORDER BY v.id_ven
            LIMIT p_limite OFFSET p_offset;
            
            -- Total de registros filtrados
            SELECT COUNT(*) as total 
            FROM Vendedor 
            WHERE nom_ven LIKE CONCAT('%', p_search, '%');
            
        WHEN 'apellido' THEN
            SELECT 
                v.*,
                COALESCE(d.nombre, 'Sin distrito') as distrito
            FROM Vendedor v
            LEFT JOIN Distrito d ON v.id_distrito = d.id_distrito
            WHERE v.ape_ven LIKE CONCAT('%', p_search, '%')
            ORDER BY v.id_ven
            LIMIT p_limite OFFSET p_offset;
            
            -- Total de registros filtrados
            SELECT COUNT(*) as total 
            FROM Vendedor 
            WHERE ape_ven LIKE CONCAT('%', p_search, '%');
            
        WHEN 'distrito' THEN
            SELECT 
                v.*,
                COALESCE(d.nombre, 'Sin distrito') as distrito
            FROM Vendedor v
            LEFT JOIN Distrito d ON v.id_distrito = d.id_distrito
            WHERE d.nombre LIKE CONCAT('%', p_search, '%')
            ORDER BY v.id_ven
            LIMIT p_limite OFFSET p_offset;
            
            -- Total de registros filtrados
            SELECT COUNT(*) as total 
            FROM Vendedor v
            LEFT JOIN Distrito d ON v.id_distrito = d.id_distrito
            WHERE d.nombre LIKE CONCAT('%', p_search, '%');
            
        WHEN 'celular' THEN
            SELECT 
                v.*,
                COALESCE(d.nombre, 'Sin distrito') as distrito
            FROM Vendedor v
            LEFT JOIN Distrito d ON v.id_distrito = d.id_distrito
            WHERE v.cel_ven LIKE CONCAT('%', p_search, '%')
            ORDER BY v.id_ven
            LIMIT p_limite OFFSET p_offset;
            
            -- Total de registros filtrados
            SELECT COUNT(*) as total 
            FROM Vendedor 
            WHERE cel_ven LIKE CONCAT('%', p_search, '%');
            
        ELSE
            -- Por defecto buscar en todos los campos
            CALL sp_searchven_paginado(p_search, p_limite, p_offset);
    END CASE;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_busven` (IN `p_id_ven` INT)   BEGIN
    IF NOT EXISTS (SELECT 1 FROM Vendedor WHERE id_ven = p_id_ven) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El vendedor especificado no existe';
    END IF;
    
select
 v.id_ven, v.nom_ven, v.ape_ven,v.cel_ven,d.nombre, e.nom_esp
from vendedor v inner join distrito d on v.id_distrito = d.id_distrito inner join especialidad e on v.id_esp = e.id_esp

    WHERE v.id_ven = p_id_ven;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_busven_paginado` (IN `p_id_ven` INT, IN `p_limite` INT, IN `p_offset` INT)   BEGIN
select
 v.id_ven, v.nom_ven, v.ape_ven,v.cel_ven,d.nombre, e.nom_esp
from vendedor v inner join distrito d on v.id_distrito = d.id_distrito inner join especialidad e on v.id_esp = e.id_esp

    WHERE v.id_ven = p_id_ven
    LIMIT p_limite OFFSET p_offset;
    
    -- Segunda consulta para obtener el total de registros filtrados
    SELECT COUNT(*) as total FROM Vendedor WHERE id_ven = p_id_ven;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_contar_vendedores` ()   BEGIN
    SELECT COUNT(*) as total FROM Vendedor;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_delven` (IN `p_id_ven` INT)   BEGIN
    DECLARE vendedor_exists INT;
    
    -- Validar que el vendedor existe
    SELECT COUNT(*) INTO vendedor_exists FROM Vendedor WHERE id_ven = p_id_ven;
    IF vendedor_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El vendedor especificado no existe';
    END IF;
    
    DELETE FROM Vendedor WHERE id_ven = p_id_ven;
    
    -- Opción para reordenar IDs (comentar si no se desea esta funcionalidad)
    -- SET @num := 0;
    -- UPDATE Vendedor SET id_ven = @num := (@num + 1) ORDER BY id_ven;
    -- ALTER TABLE Vendedor AUTO_INCREMENT = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ingven` (IN `p_nom_ven` VARCHAR(25), IN `p_ape_ven` VARCHAR(25), IN `p_cel_ven` CHAR(9), IN `p_id_distrito` INT, IN `p_id_esp` INT)   BEGIN
    DECLARE distrito_exists INT;
    
    -- Validar datos no nulos
    IF p_nom_ven IS NULL OR p_ape_ven IS NULL OR p_cel_ven IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Todos los campos son obligatorios';
    END IF;
    
    -- Validar longitud del celular
    IF LENGTH(p_cel_ven) != 9 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El número de celular debe tener exactamente 9 dígitos';
    END IF;
    
    -- Validar que el distrito existe
    IF p_id_distrito IS NOT NULL THEN
        SELECT COUNT(*) INTO distrito_exists FROM Distrito WHERE id_distrito = p_id_distrito;
        IF distrito_exists = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El distrito especificado no existe';
        END IF;
    END IF;
    
    INSERT INTO Vendedor(nom_ven, ape_ven, cel_ven, id_distrito, id_esp)
    VALUES (p_nom_ven, p_ape_ven, p_cel_ven, p_id_distrito, p_id_esp);
    
    SELECT LAST_INSERT_ID() AS id_vendedor;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_lisdistritos` ()   BEGIN
    SELECT * FROM Distrito ORDER BY nombre;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_lisespecialidades` ()   BEGIN
    SELECT * FROM Especialidad ORDER BY nom_esp;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_lisven` ()   BEGIN
select
 v.id_ven, v.nom_ven, v.ape_ven,v.cel_ven,d.nombre, e.nom_esp
from vendedor v inner join distrito d on v.id_distrito = d.id_distrito inner join especialidad e on v.id_esp = e.id_esp

    ORDER BY v.id_ven;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_lisven_paginado` (IN `p_limite` INT, IN `p_offset` INT)   BEGIN
select
 v.id_ven, v.nom_ven, v.ape_ven,v.cel_ven,d.nombre, e.nom_esp
from vendedor v inner join distrito d on v.id_distrito = d.id_distrito inner join especialidad e on v.id_esp = e.id_esp
    ORDER BY v.id_ven
    LIMIT p_limite OFFSET p_offset;
    
    -- Segunda consulta para obtener el total de registros
    SELECT COUNT(*) as total FROM Vendedor;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_modven` (IN `p_id_ven` INT, IN `p_nom_ven` VARCHAR(25), IN `p_ape_ven` VARCHAR(25), IN `p_cel_ven` CHAR(9), IN `p_id_distrito` INT, IN `p_id_esp` INT)   BEGIN
    DECLARE vendedor_exists INT;
    DECLARE distrito_exists INT;
    
    -- Validar que el vendedor existe
    SELECT COUNT(*) INTO vendedor_exists FROM Vendedor WHERE id_ven = p_id_ven;
    IF vendedor_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El vendedor especificado no existe';
    END IF;
    
    -- Validar datos no nulos
    IF p_nom_ven IS NULL OR p_ape_ven IS NULL OR p_cel_ven IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Todos los campos son obligatorios';
    END IF;
    
    -- Validar longitud del celular
    IF LENGTH(p_cel_ven) != 9 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El número de celular debe tener exactamente 9 dígitos';
    END IF;
    
    -- Validar que el distrito existe si se proporciona
    IF p_id_distrito IS NOT NULL THEN
        SELECT COUNT(*) INTO distrito_exists FROM Distrito WHERE id_distrito = p_id_distrito;
        IF distrito_exists = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El distrito especificado no existe';
        END IF;
    END IF;
    
    UPDATE Vendedor 
    SET nom_ven = p_nom_ven,
        ape_ven = p_ape_ven,
        cel_ven = p_cel_ven,
        id_distrito = p_id_distrito,
id_esp = p_id_esp
    WHERE id_ven = p_id_ven;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_searchven` (IN `p_search` VARCHAR(50))   BEGIN
    IF p_search IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El término de búsqueda no puede estar vacío';
    END IF;
    
select
 v.id_ven, v.nom_ven, v.ape_ven,v.cel_ven,d.nombre, e.nom_esp
from vendedor v inner join distrito d on v.id_distrito = d.id_distrito inner join especialidad e on v.id_esp = e.id_esp

    WHERE v.nom_ven LIKE CONCAT('%', p_search, '%')
       OR v.ape_ven LIKE CONCAT('%', p_search, '%')
       OR d.nombre LIKE CONCAT('%', p_search, '%')
       OR v.cel_ven LIKE CONCAT('%', p_search, '%')
    ORDER BY v.id_ven;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_searchven_paginado` (IN `p_search` VARCHAR(50), IN `p_limite` INT, IN `p_offset` INT)   BEGIN
    IF p_search IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El término de búsqueda no puede estar vacío';
    END IF;
    
select
 v.id_ven, v.nom_ven, v.ape_ven,v.cel_ven,d.nombre, e.nom_esp
from vendedor v inner join distrito d on v.id_distrito = d.id_distrito inner join especialidad e on v.id_esp = e.id_esp

    WHERE v.nom_ven LIKE CONCAT('%', p_search, '%')
       OR v.ape_ven LIKE CONCAT('%', p_search, '%')
       OR d.nombre LIKE CONCAT('%', p_search, '%')
       OR v.cel_ven LIKE CONCAT('%', p_search, '%')
    ORDER BY v.id_ven
    LIMIT p_limite OFFSET p_offset;
    
    -- Segunda consulta para obtener el total de registros filtrados
    SELECT COUNT(*) as total 
    FROM Vendedor v
    LEFT JOIN Distrito d ON v.id_distrito = d.id_distrito
    WHERE v.nom_ven LIKE CONCAT('%', p_search, '%')
       OR v.ape_ven LIKE CONCAT('%', p_search, '%')
       OR d.nombre LIKE CONCAT('%', p_search, '%')
       OR v.cel_ven LIKE CONCAT('%', p_search, '%');
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `distrito`
--

CREATE TABLE `distrito` (
  `id_distrito` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `distrito`
--

INSERT INTO `distrito` (`id_distrito`, `nombre`) VALUES
(1, 'San Juan de Lurigancho'),
(2, 'San Martín de Porres'),
(3, 'Ate'),
(4, 'Comas'),
(5, 'Villa El Salvador'),
(6, 'Villa María del Triunfo'),
(7, 'San Juan de Miraflores'),
(8, 'Los Olivos'),
(9, 'Puente Piedra'),
(10, 'Santiago de Surco');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `especialidad`
--

CREATE TABLE `especialidad` (
  `id_esp` int(11) NOT NULL,
  `nom_esp` varchar(25) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `especialidad`
--

INSERT INTO `especialidad` (`id_esp`, `nom_esp`) VALUES
(1, 'Motores'),
(2, 'Tractores'),
(3, 'Niveladoras'),
(4, 'Moledoras');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vendedor`
--

CREATE TABLE `vendedor` (
  `id_ven` int(11) NOT NULL,
  `nom_ven` varchar(25) NOT NULL,
  `ape_ven` varchar(25) NOT NULL,
  `cel_ven` char(9) NOT NULL,
  `id_distrito` int(11) DEFAULT NULL,
  `id_esp` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `vendedor`
--

INSERT INTO `vendedor` (`id_ven`, `nom_ven`, `ape_ven`, `cel_ven`, `id_distrito`, `id_esp`) VALUES
(1, 'Mariana', 'Flores', '999999999', 10, 4);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `distrito`
--
ALTER TABLE `distrito`
  ADD PRIMARY KEY (`id_distrito`);

--
-- Indices de la tabla `especialidad`
--
ALTER TABLE `especialidad`
  ADD PRIMARY KEY (`id_esp`);

--
-- Indices de la tabla `vendedor`
--
ALTER TABLE `vendedor`
  ADD PRIMARY KEY (`id_ven`),
  ADD KEY `id_distrito` (`id_distrito`),
  ADD KEY `fk_vendedor_especialidad` (`id_esp`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `distrito`
--
ALTER TABLE `distrito`
  MODIFY `id_distrito` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT de la tabla `especialidad`
--
ALTER TABLE `especialidad`
  MODIFY `id_esp` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `vendedor`
--
ALTER TABLE `vendedor`
  MODIFY `id_ven` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `vendedor`
--
ALTER TABLE `vendedor`
  ADD CONSTRAINT `fk_vendedor_especialidad` FOREIGN KEY (`id_esp`) REFERENCES `especialidad` (`id_esp`),
  ADD CONSTRAINT `vendedor_ibfk_1` FOREIGN KEY (`id_distrito`) REFERENCES `distrito` (`id_distrito`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

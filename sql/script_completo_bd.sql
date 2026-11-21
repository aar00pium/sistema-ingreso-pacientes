-- =====================================================================
--  SCRIPT COMPLETO - Sistema de Ingreso de Pacientes
--  Centro Odontológico - Base de datos bd_ingreso_odontologico (MySQL 8.0)
--
--  Crea la base desde cero con todos sus objetos y datos de prueba.
--  Ejecutar completo con el usuario root en MySQL Workbench.
--  Contenido, en el orden en que debe ejecutarse:
--    1. 01_creacion_bd.sql
--    2. 11_estructura_entrega5.sql
--    3. 02_insercion_datos.sql
--    4. 14_datos_ampliados.sql
--    5. 09_funciones_procedimientos.sql
--    6. 10_procedimientos_crud.sql
--    7. 12_catalogos_reportes.sql
--    8. 13_triggers_auditoria.sql
--    9. 08_usuario_aplicativo.sql
--  ATENCIÓN: el primer bloque borra la base si ya existe.
-- =====================================================================



-- #####################################################################
-- ##  01_creacion_bd.sql
-- #####################################################################

-- =====================================================================
--  Script 1 - Creación de la base de datos
--  Sistema de Ingreso de Pacientes - Centro Odontológico UCSM
--  Gestor: MySQL 8.0 (motor InnoDB). Ejecutar en MySQL Workbench.
-- =====================================================================

SET NAMES utf8mb4;

DROP DATABASE IF EXISTS bd_ingreso_odontologico;
CREATE DATABASE bd_ingreso_odontologico
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE bd_ingreso_odontologico;

-- ---------------------------------------------------------------------
-- Tablas de catálogo
-- ---------------------------------------------------------------------
CREATE TABLE paciente (
    dni        CHAR(8)      NOT NULL,
    nombre     VARCHAR(60)  NOT NULL,
    condicion  VARCHAR(8)   NOT NULL,
    CONSTRAINT pk_paciente PRIMARY KEY (dni),
    CONSTRAINT ck_paciente_dni CHECK (REGEXP_LIKE(dni, '^[0-9]{8}$')),
    CONSTRAINT ck_paciente_condicion CHECK (condicion COLLATE utf8mb4_bin IN ('Adulto', 'Niño', 'Prenatal'))
) ENGINE = InnoDB COMMENT = 'Pacientes atendidos en el Centro Odontológico';

CREATE TABLE sillon (
    codigo_sillon  VARCHAR(3)  NOT NULL,
    piso           SMALLINT    NOT NULL,
    CONSTRAINT pk_sillon PRIMARY KEY (codigo_sillon),
    CONSTRAINT ck_sillon_codigo CHECK (REGEXP_LIKE(codigo_sillon, '^[A-Z][0-9]{1,2}$', 'c')),
    CONSTRAINT ck_sillon_piso CHECK (piso BETWEEN 1 AND 3)
) ENGINE = InnoDB COMMENT = 'Sillones odontológicos por piso';

CREATE TABLE sala (
    codigo_sala  SMALLINT     NOT NULL,
    nombre_sala  VARCHAR(30)  NOT NULL,
    CONSTRAINT pk_sala PRIMARY KEY (codigo_sala),
    CONSTRAINT ck_sala_codigo CHECK (codigo_sala BETWEEN 1 AND 99)
) ENGINE = InnoDB COMMENT = 'Salas especializadas: Cirugía y Diagnóstico/Radiología';

CREATE TABLE alumno (
    codigo_alumno  VARCHAR(10)  NOT NULL,
    codigo_qr      VARCHAR(10)  NOT NULL,
    nombre         VARCHAR(60)  NOT NULL,
    CONSTRAINT pk_alumno PRIMARY KEY (codigo_alumno),
    CONSTRAINT uq_alumno_qr UNIQUE (codigo_qr),
    CONSTRAINT ck_alumno_codigo CHECK (REGEXP_LIKE(codigo_alumno, '^[0-9]{1,10}$'))
) ENGINE = InnoDB COMMENT = 'Alumnos tratantes con su código QR de acceso';

CREATE TABLE personal (
    codigo_personal  SMALLINT     NOT NULL,
    nombre           VARCHAR(60)  NOT NULL,
    CONSTRAINT pk_personal PRIMARY KEY (codigo_personal),
    CONSTRAINT ck_personal_codigo CHECK (codigo_personal BETWEEN 1 AND 9999)
) ENGINE = InnoDB COMMENT = 'Personal de recepción que valida los ingresos';

CREATE TABLE doctor (
    codigo_doctor  SMALLINT     NOT NULL,
    nombre         VARCHAR(60)  NOT NULL,
    CONSTRAINT pk_doctor PRIMARY KEY (codigo_doctor),
    CONSTRAINT ck_doctor_codigo CHECK (codigo_doctor BETWEEN 1 AND 9999)
) ENGINE = InnoDB COMMENT = 'Doctores que supervisan los procedimientos';

-- ---------------------------------------------------------------------
-- Tablas de movimiento
-- ---------------------------------------------------------------------
CREATE TABLE programacion (
    codigo_programacion  VARCHAR(8)   NOT NULL,
    dia_semana           VARCHAR(9)   NOT NULL,
    bloque_horario       VARCHAR(11)  NOT NULL,
    asistencia           VARCHAR(10)  NULL,
    dni                  CHAR(8)      NOT NULL,
    codigo_sillon        VARCHAR(3)   NULL,
    CONSTRAINT pk_programacion PRIMARY KEY (codigo_programacion),
    CONSTRAINT fk_programacion_paciente FOREIGN KEY (dni)
        REFERENCES paciente (dni) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_programacion_sillon FOREIGN KEY (codigo_sillon)
        REFERENCES sillon (codigo_sillon) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT ck_programacion_codigo CHECK (REGEXP_LIKE(codigo_programacion, '^[0-9]{4,8}$')),
    CONSTRAINT ck_programacion_dia CHECK (dia_semana COLLATE utf8mb4_bin IN ('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado')),
    CONSTRAINT ck_programacion_bloque CHECK (
        REGEXP_LIKE(bloque_horario, '^([01][0-9]|2[0-3]):[0-5][0-9]-([01][0-9]|2[0-3]):[0-5][0-9]$')
        AND SUBSTRING(bloque_horario, 1, 5) < SUBSTRING(bloque_horario, 7, 5)),
    CONSTRAINT ck_programacion_asistencia CHECK (asistencia IS NULL OR asistencia COLLATE utf8mb4_bin IN ('Asistió', 'No asistió'))
) ENGINE = InnoDB COMMENT = 'Citas programadas de los pacientes';

CREATE TABLE ingreso (
    codigo_ingreso       VARCHAR(8)   NOT NULL,
    fecha                DATE         NOT NULL,
    hora_ingreso         TIME         NOT NULL,
    turno                VARCHAR(6)   NOT NULL,
    tipo_procedimiento   VARCHAR(30)  NULL,
    codigo_programacion  VARCHAR(8)   NOT NULL,
    codigo_alumno        VARCHAR(10)  NOT NULL,
    codigo_personal      SMALLINT     NOT NULL,
    codigo_sala          SMALLINT     NULL,
    codigo_doctor        SMALLINT     NULL,
    CONSTRAINT pk_ingreso PRIMARY KEY (codigo_ingreso),
    CONSTRAINT uq_ingreso_programacion UNIQUE (codigo_programacion),
    CONSTRAINT fk_ingreso_programacion FOREIGN KEY (codigo_programacion)
        REFERENCES programacion (codigo_programacion) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ingreso_alumno FOREIGN KEY (codigo_alumno)
        REFERENCES alumno (codigo_alumno) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ingreso_personal FOREIGN KEY (codigo_personal)
        REFERENCES personal (codigo_personal) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ingreso_sala FOREIGN KEY (codigo_sala)
        REFERENCES sala (codigo_sala) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ingreso_doctor FOREIGN KEY (codigo_doctor)
        REFERENCES doctor (codigo_doctor) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_ingreso_codigo CHECK (REGEXP_LIKE(codigo_ingreso, '^[0-9]{4,8}$')),
    CONSTRAINT ck_ingreso_turno CHECK (turno COLLATE utf8mb4_bin IN ('Mañana', 'Tarde'))
) ENGINE = InnoDB COMMENT = 'Evento de ingreso generado por una programación (1:1)';

CREATE TABLE permiso (
    codigo_ingreso  VARCHAR(8)   NOT NULL,
    hora_salida     TIME         NOT NULL,
    hora_retorno    TIME         NULL,
    motivo          VARCHAR(50)  NOT NULL,
    CONSTRAINT pk_permiso PRIMARY KEY (codigo_ingreso, hora_salida),
    CONSTRAINT fk_permiso_ingreso FOREIGN KEY (codigo_ingreso)
        REFERENCES ingreso (codigo_ingreso) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_permiso_retorno CHECK (hora_retorno IS NULL OR hora_retorno > hora_salida)
) ENGINE = InnoDB COMMENT = 'Salidas temporales del alumno durante un ingreso (entidad débil)';

CREATE TABLE esterilizacion (
    codigo_ingreso  VARCHAR(8)   NOT NULL,
    hora_inicio     TIME         NOT NULL,
    hora_fin        TIME         NULL,
    asistencia      VARCHAR(10)  NOT NULL,
    CONSTRAINT pk_esterilizacion PRIMARY KEY (codigo_ingreso, hora_inicio),
    CONSTRAINT fk_esterilizacion_ingreso FOREIGN KEY (codigo_ingreso)
        REFERENCES ingreso (codigo_ingreso) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_esterilizacion_fin CHECK (hora_fin IS NULL OR hora_fin > hora_inicio),
    CONSTRAINT ck_esterilizacion_asistencia CHECK (asistencia COLLATE utf8mb4_bin IN ('Asistió', 'No asistió'))
) ENGINE = InnoDB COMMENT = 'Ciclos de esterilización de instrumental por ingreso (entidad débil)';

-- ---------------------------------------------------------------------
-- Índices secundarios
-- ---------------------------------------------------------------------
CREATE INDEX ix_paciente_nombre      ON paciente (nombre);
CREATE INDEX ix_programacion_dni     ON programacion (dni);
CREATE INDEX ix_programacion_sillon  ON programacion (codigo_sillon);
CREATE INDEX ix_programacion_agenda  ON programacion (dia_semana, bloque_horario);
CREATE INDEX ix_ingreso_fecha_turno  ON ingreso (fecha, turno);
CREATE INDEX ix_ingreso_alumno       ON ingreso (codigo_alumno, fecha);
CREATE INDEX ix_ingreso_personal     ON ingreso (codigo_personal);
CREATE INDEX ix_ingreso_sala         ON ingreso (codigo_sala);
CREATE INDEX ix_ingreso_doctor       ON ingreso (codigo_doctor);
CREATE INDEX ix_permiso_abierto      ON permiso (codigo_ingreso, hora_retorno);
CREATE INDEX ix_esterilizacion_curso ON esterilizacion (codigo_ingreso, hora_fin);

-- ---------------------------------------------------------------------
-- Triggers: no se registra un procedimiento sin sala
-- (MySQL no permite un CHECK sobre codigo_sala porque tiene ON UPDATE CASCADE)
-- ---------------------------------------------------------------------
DELIMITER $$

CREATE TRIGGER trg_ingreso_bi
BEFORE INSERT ON ingreso
FOR EACH ROW
BEGIN
    IF NEW.tipo_procedimiento IS NOT NULL AND NEW.codigo_sala IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Si existe un tipo de procedimiento, se requiere obligatoriamente un código de sala.';
    END IF;
END$$

CREATE TRIGGER trg_ingreso_bu
BEFORE UPDATE ON ingreso
FOR EACH ROW
BEGIN
    IF NEW.tipo_procedimiento IS NOT NULL AND NEW.codigo_sala IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Si existe un tipo de procedimiento, se requiere obligatoriamente un código de sala.';
    END IF;
END$$

DELIMITER ;


-- #####################################################################
-- ##  11_estructura_entrega5.sql
-- #####################################################################

-- =====================================================================
--  Script 11 - Cambios de estructura para la entrega 5
--  Base de datos: bd_ingreso_odontologico (MySQL 8.0)
--  Ejecutar con root en Workbench, después de 01 y antes de 02.
--
--  1. Borrado lógico: columna activo (1 = activo, 0 = desactivado) en los
--     catálogos y en las citas. Los registros ya no se borran físicamente.
--  2. Tabla de auditoría: guarda cada INSERT, UPDATE y DELETE hecho sobre
--     las tablas del sistema (la llenan los triggers del script 13).
-- =====================================================================
SET NAMES utf8mb4;
USE bd_ingreso_odontologico;

-- ---------------------------------------------------------------------
-- 1. Columna activo para el borrado lógico
-- ---------------------------------------------------------------------
ALTER TABLE paciente
    ADD COLUMN activo TINYINT NOT NULL DEFAULT 1 COMMENT '1 = activo, 0 = desactivado (borrado lógico)',
    ADD CONSTRAINT ck_paciente_activo CHECK (activo IN (0, 1));

ALTER TABLE alumno
    ADD COLUMN activo TINYINT NOT NULL DEFAULT 1 COMMENT '1 = activo, 0 = desactivado (borrado lógico)',
    ADD CONSTRAINT ck_alumno_activo CHECK (activo IN (0, 1));

ALTER TABLE sillon
    ADD COLUMN activo TINYINT NOT NULL DEFAULT 1 COMMENT '1 = en servicio, 0 = fuera de servicio',
    ADD CONSTRAINT ck_sillon_activo CHECK (activo IN (0, 1));

ALTER TABLE sala
    ADD COLUMN activo TINYINT NOT NULL DEFAULT 1 COMMENT '1 = habilitada, 0 = deshabilitada',
    ADD CONSTRAINT ck_sala_activo CHECK (activo IN (0, 1));

ALTER TABLE personal
    ADD COLUMN activo TINYINT NOT NULL DEFAULT 1 COMMENT '1 = activo, 0 = desactivado (borrado lógico)',
    ADD CONSTRAINT ck_personal_activo CHECK (activo IN (0, 1));

ALTER TABLE doctor
    ADD COLUMN activo TINYINT NOT NULL DEFAULT 1 COMMENT '1 = activo, 0 = desactivado (borrado lógico)',
    ADD CONSTRAINT ck_doctor_activo CHECK (activo IN (0, 1));

ALTER TABLE programacion
    ADD COLUMN activo TINYINT NOT NULL DEFAULT 1 COMMENT '1 = vigente, 0 = cita eliminada (borrado lógico)',
    ADD CONSTRAINT ck_programacion_activo CHECK (activo IN (0, 1));

-- La agenda y la ocupación siempre filtran por citas vigentes
DROP INDEX ix_programacion_agenda ON programacion;
CREATE INDEX ix_programacion_agenda ON programacion (dia_semana, activo, bloque_horario);

-- ---------------------------------------------------------------------
-- 2. Tabla de auditoría
-- ---------------------------------------------------------------------
CREATE TABLE auditoria (
    id_auditoria  BIGINT       NOT NULL AUTO_INCREMENT,
    fecha_hora    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tabla         VARCHAR(20)  NOT NULL,
    operacion     VARCHAR(6)   NOT NULL,
    clave         VARCHAR(30)  NOT NULL,
    detalle       VARCHAR(255) NULL,
    usuario_bd    VARCHAR(80)  NOT NULL,
    personal      SMALLINT     NULL     COMMENT 'Personal de recepción que tenía el turno abierto',
    CONSTRAINT pk_auditoria PRIMARY KEY (id_auditoria),
    CONSTRAINT ck_auditoria_operacion CHECK (operacion COLLATE utf8mb4_bin IN ('INSERT', 'UPDATE', 'DELETE'))
) ENGINE = InnoDB COMMENT = 'Registro de operaciones sobre las tablas (llenado por triggers)';

CREATE INDEX ix_auditoria_fecha ON auditoria (fecha_hora);
CREATE INDEX ix_auditoria_tabla ON auditoria (tabla, clave);

-- Verificación
SELECT table_name AS tabla, column_name AS columna, column_default AS valor_por_defecto
FROM information_schema.columns
WHERE table_schema = 'bd_ingreso_odontologico' AND column_name = 'activo'
ORDER BY table_name;


-- #####################################################################
-- ##  02_insercion_datos.sql
-- #####################################################################

-- =====================================================================
--  Script 2 - Inserción de datos de ejemplo
--  Ejecutar después de 01_creacion_bd.sql
--  Semana de atención del 19 al 24 de octubre de 2026
-- =====================================================================
SET NAMES utf8mb4;
USE bd_ingreso_odontologico;

START TRANSACTION;

-- Catálogos
INSERT INTO sala (codigo_sala, nombre_sala) VALUES
    (1, 'Sala de Cirugía'),
    (2, 'Sala de Diagnóstico/Radiología');

INSERT INTO sillon (codigo_sillon, piso) VALUES
    ('A1', 1),
    ('A2', 1),
    ('B1', 1),
    ('B2', 1),
    ('C1', 2),
    ('C2', 2),
    ('D1', 2),
    ('D2', 2),
    ('E1', 2),
    ('E2', 2),
    ('F1', 3),
    ('F2', 3),
    ('G1', 3),
    ('G2', 3),
    ('H1', 3),
    ('H2', 3);

INSERT INTO personal (codigo_personal, nombre) VALUES
    (1, 'Torres Lima, Juan'),
    (2, 'Quispe Mamani, Rosa'),
    (3, 'Flores Apaza, Carmen'),
    (4, 'Huamán Ccori, Luis');

INSERT INTO doctor (codigo_doctor, nombre) VALUES
    (1, 'Dr. Fernández Rivera, Carlos'),
    (2, 'Dra. Salas Cornejo, Patricia'),
    (3, 'Dr. Medina Paredes, Jorge'),
    (4, 'Dra. Villena Rojas, Lucía'),
    (5, 'Dr. Chávez Núñez, Ricardo'),
    (6, 'Dra. Zegarra Pinto, Mónica');

INSERT INTO alumno (codigo_alumno, codigo_qr, nombre) VALUES
    ('2021248861', 'QR72623725', 'Pérez Rojas, Ana'),
    ('2021248902', 'QR72623801', 'Gutiérrez Lazo, Diego'),
    ('2021249013', 'QR72623877', 'Mendoza Arias, Valeria'),
    ('2021249145', 'QR72623954', 'Ramos Tito, Sebastián'),
    ('2022110236', 'QR72624030', 'Cáceres Vera, Daniela'),
    ('2022110378', 'QR72624107', 'Ortiz Benavente, Marco'),
    ('2022110419', 'QR72624183', 'Alvarado Puma, Camila'),
    ('2022110582', 'QR72624260', 'Núñez Herrera, Joaquín'),
    ('2022110647', 'QR72624336', 'Delgado Soto, Fernanda'),
    ('2022110793', 'QR72624412', 'Cornejo Ugarte, Renato');

INSERT INTO paciente (dni, nombre, condicion) VALUES
    ('71928723', 'García López, Luis', 'Adulto'),
    ('72015448', 'Mamani Condori, Elena', 'Adulto'),
    ('70833192', 'Huanca Ríos, Pedro', 'Adulto'),
    ('78450216', 'Vargas Peña, Sofía', 'Niño'),
    ('76129034', 'Lazo Gómez, Mateo', 'Niño'),
    ('73374581', 'Torres Ccama, María', 'Prenatal'),
    ('74480127', 'Chávez Lima, Rosa', 'Adulto'),
    ('71102938', 'Paredes Arce, Jorge', 'Adulto'),
    ('79210345', 'Apaza Quispe, Lucía', 'Niño'),
    ('70456721', 'Salinas Vera, Carmen', 'Prenatal'),
    ('72893014', 'Rojas Medina, Alberto', 'Adulto'),
    ('75610982', 'Flores Tapia, Daniel', 'Adulto'),
    ('77345120', 'Ccori Huamán, Andrea', 'Niño'),
    ('70981236', 'Benavides Soto, Raúl', 'Adulto'),
    ('73012457', 'Montes Ugarte, Gabriela', 'Prenatal');

-- Citas de la semana
INSERT INTO programacion (codigo_programacion, dia_semana, bloque_horario, asistencia, dni, codigo_sillon) VALUES
    ('10001001', 'Lunes', '08:00-10:00', 'Asistió', '71102938', 'C2'),
    ('10001002', 'Lunes', '10:00-12:00', 'Asistió', '73012457', 'F1'),
    ('10001003', 'Lunes', '14:00-16:00', 'Asistió', '74480127', NULL),
    ('10001004', 'Lunes', '16:00-18:00', 'Asistió', '70981236', 'C1'),
    ('10001005', 'Martes', '08:00-10:00', 'No asistió', '73374581', 'E2'),
    ('10001006', 'Martes', '10:00-12:00', 'Asistió', '77345120', 'H1'),
    ('10001007', 'Martes', '14:00-16:00', 'Asistió', '76129034', 'B2'),
    ('10001008', 'Martes', '16:00-18:00', 'Asistió', '75610982', 'E1'),
    ('10001009', 'Miércoles', '08:00-10:00', 'Asistió', '78450216', 'G2'),
    ('10001010', 'Miércoles', '10:00-12:00', 'Asistió', '72893014', 'B1'),
    ('10001011', 'Miércoles', '14:00-16:00', 'No asistió', '70833192', 'D2'),
    ('10001012', 'Miércoles', '16:00-18:00', 'Asistió', '70456721', 'G1'),
    ('10001013', 'Jueves', '08:00-10:00', 'Asistió', '72015448', 'A2'),
    ('10001014', 'Jueves', '10:00-12:00', 'Asistió', '79210345', NULL),
    ('10001015', 'Jueves', '14:00-16:00', 'Asistió', '71928723', 'F2'),
    ('10001016', 'Jueves', '16:00-18:00', 'Asistió', '71102938', 'A1'),
    ('10001017', 'Viernes', '08:00-10:00', 'Asistió', '73012457', 'C2'),
    ('10001018', 'Viernes', '10:00-12:00', 'No asistió', '74480127', 'F1'),
    ('10001019', 'Viernes', '14:00-16:00', 'Asistió', '70981236', 'H2'),
    ('10001020', 'Viernes', '16:00-18:00', 'Asistió', '73374581', NULL),
    ('10001021', 'Sábado', '08:00-10:00', 'Asistió', '77345120', 'E2'),
    ('10001022', 'Sábado', '10:00-12:00', 'Asistió', '76129034', 'H1'),
    ('10001023', 'Sábado', '14:00-16:00', 'No asistió', '75610982', 'B2'),
    ('10001024', 'Sábado', '16:00-18:00', NULL, '78450216', 'E1');

-- Ingresos registrados (las citas con 'No asistió' no generan ingreso)
INSERT INTO ingreso (codigo_ingreso, fecha, hora_ingreso, turno, tipo_procedimiento, codigo_programacion, codigo_alumno, codigo_personal, codigo_sala, codigo_doctor) VALUES
    ('50001001', '2026-10-19', '08:08', 'Mañana', NULL, '10001001', '2021249145', 2, NULL, NULL),
    ('50001002', '2026-10-19', '10:11', 'Mañana', NULL, '10001002', '2022110419', 3, NULL, NULL),
    ('50001003', '2026-10-19', '14:14', 'Tarde', 'Exodoncia', '10001003', '2022110793', 4, 1, 2),
    ('50001004', '2026-10-19', '16:17', 'Tarde', NULL, '10001004', '2021249013', 1, NULL, NULL),
    ('50001005', '2026-10-20', '10:23', 'Mañana', NULL, '10001006', '2022110647', 3, NULL, NULL),
    ('50001006', '2026-10-20', '14:06', 'Tarde', NULL, '10001007', '2021248902', 4, NULL, NULL),
    ('50001007', '2026-10-20', '16:09', 'Tarde', NULL, '10001008', '2022110236', 1, NULL, NULL),
    ('50001008', '2026-10-21', '08:12', 'Mañana', NULL, '10001009', '2022110582', 2, NULL, NULL),
    ('50001009', '2026-10-21', '10:15', 'Mañana', NULL, '10001010', '2021248861', 3, NULL, NULL),
    ('50001010', '2026-10-21', '16:21', 'Tarde', NULL, '10001012', '2022110419', 1, NULL, NULL),
    ('50001011', '2026-10-22', '08:24', 'Mañana', NULL, '10001013', '2022110793', 2, NULL, NULL),
    ('50001012', '2026-10-22', '10:07', 'Mañana', 'Radiografía panorámica', '10001014', '2021249013', 3, 2, 4),
    ('50001013', '2026-10-22', '14:10', 'Tarde', NULL, '10001015', '2022110378', 4, NULL, NULL),
    ('50001014', '2026-10-22', '16:13', 'Tarde', NULL, '10001016', '2022110647', 1, NULL, NULL),
    ('50001015', '2026-10-23', '08:16', 'Mañana', NULL, '10001017', '2021248902', 2, NULL, NULL),
    ('50001016', '2026-10-23', '14:22', 'Tarde', NULL, '10001019', '2022110582', 4, NULL, NULL),
    ('50001017', '2026-10-23', '16:05', 'Tarde', 'Cirugía de terceros molares', '10001020', '2021248861', 1, 1, 1),
    ('50001018', '2026-10-24', '08:08', 'Mañana', NULL, '10001021', '2021249145', 2, NULL, NULL),
    ('50001019', '2026-10-24', '10:11', 'Mañana', NULL, '10001022', '2022110419', 3, NULL, NULL);

-- Permisos (los dos últimos siguen abiertos)
INSERT INTO permiso (codigo_ingreso, hora_salida, hora_retorno, motivo) VALUES
    ('50001001', '09:05', '09:20', 'Compra de material'),
    ('50001003', '10:40', '10:55', 'Recojo de instrumental en almacén'),
    ('50001007', '15:10', '15:25', 'Consulta con el docente'),
    ('50001010', '10:30', '10:42', 'Compra de material'),
    ('50001010', '11:15', '11:28', 'Servicios higiénicos'),
    ('50001016', '15:00', NULL, 'Compra de material'),
    ('50001018', '09:10', NULL, 'Recojo de radiografía');

-- Ciclos de esterilización (los dos últimos siguen en curso)
INSERT INTO esterilizacion (codigo_ingreso, hora_inicio, hora_fin, asistencia) VALUES
    ('50001001', '09:08', '09:33', 'Asistió'),
    ('50001002', '11:11', '11:36', 'Asistió'),
    ('50001003', '15:14', '15:39', 'Asistió'),
    ('50001004', '17:17', '17:42', 'Asistió'),
    ('50001005', '11:23', '11:48', 'No asistió'),
    ('50001006', '15:06', '15:31', 'Asistió'),
    ('50001007', '17:09', '17:34', 'Asistió'),
    ('50001008', '09:12', '09:37', 'Asistió'),
    ('50001009', '11:15', '11:40', 'Asistió'),
    ('50001010', '17:21', '17:46', 'Asistió'),
    ('50001011', '09:24', '09:49', 'Asistió'),
    ('50001012', '11:07', '11:32', 'Asistió'),
    ('50001013', '15:10', '15:35', 'No asistió'),
    ('50001014', '17:13', '17:38', 'Asistió'),
    ('50001015', '09:16', '09:41', 'Asistió'),
    ('50001016', '15:22', '15:47', 'Asistió'),
    ('50001017', '17:05', '17:30', 'Asistió'),
    ('50001018', '09:08', NULL, 'Asistió'),
    ('50001019', '11:11', NULL, 'Asistió');

COMMIT;

-- Conteo de filas cargadas
SELECT 'paciente' AS tabla, COUNT(*) AS filas FROM paciente
UNION ALL SELECT 'sillon', COUNT(*) FROM sillon
UNION ALL SELECT 'sala', COUNT(*) FROM sala
UNION ALL SELECT 'alumno', COUNT(*) FROM alumno
UNION ALL SELECT 'personal', COUNT(*) FROM personal
UNION ALL SELECT 'doctor', COUNT(*) FROM doctor
UNION ALL SELECT 'programacion', COUNT(*) FROM programacion
UNION ALL SELECT 'ingreso', COUNT(*) FROM ingreso
UNION ALL SELECT 'permiso', COUNT(*) FROM permiso
UNION ALL SELECT 'esterilizacion', COUNT(*) FROM esterilizacion;


-- #####################################################################
-- ##  14_datos_ampliados.sql
-- #####################################################################

-- =====================================================================
--  Script 14 - Datos ampliados para pruebas del aplicativo
--  Base de datos: bd_ingreso_odontologico (MySQL 8.0)
--  Ejecutar después de 01, 11 y 02, y ANTES de los triggers (script 13).
--  Agrega cuatro semanas de operación (26/10/2026 al 21/11/2026):
--  hasta el 17/11 las citas ya ocurrieron; desde el 18/11 quedan pendientes.
--    personal: 2   pacientes: 85   alumnos: 30
--    citas: 244   ingresos: 173   permisos: 54   esterilizaciones: 173
--  Generado con gen_datos.py (semilla fija, siempre produce los mismos datos).
-- =====================================================================
SET NAMES utf8mb4;
USE bd_ingreso_odontologico;
START TRANSACTION;


INSERT INTO personal (codigo_personal, nombre) VALUES
    (5, 'Valdivia Polar, Noemí'),
    (6, 'Cárdenas Linares, Iván');

INSERT INTO paciente (dni, nombre, condicion) VALUES
    ('47994000', 'Polar Ccama, Sergio', 'Adulto'),
    ('77350043', 'Pacheco Cornejo, Milagros', 'Adulto'),
    ('79360747', 'Quispe Mendoza, Raúl', 'Adulto'),
    ('47431403', 'Ccama Rivera, Luis', 'Adulto'),
    ('72902585', 'Chávez Bellido, Rodrigo', 'Adulto'),
    ('63330923', 'Begazo Zevallos, Ximena', 'Prenatal'),
    ('45121741', 'Apaza Cornejo, Carmen', 'Adulto'),
    ('59603967', 'Vargas Pacheco, Martín', 'Adulto'),
    ('41660226', 'Llerena Apaza, Valeria', 'Niño'),
    ('79306857', 'Choque Llerena, Ximena', 'Adulto'),
    ('72952513', 'Tejada Medina, Camila', 'Adulto'),
    ('77849407', 'Núñez Polar, Fiorella', 'Niño'),
    ('41702963', 'Rojas Huamán, Fiorella', 'Adulto'),
    ('46883784', 'Llerena Núñez, Andrés', 'Adulto'),
    ('72354063', 'Choque Málaga, Gabriela', 'Niño'),
    ('76616761', 'Bellido Cárdenas, Diana', 'Adulto'),
    ('73681912', 'Bellido Llerena, Óscar', 'Adulto'),
    ('59755114', 'Quispe Condori, Andrés', 'Niño'),
    ('70751123', 'Herrera Valdivia, Óscar', 'Niño'),
    ('57455721', 'Málaga Polar, Milagros', 'Adulto'),
    ('69140647', 'Condori Zúñiga, María', 'Adulto'),
    ('70712745', 'Ccama Rivera, Ximena', 'Niño'),
    ('57369864', 'Pérez Llerena, Gabriela', 'Adulto'),
    ('44314774', 'Herrera Valdivia, Diego', 'Adulto'),
    ('53058486', 'Cuadros Vargas, Elena', 'Niño'),
    ('40941708', 'Rivera Ticona, Carmen', 'Adulto'),
    ('45574435', 'Torres Paredes, Renzo', 'Adulto'),
    ('42997019', 'Villanueva Begazo, Andrés', 'Niño'),
    ('40344342', 'Ticona Pacheco, Milagros', 'Adulto'),
    ('49050609', 'Núñez Ticona, Marco', 'Adulto'),
    ('73871279', 'Cuadros Gutiérrez, Marco', 'Adulto'),
    ('79327753', 'Cuadros Zevallos, Andrés', 'Adulto'),
    ('74898684', 'Zevallos Quispe, Diego', 'Niño'),
    ('66128700', 'Huamán Begazo, Lucía', 'Niño'),
    ('41730753', 'Núñez Delgado, Martín', 'Adulto'),
    ('70208409', 'Choque Herrera, Patricia', 'Adulto'),
    ('78360649', 'Gutiérrez Vargas, Noemí', 'Adulto'),
    ('74870687', 'Mendoza Linares, Patricia', 'Adulto'),
    ('55658276', 'Flores Cornejo, Valeria', 'Adulto'),
    ('42291948', 'Pérez Condori, Carmen', 'Adulto'),
    ('43233805', 'Torres Núñez, Jorge', 'Adulto'),
    ('48666423', 'Chávez Tejada, Marco', 'Adulto'),
    ('50763636', 'Pérez Zevallos, Álvaro', 'Adulto'),
    ('68545042', 'Apaza Zevallos, Martín', 'Adulto'),
    ('52562697', 'Medina Málaga, Milagros', 'Adulto'),
    ('67899664', 'Pérez Delgado, Fiorella', 'Adulto'),
    ('72350014', 'Ccama Chávez, Sergio', 'Adulto'),
    ('40329224', 'Málaga Linares, Camila', 'Prenatal'),
    ('76578367', 'Pérez Mamani, Lucía', 'Niño'),
    ('50519926', 'Pacheco Benavente, Iván', 'Adulto'),
    ('47361406', 'Villanueva Cornejo, Karla', 'Adulto'),
    ('54390492', 'Pacheco Villanueva, Diana', 'Adulto'),
    ('48899854', 'Medina Ccama, Daniela', 'Adulto'),
    ('51494076', 'Huamán Begazo, Fernando', 'Adulto'),
    ('47135016', 'Villanueva Ticona, Miguel', 'Adulto'),
    ('59531105', 'Gutiérrez Medina, Rodrigo', 'Niño'),
    ('44219743', 'Medina Cuadros, Luis', 'Adulto'),
    ('43846117', 'Mamani Cárdenas, Renzo', 'Adulto'),
    ('46299518', 'Pacheco Begazo, María', 'Adulto'),
    ('70604642', 'Mendoza Condori, Valeria', 'Adulto'),
    ('61210677', 'Larico Málaga, Daniela', 'Adulto'),
    ('48015499', 'Polar Medina, Sofía', 'Adulto'),
    ('59587828', 'Begazo Huamán, Daniela', 'Prenatal'),
    ('41588018', 'Linares Zúñiga, Renzo', 'Adulto'),
    ('59927441', 'Delgado Ticona, Jorge', 'Niño'),
    ('76383529', 'Torres Cornejo, José', 'Prenatal'),
    ('47556297', 'Rojas Tejada, Lucía', 'Adulto'),
    ('60283061', 'Ticona Rojas, Lucía', 'Adulto'),
    ('67870183', 'Paredes Cuadros, Sergio', 'Adulto'),
    ('48402570', 'Mamani Benavente, Diana', 'Adulto'),
    ('66632717', 'Vargas Salazar, Jorge', 'Niño'),
    ('41113725', 'Núñez Cuadros, Rodrigo', 'Adulto'),
    ('61122158', 'Ticona Apaza, Fernando', 'Adulto'),
    ('77110001', 'Polar Medina, Rosa', 'Adulto'),
    ('74926736', 'Delgado Huamán, Luis', 'Niño'),
    ('56294468', 'Salazar Polar, Andrés', 'Adulto'),
    ('66781424', 'Valdivia Salazar, Diana', 'Adulto'),
    ('58506071', 'Torres Valdivia, Lucía', 'Adulto'),
    ('70820935', 'Cornejo Núñez, Noemí', 'Adulto'),
    ('60950961', 'Cuadros Vargas, Milagros', 'Adulto'),
    ('40356469', 'Tejada Cuadros, Carlos', 'Prenatal'),
    ('51581162', 'Valdivia Benavente, Rodrigo', 'Adulto'),
    ('49258378', 'Ccama Mamani, Carmen', 'Adulto'),
    ('54570849', 'Ticona Cárdenas, Karla', 'Niño'),
    ('42995945', 'Zevallos Benavente, Fiorella', 'Prenatal');

INSERT INTO alumno (codigo_alumno, codigo_qr, nombre) VALUES
    ('2022100001', 'QR96442492', 'Gutiérrez Polar, Diego'),
    ('2022100038', 'QR21480544', 'Vargas Zevallos, Rosa'),
    ('2022100075', 'QR83482912', 'Medina Cárdenas, Carlos'),
    ('2022100112', 'QR89553785', 'Torres Gutiérrez, Hugo'),
    ('2022100149', 'QR49633400', 'Benavente Zúñiga, Lucía'),
    ('2022100186', 'QR27985812', 'Zevallos Torres, Luis'),
    ('2022100223', 'QR91329384', 'Núñez Llerena, Lucía'),
    ('2022100260', 'QR82124991', 'Gutiérrez Tejada, Jorge'),
    ('2022100297', 'QR34108605', 'Delgado Benavente, Andrés'),
    ('2022100334', 'QR32003385', 'Mamani Choque, Ximena'),
    ('2022100371', 'QR99617544', 'Quispe Valdivia, Miguel'),
    ('2022100408', 'QR59391658', 'Cárdenas Chávez, Carmen'),
    ('2022100445', 'QR30699871', 'Larico Mendoza, Gonzalo'),
    ('2022100482', 'QR26981826', 'Ccama Delgado, Milagros'),
    ('2022100519', 'QR24414113', 'Flores Zevallos, Rodrigo'),
    ('2022100556', 'QR92806254', 'Cárdenas Choque, Lucía'),
    ('2022100593', 'QR73670338', 'Herrera Choque, Diana'),
    ('2022100630', 'QR79651800', 'Paredes Begazo, Patricia'),
    ('2022100667', 'QR88559672', 'Begazo Apaza, Miguel'),
    ('2022100704', 'QR21793294', 'Herrera Cárdenas, Rodrigo'),
    ('2022100741', 'QR98866676', 'Salazar Gutiérrez, María'),
    ('2022100778', 'QR68062135', 'Polar Cornejo, Rosa'),
    ('2022100815', 'QR53311204', 'Herrera Bellido, María'),
    ('2022100852', 'QR33722079', 'Torres Málaga, Sergio'),
    ('2022100889', 'QR56781129', 'Begazo Cuadros, Noemí'),
    ('2022100926', 'QR61221192', 'Chávez Vargas, Elena'),
    ('2022100963', 'QR86043714', 'Rojas Llerena, Álvaro'),
    ('2022101000', 'QR54154075', 'Choque Delgado, Álvaro'),
    ('2022101037', 'QR69652955', 'Medina Vargas, Carmen'),
    ('2022101074', 'QR94137981', 'Villanueva Salazar, Rosa');

INSERT INTO programacion (codigo_programacion, dia_semana, bloque_horario, asistencia, dni, codigo_sillon) VALUES
    ('10001025', 'Lunes', '08:00-10:00', 'Asistió', '66632717', 'D2'),
    ('10001026', 'Lunes', '10:00-12:00', 'Asistió', '67899664', 'B1'),
    ('10001027', 'Lunes', '10:00-12:00', 'Asistió', '48015499', 'A2'),
    ('10001028', 'Lunes', '10:00-12:00', 'Asistió', '46299518', 'G2'),
    ('10001029', 'Lunes', '10:00-12:00', 'Asistió', '70604642', 'E2'),
    ('10001030', 'Lunes', '14:00-16:00', 'No asistió', '41730753', 'B2'),
    ('10001031', 'Lunes', '14:00-16:00', 'Asistió', '63330923', 'C1'),
    ('10001032', 'Lunes', '14:00-16:00', 'Asistió', '68545042', 'E1'),
    ('10001033', 'Lunes', '14:00-16:00', 'Asistió', '49258378', NULL),
    ('10001034', 'Lunes', '16:00-18:00', 'Asistió', '76383529', 'A2'),
    ('10001035', 'Lunes', '16:00-18:00', 'Asistió', '77345120', 'H2'),
    ('10001036', 'Martes', '08:00-10:00', 'Asistió', '60283061', 'F2'),
    ('10001037', 'Martes', '08:00-10:00', 'Asistió', '73871279', 'C1'),
    ('10001038', 'Martes', '08:00-10:00', 'Asistió', '59755114', NULL),
    ('10001039', 'Martes', '10:00-12:00', 'No asistió', '71928723', 'C1'),
    ('10001040', 'Martes', '10:00-12:00', 'Asistió', '72015448', 'C2'),
    ('10001041', 'Martes', '10:00-12:00', 'Asistió', '74480127', 'D2'),
    ('10001042', 'Martes', '14:00-16:00', 'Asistió', '49258378', 'F1'),
    ('10001043', 'Martes', '14:00-16:00', 'Asistió', '77849407', 'B2'),
    ('10001044', 'Martes', '16:00-18:00', 'Asistió', '61210677', 'H1'),
    ('10001045', 'Martes', '16:00-18:00', 'Asistió', '69140647', 'D2'),
    ('10001046', 'Martes', '16:00-18:00', 'Asistió', '73871279', 'B2'),
    ('10001047', 'Miércoles', '08:00-10:00', 'Asistió', '72893014', 'C2'),
    ('10001048', 'Miércoles', '08:00-10:00', 'No asistió', '53058486', 'G2'),
    ('10001049', 'Miércoles', '08:00-10:00', 'Asistió', '47135016', NULL),
    ('10001050', 'Miércoles', '10:00-12:00', 'Asistió', '47556297', 'H1'),
    ('10001051', 'Miércoles', '14:00-16:00', 'No asistió', '40344342', 'B2'),
    ('10001052', 'Miércoles', '14:00-16:00', 'Asistió', '46299518', 'D1'),
    ('10001053', 'Miércoles', '14:00-16:00', 'Asistió', '77345120', 'H2'),
    ('10001054', 'Miércoles', '16:00-18:00', 'Asistió', '70208409', 'E1'),
    ('10001055', 'Miércoles', '16:00-18:00', 'Asistió', '79360747', 'F2'),
    ('10001056', 'Miércoles', '16:00-18:00', 'Asistió', '72893014', 'G1'),
    ('10001057', 'Miércoles', '16:00-18:00', 'Asistió', '48666423', 'H2'),
    ('10001058', 'Jueves', '08:00-10:00', 'Asistió', '48015499', 'B1'),
    ('10001059', 'Jueves', '08:00-10:00', 'Asistió', '74870687', 'H2'),
    ('10001060', 'Jueves', '08:00-10:00', 'No asistió', '70712745', 'F2'),
    ('10001061', 'Jueves', '08:00-10:00', 'Asistió', '76616761', 'G1'),
    ('10001062', 'Jueves', '08:00-10:00', 'Asistió', '79327753', 'D2'),
    ('10001063', 'Jueves', '10:00-12:00', 'No asistió', '72354063', 'H2'),
    ('10001064', 'Jueves', '10:00-12:00', 'Asistió', '66632717', 'G1'),
    ('10001065', 'Jueves', '14:00-16:00', 'Asistió', '53058486', 'D1'),
    ('10001066', 'Jueves', '14:00-16:00', 'No asistió', '61210677', NULL),
    ('10001067', 'Jueves', '16:00-18:00', 'No asistió', '79306857', 'C2'),
    ('10001068', 'Jueves', '16:00-18:00', 'Asistió', '72015448', 'A2'),
    ('10001069', 'Viernes', '08:00-10:00', 'Asistió', '44219743', 'H1'),
    ('10001070', 'Viernes', '08:00-10:00', 'Asistió', '70604642', 'C2'),
    ('10001071', 'Viernes', '08:00-10:00', 'Asistió', '74480127', 'H2'),
    ('10001072', 'Viernes', '08:00-10:00', 'No asistió', '77849407', 'B1'),
    ('10001073', 'Viernes', '08:00-10:00', 'Asistió', '41588018', 'A1'),
    ('10001074', 'Viernes', '10:00-12:00', 'Asistió', '54570849', 'E2'),
    ('10001075', 'Viernes', '10:00-12:00', 'No asistió', '77350043', 'G2'),
    ('10001076', 'Viernes', '10:00-12:00', 'No asistió', '68545042', 'F1'),
    ('10001077', 'Viernes', '14:00-16:00', 'Asistió', '57369864', 'G2'),
    ('10001078', 'Viernes', '14:00-16:00', 'Asistió', '42995945', 'B1'),
    ('10001079', 'Viernes', '14:00-16:00', 'Asistió', '79360747', NULL),
    ('10001080', 'Sábado', '08:00-10:00', 'No asistió', '50519926', 'C1'),
    ('10001081', 'Sábado', '10:00-12:00', 'Asistió', '44219743', 'G2'),
    ('10001082', 'Sábado', '10:00-12:00', 'Asistió', '70712745', 'C1'),
    ('10001083', 'Sábado', '10:00-12:00', 'Asistió', '49050609', 'G1'),
    ('10001084', 'Sábado', '16:00-18:00', 'No asistió', '67870183', 'C2'),
    ('10001085', 'Sábado', '16:00-18:00', 'Asistió', '74480127', 'B2'),
    ('10001086', 'Lunes', '08:00-10:00', 'Asistió', '41113725', 'B2'),
    ('10001087', 'Lunes', '08:00-10:00', 'Asistió', '52562697', NULL),
    ('10001088', 'Lunes', '10:00-12:00', 'Asistió', '67899664', 'A1'),
    ('10001089', 'Lunes', '10:00-12:00', 'Asistió', '40329224', 'G1'),
    ('10001090', 'Lunes', '10:00-12:00', 'Asistió', '51494076', 'E1'),
    ('10001091', 'Lunes', '10:00-12:00', 'Asistió', '40356469', 'H2'),
    ('10001092', 'Lunes', '10:00-12:00', 'Asistió', '66781424', 'B2'),
    ('10001093', 'Lunes', '14:00-16:00', 'Asistió', '77849407', 'E1'),
    ('10001094', 'Lunes', '14:00-16:00', 'Asistió', '71102938', 'F2'),
    ('10001095', 'Lunes', '14:00-16:00', 'Asistió', '60283061', 'D2'),
    ('10001096', 'Lunes', '14:00-16:00', 'No asistió', '72350014', 'H2'),
    ('10001097', 'Martes', '08:00-10:00', 'Asistió', '49050609', 'E2'),
    ('10001098', 'Martes', '08:00-10:00', 'Asistió', '70820935', 'C2'),
    ('10001099', 'Martes', '10:00-12:00', 'Asistió', '69140647', 'F1'),
    ('10001100', 'Martes', '10:00-12:00', 'Asistió', '40941708', 'A1'),
    ('10001101', 'Martes', '10:00-12:00', 'Asistió', '49258378', 'C1'),
    ('10001102', 'Martes', '14:00-16:00', 'Asistió', '72893014', 'E1'),
    ('10001103', 'Martes', '14:00-16:00', 'Asistió', '73012457', 'C1'),
    ('10001104', 'Martes', '14:00-16:00', 'Asistió', '79360747', 'D2'),
    ('10001105', 'Martes', '14:00-16:00', 'Asistió', '66128700', NULL),
    ('10001106', 'Martes', '16:00-18:00', 'Asistió', '46299518', 'E1'),
    ('10001107', 'Martes', '16:00-18:00', 'Asistió', '51494076', 'A2'),
    ('10001108', 'Miércoles', '08:00-10:00', 'Asistió', '41113725', 'C1'),
    ('10001109', 'Miércoles', '08:00-10:00', 'No asistió', '51581162', 'E1'),
    ('10001110', 'Miércoles', '08:00-10:00', 'Asistió', '67870183', 'A2'),
    ('10001111', 'Miércoles', '10:00-12:00', 'Asistió', '78450216', 'G1'),
    ('10001112', 'Miércoles', '10:00-12:00', 'Asistió', '70456721', 'B1'),
    ('10001113', 'Miércoles', '14:00-16:00', 'Asistió', '70208409', 'B2'),
    ('10001114', 'Miércoles', '14:00-16:00', 'Asistió', '59755114', 'H2'),
    ('10001115', 'Miércoles', '14:00-16:00', 'Asistió', '72350014', NULL),
    ('10001116', 'Miércoles', '16:00-18:00', 'Asistió', '41113725', 'C2'),
    ('10001117', 'Miércoles', '16:00-18:00', 'Asistió', '41730753', 'A1'),
    ('10001118', 'Miércoles', '16:00-18:00', 'Asistió', '55658276', 'A2'),
    ('10001119', 'Jueves', '08:00-10:00', 'Asistió', '48402570', 'B2'),
    ('10001120', 'Jueves', '08:00-10:00', 'Asistió', '74480127', 'G1'),
    ('10001121', 'Jueves', '08:00-10:00', 'Asistió', '41113725', 'A2'),
    ('10001122', 'Jueves', '08:00-10:00', 'Asistió', '59531105', 'D1'),
    ('10001123', 'Jueves', '10:00-12:00', 'Asistió', '76616761', 'C1'),
    ('10001124', 'Jueves', '10:00-12:00', 'Asistió', '77345120', 'A1'),
    ('10001125', 'Jueves', '10:00-12:00', 'Asistió', '40941708', 'H2'),
    ('10001126', 'Jueves', '14:00-16:00', 'Asistió', '41113725', 'E1'),
    ('10001127', 'Jueves', '14:00-16:00', 'Asistió', '66128700', NULL),
    ('10001128', 'Jueves', '16:00-18:00', 'Asistió', '42291948', 'C2'),
    ('10001129', 'Jueves', '16:00-18:00', 'Asistió', '70208409', 'H1'),
    ('10001130', 'Viernes', '08:00-10:00', 'No asistió', '79327753', 'C2'),
    ('10001131', 'Viernes', '08:00-10:00', 'No asistió', '77110001', 'D2'),
    ('10001132', 'Viernes', '08:00-10:00', 'Asistió', '40344342', NULL),
    ('10001133', 'Viernes', '10:00-12:00', 'No asistió', '46299518', 'C1'),
    ('10001134', 'Viernes', '10:00-12:00', 'Asistió', '72893014', 'F1'),
    ('10001135', 'Viernes', '10:00-12:00', 'Asistió', '54390492', 'A2'),
    ('10001136', 'Viernes', '14:00-16:00', 'Asistió', '79360747', 'H2'),
    ('10001137', 'Viernes', '14:00-16:00', 'Asistió', '72893014', 'G1'),
    ('10001138', 'Viernes', '14:00-16:00', 'Asistió', '40941708', 'F2'),
    ('10001139', 'Viernes', '16:00-18:00', 'No asistió', '51494076', 'D2'),
    ('10001140', 'Viernes', '16:00-18:00', 'Asistió', '54390492', 'F1'),
    ('10001141', 'Sábado', '08:00-10:00', 'Asistió', '45121741', 'A2'),
    ('10001142', 'Sábado', '08:00-10:00', 'Asistió', '41588018', 'H2'),
    ('10001143', 'Sábado', '08:00-10:00', 'Asistió', '59755114', 'B1'),
    ('10001144', 'Sábado', '10:00-12:00', 'Asistió', '41588018', 'D2'),
    ('10001145', 'Sábado', '14:00-16:00', 'No asistió', '73681912', 'A1'),
    ('10001146', 'Sábado', '16:00-18:00', 'Asistió', '77345120', 'G2'),
    ('10001147', 'Lunes', '08:00-10:00', 'Asistió', '59603967', 'A2'),
    ('10001148', 'Lunes', '10:00-12:00', 'No asistió', '70751123', 'H2'),
    ('10001149', 'Lunes', '10:00-12:00', 'Asistió', '43233805', 'E2'),
    ('10001150', 'Lunes', '10:00-12:00', 'No asistió', '77345120', 'H1'),
    ('10001151', 'Lunes', '10:00-12:00', 'Asistió', '71928723', 'C2'),
    ('10001152', 'Lunes', '10:00-12:00', 'Asistió', '77110001', 'C1'),
    ('10001153', 'Lunes', '14:00-16:00', 'Asistió', '47431403', 'C2'),
    ('10001154', 'Lunes', '14:00-16:00', 'Asistió', '77345120', 'F1'),
    ('10001155', 'Lunes', '14:00-16:00', 'Asistió', '43846117', NULL),
    ('10001156', 'Lunes', '16:00-18:00', 'Asistió', '49050609', 'F2'),
    ('10001157', 'Lunes', '16:00-18:00', 'No asistió', '72015448', 'C1'),
    ('10001158', 'Martes', '08:00-10:00', 'Asistió', '74480127', 'E1'),
    ('10001159', 'Martes', '08:00-10:00', 'Asistió', '70712745', 'B1'),
    ('10001160', 'Martes', '08:00-10:00', 'Asistió', '73681912', NULL),
    ('10001161', 'Martes', '10:00-12:00', 'Asistió', '59531105', 'G2'),
    ('10001162', 'Martes', '10:00-12:00', 'Asistió', '70712745', 'E2'),
    ('10001163', 'Martes', '14:00-16:00', 'Asistió', '41113725', 'A2'),
    ('10001164', 'Martes', '14:00-16:00', 'Asistió', '63330923', 'G1'),
    ('10001165', 'Martes', '16:00-18:00', 'Asistió', '72952513', 'G1'),
    ('10001166', 'Martes', '16:00-18:00', 'Asistió', '78360649', 'H2'),
    ('10001167', 'Martes', '16:00-18:00', 'Asistió', '49050609', 'C1'),
    ('10001168', 'Martes', '16:00-18:00', 'Asistió', '75610982', 'B2'),
    ('10001169', 'Miércoles', '08:00-10:00', 'Asistió', '70981236', 'A2'),
    ('10001170', 'Miércoles', '08:00-10:00', 'Asistió', '54390492', 'F1'),
    ('10001171', 'Miércoles', '10:00-12:00', 'Asistió', '77110001', 'D2'),
    ('10001172', 'Miércoles', '10:00-12:00', 'Asistió', '49050609', 'B2'),
    ('10001173', 'Miércoles', '10:00-12:00', 'Asistió', '78360649', 'B1'),
    ('10001174', 'Miércoles', '10:00-12:00', 'Asistió', '57369864', 'E1'),
    ('10001175', 'Miércoles', '14:00-16:00', 'No asistió', '70981236', 'A2'),
    ('10001176', 'Miércoles', '14:00-16:00', 'Asistió', '48015499', 'G1'),
    ('10001177', 'Miércoles', '14:00-16:00', 'Asistió', '59603967', NULL),
    ('10001178', 'Miércoles', '16:00-18:00', 'Asistió', '44314774', 'F1'),
    ('10001179', 'Miércoles', '16:00-18:00', 'Asistió', '77849407', 'C2'),
    ('10001180', 'Jueves', '08:00-10:00', 'Asistió', '77849407', 'B2'),
    ('10001181', 'Jueves', '08:00-10:00', 'Asistió', '75610982', 'F2'),
    ('10001182', 'Jueves', '08:00-10:00', 'Asistió', '78450216', 'E1'),
    ('10001183', 'Jueves', '08:00-10:00', 'Asistió', '66781424', 'F1'),
    ('10001184', 'Jueves', '08:00-10:00', 'Asistió', '55658276', 'A1'),
    ('10001185', 'Jueves', '14:00-16:00', 'No asistió', '67870183', 'A1'),
    ('10001186', 'Jueves', '14:00-16:00', 'Asistió', '77110001', NULL),
    ('10001187', 'Jueves', '16:00-18:00', 'Asistió', '70604642', 'A1'),
    ('10001188', 'Jueves', '16:00-18:00', 'No asistió', '71102938', 'B2'),
    ('10001189', 'Jueves', '16:00-18:00', 'Asistió', '77849407', 'D1'),
    ('10001190', 'Jueves', '16:00-18:00', 'Asistió', '59603967', 'E1'),
    ('10001191', 'Viernes', '08:00-10:00', 'Asistió', '76129034', 'D1'),
    ('10001192', 'Viernes', '08:00-10:00', 'Asistió', '72350014', 'G2'),
    ('10001193', 'Viernes', '08:00-10:00', 'Asistió', '40356469', 'E2'),
    ('10001194', 'Viernes', '08:00-10:00', 'Asistió', '72354063', NULL),
    ('10001195', 'Viernes', '10:00-12:00', 'No asistió', '72015448', 'H2'),
    ('10001196', 'Viernes', '10:00-12:00', 'Asistió', '58506071', 'E2'),
    ('10001197', 'Viernes', '10:00-12:00', 'Asistió', '77110001', 'B1'),
    ('10001198', 'Viernes', '10:00-12:00', 'No asistió', '46883784', 'C1'),
    ('10001199', 'Viernes', '10:00-12:00', 'Asistió', '59587828', 'F2'),
    ('10001200', 'Viernes', '14:00-16:00', 'Asistió', '79210345', 'G1'),
    ('10001201', 'Viernes', '16:00-18:00', 'Asistió', '66632717', 'G1'),
    ('10001202', 'Sábado', '10:00-12:00', 'Asistió', '44219743', 'F2'),
    ('10001203', 'Sábado', '10:00-12:00', 'Asistió', '55658276', 'E1'),
    ('10001204', 'Sábado', '14:00-16:00', 'Asistió', '63330923', 'E2'),
    ('10001205', 'Sábado', '14:00-16:00', 'Asistió', '72893014', 'C1'),
    ('10001206', 'Sábado', '16:00-18:00', 'Asistió', '51494076', 'H1'),
    ('10001207', 'Sábado', '16:00-18:00', 'Asistió', '79360747', 'A1'),
    ('10001208', 'Lunes', '08:00-10:00', 'Asistió', '74480127', 'H2'),
    ('10001209', 'Lunes', '08:00-10:00', 'Asistió', '47556297', 'G2'),
    ('10001210', 'Lunes', '08:00-10:00', 'Asistió', '79306857', 'C1'),
    ('10001211', 'Lunes', '08:00-10:00', 'Asistió', '47135016', 'C2'),
    ('10001212', 'Lunes', '10:00-12:00', 'Asistió', '70456721', 'B2'),
    ('10001213', 'Lunes', '10:00-12:00', 'No asistió', '72354063', 'G2'),
    ('10001214', 'Lunes', '14:00-16:00', 'No asistió', '70751123', 'E2'),
    ('10001215', 'Lunes', '14:00-16:00', 'Asistió', '70208409', 'F1'),
    ('10001216', 'Lunes', '14:00-16:00', 'Asistió', '68545042', 'D2'),
    ('10001217', 'Lunes', '14:00-16:00', 'Asistió', '70456721', NULL),
    ('10001218', 'Lunes', '16:00-18:00', 'Asistió', '76383529', 'H2'),
    ('10001219', 'Martes', '08:00-10:00', 'No asistió', '76129034', 'A1'),
    ('10001220', 'Martes', '10:00-12:00', 'Asistió', '75610982', 'C1'),
    ('10001221', 'Martes', '10:00-12:00', 'Asistió', '59927441', 'H2'),
    ('10001222', 'Martes', '10:00-12:00', 'Asistió', '40941708', 'C2'),
    ('10001223', 'Martes', '10:00-12:00', 'Asistió', '73374581', 'F1'),
    ('10001224', 'Martes', '10:00-12:00', 'No asistió', '59927441', 'F2'),
    ('10001225', 'Martes', '10:00-12:00', 'Asistió', '68545042', 'D2'),
    ('10001226', 'Martes', '14:00-16:00', 'Asistió', '73012457', 'G1'),
    ('10001227', 'Martes', '14:00-16:00', 'Asistió', '43233805', 'H2'),
    ('10001228', 'Martes', '14:00-16:00', 'Asistió', '41588018', NULL),
    ('10001229', 'Martes', '16:00-18:00', 'Asistió', '70604642', 'D2'),
    ('10001230', 'Miércoles', '08:00-10:00', NULL, '40344342', 'D2'),
    ('10001231', 'Miércoles', '08:00-10:00', NULL, '63330923', 'H1'),
    ('10001232', 'Miércoles', '08:00-10:00', NULL, '77110001', 'F2'),
    ('10001233', 'Miércoles', '08:00-10:00', NULL, '78450216', NULL),
    ('10001234', 'Miércoles', '10:00-12:00', NULL, '51494076', 'H1'),
    ('10001235', 'Miércoles', '10:00-12:00', NULL, '70208409', 'G1'),
    ('10001236', 'Miércoles', '10:00-12:00', NULL, '57369864', 'A2'),
    ('10001237', 'Miércoles', '10:00-12:00', NULL, '47556297', 'A1'),
    ('10001238', 'Miércoles', '14:00-16:00', NULL, '69140647', 'H1'),
    ('10001239', 'Miércoles', '16:00-18:00', NULL, '42291948', 'H1'),
    ('10001240', 'Miércoles', '16:00-18:00', NULL, '45574435', 'B1'),
    ('10001241', 'Jueves', '08:00-10:00', NULL, '51581162', 'H2'),
    ('10001242', 'Jueves', '08:00-10:00', NULL, '74870687', 'G2'),
    ('10001243', 'Jueves', '08:00-10:00', NULL, '75610982', 'G1'),
    ('10001244', 'Jueves', '08:00-10:00', NULL, '70820935', 'C2'),
    ('10001245', 'Jueves', '08:00-10:00', NULL, '50763636', NULL),
    ('10001246', 'Jueves', '10:00-12:00', NULL, '61210677', 'B2'),
    ('10001247', 'Jueves', '10:00-12:00', NULL, '78360649', 'C2'),
    ('10001248', 'Jueves', '14:00-16:00', NULL, '72893014', 'C1'),
    ('10001249', 'Jueves', '16:00-18:00', NULL, '74870687', 'G2'),
    ('10001250', 'Jueves', '16:00-18:00', NULL, '79306857', 'C2'),
    ('10001251', 'Jueves', '16:00-18:00', NULL, '48666423', 'B1'),
    ('10001252', 'Viernes', '08:00-10:00', NULL, '76129034', 'F1'),
    ('10001253', 'Viernes', '08:00-10:00', NULL, '71928723', 'C1'),
    ('10001254', 'Viernes', '08:00-10:00', NULL, '55658276', 'E1'),
    ('10001255', 'Viernes', '08:00-10:00', NULL, '51581162', NULL),
    ('10001256', 'Viernes', '10:00-12:00', NULL, '70751123', 'E2'),
    ('10001257', 'Viernes', '10:00-12:00', NULL, '47361406', 'H1'),
    ('10001258', 'Viernes', '10:00-12:00', NULL, '40329224', 'D2'),
    ('10001259', 'Viernes', '14:00-16:00', NULL, '41660226', 'E2'),
    ('10001260', 'Viernes', '14:00-16:00', NULL, '72952513', 'G1'),
    ('10001261', 'Viernes', '16:00-18:00', NULL, '70981236', 'A1'),
    ('10001262', 'Viernes', '16:00-18:00', NULL, '77345120', 'D1'),
    ('10001263', 'Sábado', '08:00-10:00', NULL, '68545042', 'F2'),
    ('10001264', 'Sábado', '10:00-12:00', NULL, '48402570', 'E2'),
    ('10001265', 'Sábado', '14:00-16:00', NULL, '73871279', 'D2'),
    ('10001266', 'Sábado', '16:00-18:00', NULL, '67899664', 'A2'),
    ('10001267', 'Sábado', '16:00-18:00', NULL, '71102938', 'E2'),
    ('10001268', 'Sábado', '16:00-18:00', NULL, '70820935', 'C1');

INSERT INTO ingreso (codigo_ingreso, fecha, hora_ingreso, turno, tipo_procedimiento, codigo_programacion, codigo_alumno, codigo_personal, codigo_sala, codigo_doctor) VALUES
    ('50001020', '2026-10-26', '08:10', 'Mañana', NULL, '10001025', '2022100408', 2, NULL, NULL),
    ('50001021', '2026-10-26', '10:00', 'Mañana', NULL, '10001026', '2022100038', 2, NULL, NULL),
    ('50001022', '2026-10-26', '10:00', 'Mañana', NULL, '10001027', '2022110582', 1, NULL, NULL),
    ('50001023', '2026-10-26', '10:09', 'Mañana', NULL, '10001028', '2022100482', 5, NULL, NULL),
    ('50001024', '2026-10-26', '10:10', 'Mañana', NULL, '10001029', '2022100334', 1, NULL, NULL),
    ('50001025', '2026-10-26', '14:11', 'Tarde', NULL, '10001031', '2022100149', 6, NULL, NULL),
    ('50001026', '2026-10-26', '14:09', 'Tarde', NULL, '10001032', '2022100223', 4, NULL, NULL),
    ('50001027', '2026-10-26', '14:00', 'Tarde', 'Exodoncia', '10001033', '2022100482', 4, 1, 2),
    ('50001028', '2026-10-26', '16:06', 'Tarde', NULL, '10001034', '2022100112', 4, NULL, NULL),
    ('50001029', '2026-10-26', '16:13', 'Tarde', NULL, '10001035', '2022100741', 4, NULL, NULL),
    ('50001030', '2026-10-27', '08:06', 'Mañana', NULL, '10001036', '2022110419', 5, NULL, NULL),
    ('50001031', '2026-10-27', '08:08', 'Mañana', NULL, '10001037', '2022110647', 5, NULL, NULL),
    ('50001032', '2026-10-27', '08:13', 'Mañana', 'Radiografía panorámica', '10001038', '2022100482', 2, 2, 6),
    ('50001033', '2026-10-27', '10:12', 'Mañana', NULL, '10001040', '2022100963', 5, NULL, NULL),
    ('50001034', '2026-10-27', '10:07', 'Mañana', NULL, '10001041', '2022100038', 1, NULL, NULL),
    ('50001035', '2026-10-27', '14:14', 'Tarde', NULL, '10001042', '2021248902', 6, NULL, NULL),
    ('50001036', '2026-10-27', '14:11', 'Tarde', NULL, '10001043', '2022110793', 4, NULL, NULL),
    ('50001037', '2026-10-27', '16:01', 'Tarde', NULL, '10001044', '2022101000', 4, NULL, NULL),
    ('50001038', '2026-10-27', '16:13', 'Tarde', NULL, '10001045', '2022100630', 3, NULL, NULL),
    ('50001039', '2026-10-27', '16:07', 'Tarde', NULL, '10001046', '2022100482', 3, NULL, NULL),
    ('50001040', '2026-10-28', '08:11', 'Mañana', NULL, '10001047', '2022101074', 5, NULL, NULL),
    ('50001041', '2026-10-28', '08:02', 'Mañana', 'Exodoncia', '10001049', '2022100260', 5, 1, 2),
    ('50001042', '2026-10-28', '10:04', 'Mañana', NULL, '10001050', '2022100778', 2, NULL, NULL),
    ('50001043', '2026-10-28', '14:10', 'Tarde', NULL, '10001052', '2021249145', 6, NULL, NULL),
    ('50001044', '2026-10-28', '14:07', 'Tarde', NULL, '10001053', '2022100889', 4, NULL, NULL),
    ('50001045', '2026-10-28', '16:01', 'Tarde', NULL, '10001054', '2021249013', 6, NULL, NULL),
    ('50001046', '2026-10-28', '16:05', 'Tarde', NULL, '10001055', '2021248902', 3, NULL, NULL),
    ('50001047', '2026-10-28', '16:01', 'Tarde', NULL, '10001056', '2022100408', 6, NULL, NULL),
    ('50001048', '2026-10-28', '16:07', 'Tarde', NULL, '10001057', '2022100186', 6, NULL, NULL),
    ('50001049', '2026-10-29', '08:07', 'Mañana', NULL, '10001058', '2022100519', 1, NULL, NULL),
    ('50001050', '2026-10-29', '08:08', 'Mañana', NULL, '10001059', '2022100260', 2, NULL, NULL),
    ('50001051', '2026-10-29', '08:12', 'Mañana', NULL, '10001061', '2022101000', 1, NULL, NULL),
    ('50001052', '2026-10-29', '08:04', 'Mañana', NULL, '10001062', '2022100852', 1, NULL, NULL),
    ('50001053', '2026-10-29', '10:05', 'Mañana', NULL, '10001064', '2022100704', 5, NULL, NULL),
    ('50001054', '2026-10-29', '14:07', 'Tarde', NULL, '10001065', '2022100297', 3, NULL, NULL),
    ('50001055', '2026-10-29', '16:08', 'Tarde', NULL, '10001068', '2022100852', 6, NULL, NULL),
    ('50001056', '2026-10-30', '08:02', 'Mañana', NULL, '10001069', '2022100186', 1, NULL, NULL),
    ('50001057', '2026-10-30', '08:05', 'Mañana', NULL, '10001070', '2022110647', 1, NULL, NULL),
    ('50001058', '2026-10-30', '08:12', 'Mañana', NULL, '10001071', '2022100038', 2, NULL, NULL),
    ('50001059', '2026-10-30', '08:10', 'Mañana', NULL, '10001073', '2022100408', 5, NULL, NULL),
    ('50001060', '2026-10-30', '10:01', 'Mañana', NULL, '10001074', '2022100186', 2, NULL, NULL),
    ('50001061', '2026-10-30', '14:09', 'Tarde', NULL, '10001077', '2022100186', 3, NULL, NULL),
    ('50001062', '2026-10-30', '14:01', 'Tarde', NULL, '10001078', '2021248861', 3, NULL, NULL),
    ('50001063', '2026-10-30', '14:04', 'Tarde', 'Exodoncia', '10001079', '2022100519', 3, 1, 5),
    ('50001064', '2026-10-31', '10:11', 'Mañana', NULL, '10001081', '2022100223', 2, NULL, NULL),
    ('50001065', '2026-10-31', '10:08', 'Mañana', NULL, '10001082', '2022100112', 1, NULL, NULL),
    ('50001066', '2026-10-31', '10:09', 'Mañana', NULL, '10001083', '2022100889', 2, NULL, NULL),
    ('50001067', '2026-10-31', '16:13', 'Tarde', NULL, '10001085', '2022100186', 4, NULL, NULL),
    ('50001068', '2026-11-02', '08:06', 'Mañana', NULL, '10001086', '2022100889', 1, NULL, NULL),
    ('50001069', '2026-11-02', '08:05', 'Mañana', 'Radiografía panorámica', '10001087', '2022100852', 2, 2, 3),
    ('50001070', '2026-11-02', '10:13', 'Mañana', NULL, '10001088', '2022110419', 1, NULL, NULL),
    ('50001071', '2026-11-02', '10:01', 'Mañana', NULL, '10001089', '2022110582', 1, NULL, NULL),
    ('50001072', '2026-11-02', '10:04', 'Mañana', NULL, '10001090', '2022110419', 1, NULL, NULL),
    ('50001073', '2026-11-02', '10:10', 'Mañana', NULL, '10001091', '2022100075', 1, NULL, NULL),
    ('50001074', '2026-11-02', '10:01', 'Mañana', NULL, '10001092', '2022100186', 2, NULL, NULL),
    ('50001075', '2026-11-02', '14:07', 'Tarde', NULL, '10001093', '2022110236', 4, NULL, NULL),
    ('50001076', '2026-11-02', '14:00', 'Tarde', NULL, '10001094', '2022100038', 4, NULL, NULL),
    ('50001077', '2026-11-02', '14:01', 'Tarde', NULL, '10001095', '2022100001', 4, NULL, NULL),
    ('50001078', '2026-11-03', '08:09', 'Mañana', NULL, '10001097', '2022100038', 5, NULL, NULL),
    ('50001079', '2026-11-03', '08:07', 'Mañana', NULL, '10001098', '2022100593', 2, NULL, NULL),
    ('50001080', '2026-11-03', '10:08', 'Mañana', NULL, '10001099', '2022100223', 2, NULL, NULL),
    ('50001081', '2026-11-03', '10:05', 'Mañana', NULL, '10001100', '2022100371', 5, NULL, NULL),
    ('50001082', '2026-11-03', '10:07', 'Mañana', NULL, '10001101', '2022100519', 5, NULL, NULL),
    ('50001083', '2026-11-03', '14:09', 'Tarde', NULL, '10001102', '2022100963', 4, NULL, NULL),
    ('50001084', '2026-11-03', '14:04', 'Tarde', NULL, '10001103', '2021248861', 4, NULL, NULL),
    ('50001085', '2026-11-03', '14:04', 'Tarde', NULL, '10001104', '2022100889', 6, NULL, NULL),
    ('50001086', '2026-11-03', '14:14', 'Tarde', 'Radiografía panorámica', '10001105', '2022100223', 6, 2, 3),
    ('50001087', '2026-11-03', '16:09', 'Tarde', NULL, '10001106', '2022100852', 6, NULL, NULL),
    ('50001088', '2026-11-03', '16:11', 'Tarde', NULL, '10001107', '2022110419', 3, NULL, NULL),
    ('50001089', '2026-11-04', '08:12', 'Mañana', NULL, '10001108', '2022100075', 2, NULL, NULL),
    ('50001090', '2026-11-04', '08:06', 'Mañana', NULL, '10001110', '2021249145', 5, NULL, NULL),
    ('50001091', '2026-11-04', '10:12', 'Mañana', NULL, '10001111', '2022100630', 1, NULL, NULL),
    ('50001092', '2026-11-04', '10:04', 'Mañana', NULL, '10001112', '2022110419', 1, NULL, NULL),
    ('50001093', '2026-11-04', '14:03', 'Tarde', NULL, '10001113', '2022100223', 4, NULL, NULL),
    ('50001094', '2026-11-04', '14:03', 'Tarde', NULL, '10001114', '2022100223', 6, NULL, NULL),
    ('50001095', '2026-11-04', '14:12', 'Tarde', 'Radiografía panorámica', '10001115', '2022100482', 3, 2, 4),
    ('50001096', '2026-11-04', '16:14', 'Tarde', NULL, '10001116', '2022100260', 3, NULL, NULL),
    ('50001097', '2026-11-04', '16:14', 'Tarde', NULL, '10001117', '2022110419', 6, NULL, NULL),
    ('50001098', '2026-11-04', '16:11', 'Tarde', NULL, '10001118', '2022110236', 3, NULL, NULL),
    ('50001099', '2026-11-05', '08:03', 'Mañana', NULL, '10001119', '2022100445', 1, NULL, NULL),
    ('50001100', '2026-11-05', '08:10', 'Mañana', NULL, '10001120', '2022100408', 5, NULL, NULL),
    ('50001101', '2026-11-05', '08:05', 'Mañana', NULL, '10001121', '2022100889', 2, NULL, NULL),
    ('50001102', '2026-11-05', '08:10', 'Mañana', NULL, '10001122', '2022101037', 1, NULL, NULL),
    ('50001103', '2026-11-05', '10:03', 'Mañana', NULL, '10001123', '2022100149', 2, NULL, NULL),
    ('50001104', '2026-11-05', '10:00', 'Mañana', NULL, '10001124', '2022100852', 5, NULL, NULL),
    ('50001105', '2026-11-05', '10:04', 'Mañana', NULL, '10001125', '2022100334', 1, NULL, NULL),
    ('50001106', '2026-11-05', '14:01', 'Tarde', NULL, '10001126', '2022100519', 4, NULL, NULL),
    ('50001107', '2026-11-05', '14:11', 'Tarde', 'Radiografía panorámica', '10001127', '2022100408', 3, 2, 6),
    ('50001108', '2026-11-05', '16:07', 'Tarde', NULL, '10001128', '2021249013', 4, NULL, NULL),
    ('50001109', '2026-11-05', '16:12', 'Tarde', NULL, '10001129', '2022100408', 4, NULL, NULL),
    ('50001110', '2026-11-06', '08:10', 'Mañana', 'Cirugía de terceros molares', '10001132', '2021248861', 2, 1, 5),
    ('50001111', '2026-11-06', '10:11', 'Mañana', NULL, '10001134', '2022100926', 1, NULL, NULL),
    ('50001112', '2026-11-06', '10:11', 'Mañana', NULL, '10001135', '2022100926', 1, NULL, NULL),
    ('50001113', '2026-11-06', '14:12', 'Tarde', NULL, '10001136', '2022101000', 3, NULL, NULL),
    ('50001114', '2026-11-06', '14:02', 'Tarde', NULL, '10001137', '2022100075', 4, NULL, NULL),
    ('50001115', '2026-11-06', '14:08', 'Tarde', NULL, '10001138', '2022100741', 6, NULL, NULL),
    ('50001116', '2026-11-06', '16:14', 'Tarde', NULL, '10001140', '2022100334', 3, NULL, NULL),
    ('50001117', '2026-11-07', '08:00', 'Mañana', NULL, '10001141', '2022100112', 5, NULL, NULL),
    ('50001118', '2026-11-07', '08:14', 'Mañana', NULL, '10001142', '2022100038', 2, NULL, NULL),
    ('50001119', '2026-11-07', '08:00', 'Mañana', NULL, '10001143', '2022110378', 5, NULL, NULL),
    ('50001120', '2026-11-07', '10:02', 'Mañana', NULL, '10001144', '2022101074', 5, NULL, NULL),
    ('50001121', '2026-11-07', '16:08', 'Tarde', NULL, '10001146', '2022110582', 4, NULL, NULL),
    ('50001122', '2026-11-09', '08:03', 'Mañana', NULL, '10001147', '2022110419', 2, NULL, NULL),
    ('50001123', '2026-11-09', '10:03', 'Mañana', NULL, '10001149', '2022100926', 2, NULL, NULL),
    ('50001124', '2026-11-09', '10:04', 'Mañana', NULL, '10001151', '2022100593', 1, NULL, NULL),
    ('50001125', '2026-11-09', '10:10', 'Mañana', NULL, '10001152', '2022100038', 5, NULL, NULL),
    ('50001126', '2026-11-09', '14:02', 'Tarde', NULL, '10001153', '2022100001', 4, NULL, NULL),
    ('50001127', '2026-11-09', '14:10', 'Tarde', NULL, '10001154', '2022100482', 6, NULL, NULL),
    ('50001128', '2026-11-09', '14:01', 'Tarde', 'Radiografía panorámica', '10001155', '2022110582', 4, 2, 4),
    ('50001129', '2026-11-09', '16:02', 'Tarde', NULL, '10001156', '2022100038', 4, NULL, NULL),
    ('50001130', '2026-11-10', '08:06', 'Mañana', NULL, '10001158', '2022110419', 5, NULL, NULL),
    ('50001131', '2026-11-10', '08:08', 'Mañana', NULL, '10001159', '2022101000', 2, NULL, NULL),
    ('50001132', '2026-11-10', '08:12', 'Mañana', 'Exodoncia', '10001160', '2022100371', 2, 1, 2),
    ('50001133', '2026-11-10', '10:14', 'Mañana', NULL, '10001161', '2022100778', 5, NULL, NULL),
    ('50001134', '2026-11-10', '10:13', 'Mañana', NULL, '10001162', '2022100149', 2, NULL, NULL),
    ('50001135', '2026-11-10', '14:08', 'Tarde', NULL, '10001163', '2022110419', 3, NULL, NULL),
    ('50001136', '2026-11-10', '14:10', 'Tarde', NULL, '10001164', '2022110793', 3, NULL, NULL),
    ('50001137', '2026-11-10', '16:14', 'Tarde', NULL, '10001165', '2022101037', 3, NULL, NULL),
    ('50001138', '2026-11-10', '16:00', 'Tarde', NULL, '10001166', '2022110647', 6, NULL, NULL),
    ('50001139', '2026-11-10', '16:02', 'Tarde', NULL, '10001167', '2022110582', 6, NULL, NULL),
    ('50001140', '2026-11-10', '16:08', 'Tarde', NULL, '10001168', '2022100519', 6, NULL, NULL),
    ('50001141', '2026-11-11', '08:02', 'Mañana', NULL, '10001169', '2022100630', 2, NULL, NULL),
    ('50001142', '2026-11-11', '08:04', 'Mañana', NULL, '10001170', '2022100704', 5, NULL, NULL),
    ('50001143', '2026-11-11', '10:07', 'Mañana', NULL, '10001171', '2022100963', 1, NULL, NULL),
    ('50001144', '2026-11-11', '10:07', 'Mañana', NULL, '10001172', '2022101037', 5, NULL, NULL),
    ('50001145', '2026-11-11', '10:06', 'Mañana', NULL, '10001173', '2022100334', 5, NULL, NULL),
    ('50001146', '2026-11-11', '10:06', 'Mañana', NULL, '10001174', '2022100186', 5, NULL, NULL),
    ('50001147', '2026-11-11', '14:08', 'Tarde', NULL, '10001176', '2022100519', 6, NULL, NULL),
    ('50001148', '2026-11-11', '14:08', 'Tarde', 'Radiografía panorámica', '10001177', '2021249013', 3, 2, 6),
    ('50001149', '2026-11-11', '16:10', 'Tarde', NULL, '10001178', '2022100667', 6, NULL, NULL),
    ('50001150', '2026-11-11', '16:00', 'Tarde', NULL, '10001179', '2022100852', 6, NULL, NULL),
    ('50001151', '2026-11-12', '08:12', 'Mañana', NULL, '10001180', '2022101074', 2, NULL, NULL),
    ('50001152', '2026-11-12', '08:12', 'Mañana', NULL, '10001181', '2022100260', 1, NULL, NULL),
    ('50001153', '2026-11-12', '08:06', 'Mañana', NULL, '10001182', '2022100260', 2, NULL, NULL),
    ('50001154', '2026-11-12', '08:04', 'Mañana', NULL, '10001183', '2022100482', 1, NULL, NULL),
    ('50001155', '2026-11-12', '08:12', 'Mañana', NULL, '10001184', '2022100556', 5, NULL, NULL),
    ('50001156', '2026-11-12', '14:03', 'Tarde', 'Exodoncia', '10001186', '2022100001', 3, 1, 1),
    ('50001157', '2026-11-12', '16:03', 'Tarde', NULL, '10001187', '2022100075', 6, NULL, NULL),
    ('50001158', '2026-11-12', '16:00', 'Tarde', NULL, '10001189', '2022110647', 6, NULL, NULL),
    ('50001159', '2026-11-12', '16:02', 'Tarde', NULL, '10001190', '2022100519', 4, NULL, NULL),
    ('50001160', '2026-11-13', '08:00', 'Mañana', NULL, '10001191', '2022110236', 1, NULL, NULL),
    ('50001161', '2026-11-13', '08:08', 'Mañana', NULL, '10001192', '2022100408', 2, NULL, NULL),
    ('50001162', '2026-11-13', '08:08', 'Mañana', NULL, '10001193', '2022110582', 2, NULL, NULL),
    ('50001163', '2026-11-13', '08:03', 'Mañana', 'Radiografía periapical', '10001194', '2022100482', 1, 2, 4),
    ('50001164', '2026-11-13', '10:10', 'Mañana', NULL, '10001196', '2022101074', 5, NULL, NULL),
    ('50001165', '2026-11-13', '10:14', 'Mañana', NULL, '10001197', '2022100297', 2, NULL, NULL),
    ('50001166', '2026-11-13', '10:10', 'Mañana', NULL, '10001199', '2022101074', 1, NULL, NULL),
    ('50001167', '2026-11-13', '14:04', 'Tarde', NULL, '10001200', '2021249013', 6, NULL, NULL),
    ('50001168', '2026-11-13', '16:09', 'Tarde', NULL, '10001201', '2021249145', 6, NULL, NULL),
    ('50001169', '2026-11-14', '10:13', 'Mañana', NULL, '10001202', '2022100593', 1, NULL, NULL),
    ('50001170', '2026-11-14', '10:11', 'Mañana', NULL, '10001203', '2021248861', 5, NULL, NULL),
    ('50001171', '2026-11-14', '14:05', 'Tarde', NULL, '10001204', '2022100852', 4, NULL, NULL),
    ('50001172', '2026-11-14', '14:08', 'Tarde', NULL, '10001205', '2022100371', 4, NULL, NULL),
    ('50001173', '2026-11-14', '16:04', 'Tarde', NULL, '10001206', '2022100445', 3, NULL, NULL),
    ('50001174', '2026-11-14', '16:11', 'Tarde', NULL, '10001207', '2022100001', 4, NULL, NULL),
    ('50001175', '2026-11-16', '08:04', 'Mañana', NULL, '10001208', '2022100667', 2, NULL, NULL),
    ('50001176', '2026-11-16', '08:10', 'Mañana', NULL, '10001209', '2022110236', 5, NULL, NULL),
    ('50001177', '2026-11-16', '08:13', 'Mañana', NULL, '10001210', '2022100149', 1, NULL, NULL),
    ('50001178', '2026-11-16', '08:05', 'Mañana', NULL, '10001211', '2022100149', 2, NULL, NULL),
    ('50001179', '2026-11-16', '10:00', 'Mañana', NULL, '10001212', '2022100667', 5, NULL, NULL),
    ('50001180', '2026-11-16', '14:06', 'Tarde', NULL, '10001215', '2022110236', 4, NULL, NULL),
    ('50001181', '2026-11-16', '14:05', 'Tarde', NULL, '10001216', '2021248902', 6, NULL, NULL),
    ('50001182', '2026-11-16', '14:10', 'Tarde', 'Cirugía de terceros molares', '10001217', '2022100889', 4, 1, 1),
    ('50001183', '2026-11-16', '16:09', 'Tarde', NULL, '10001218', '2022100556', 6, NULL, NULL),
    ('50001184', '2026-11-17', '10:11', 'Mañana', NULL, '10001220', '2022100593', 5, NULL, NULL),
    ('50001185', '2026-11-17', '10:01', 'Mañana', NULL, '10001221', '2022100038', 2, NULL, NULL),
    ('50001186', '2026-11-17', '10:04', 'Mañana', NULL, '10001222', '2022100075', 1, NULL, NULL),
    ('50001187', '2026-11-17', '10:05', 'Mañana', NULL, '10001223', '2022100371', 1, NULL, NULL),
    ('50001188', '2026-11-17', '10:05', 'Mañana', NULL, '10001225', '2022101000', 2, NULL, NULL),
    ('50001189', '2026-11-17', '14:08', 'Tarde', NULL, '10001226', '2022110647', 3, NULL, NULL),
    ('50001190', '2026-11-17', '14:11', 'Tarde', NULL, '10001227', '2022100112', 4, NULL, NULL),
    ('50001191', '2026-11-17', '14:07', 'Tarde', 'Cirugía de terceros molares', '10001228', '2022100556', 3, 1, 5),
    ('50001192', '2026-11-17', '16:03', 'Tarde', NULL, '10001229', '2022100001', 3, NULL, NULL);

INSERT INTO permiso (codigo_ingreso, hora_salida, hora_retorno, motivo) VALUES
    ('50001020', '08:59', '09:28', 'Recoger instrumental'),
    ('50001021', '10:42', '10:54', 'Consulta con docente'),
    ('50001023', '10:56', '11:04', 'Compra de material'),
    ('50001024', '10:48', '11:17', 'Trámite en caja'),
    ('50001033', '10:58', '11:14', 'Consulta con docente'),
    ('50001039', '16:59', '17:20', 'Laboratorio dental'),
    ('50001045', '16:55', '17:06', 'Laboratorio dental'),
    ('50001046', '16:32', '16:48', 'Compra de material'),
    ('50001051', '08:42', '08:53', 'Compra de material'),
    ('50001052', '08:40', '09:25', 'Compra de material'),
    ('50001054', '14:52', '15:38', 'Compra de material'),
    ('50001056', '08:33', '08:51', 'Laboratorio dental'),
    ('50001065', '10:55', '11:15', 'Recoger radiografía'),
    ('50001067', '16:47', '17:46', 'Recoger radiografía'),
    ('50001069', '08:46', '09:13', 'Consulta con docente'),
    ('50001070', '10:43', '11:03', 'Laboratorio dental'),
    ('50001071', '10:29', '10:48', 'Recoger instrumental'),
    ('50001074', '10:40', '10:51', 'Trámite en caja'),
    ('50001077', '14:30', '14:47', 'Consulta con docente'),
    ('50001086', '14:40', '15:25', 'Compra de material'),
    ('50001090', '09:01', '09:24', 'Laboratorio dental'),
    ('50001091', '11:07', '11:31', 'Trámite en caja'),
    ('50001092', '10:41', '11:33', 'Compra de material'),
    ('50001093', '14:45', '15:10', 'Compra de material'),
    ('50001095', '14:57', '15:24', 'Consulta con docente'),
    ('50001097', '16:42', '17:11', 'Laboratorio dental'),
    ('50001098', '16:49', '17:35', 'Recoger instrumental'),
    ('50001102', '08:39', '09:02', 'Laboratorio dental'),
    ('50001107', '14:42', '14:55', 'Compra de material'),
    ('50001111', '11:01', '11:09', 'Recoger radiografía'),
    ('50001112', '10:37', '11:07', 'Compra de material'),
    ('50001117', '08:25', '08:45', 'Recoger radiografía'),
    ('50001120', '10:46', '10:56', 'Recoger instrumental'),
    ('50001125', '10:58', '11:10', 'Recoger instrumental'),
    ('50001127', '14:36', '15:04', 'Compra de material'),
    ('50001130', '08:37', '08:56', 'Laboratorio dental'),
    ('50001132', '08:43', '09:02', 'Compra de material'),
    ('50001134', '10:49', '11:39', 'Trámite en caja'),
    ('50001136', '14:35', '14:54', 'Recoger radiografía'),
    ('50001140', '16:58', '17:23', 'Laboratorio dental'),
    ('50001141', '08:55', '09:57', 'Recoger radiografía'),
    ('50001142', '08:48', '08:57', 'Recoger instrumental'),
    ('50001144', '10:49', '11:11', 'Compra de material'),
    ('50001151', '08:56', '09:13', 'Recoger radiografía'),
    ('50001153', '08:51', '09:12', 'Recoger instrumental'),
    ('50001156', '14:41', '15:05', 'Laboratorio dental'),
    ('50001160', '08:44', '09:01', 'Laboratorio dental'),
    ('50001163', '08:52', '09:17', 'Recoger instrumental'),
    ('50001168', '16:53', '17:03', 'Consulta con docente'),
    ('50001178', '08:38', '09:04', 'Recoger instrumental'),
    ('50001180', '14:35', '14:43', 'Recoger radiografía'),
    ('50001185', '10:35', '10:57', 'Compra de material'),
    ('50001186', '10:31', '10:53', 'Recoger radiografía'),
    ('50001188', '10:33', '10:53', 'Trámite en caja');

INSERT INTO esterilizacion (codigo_ingreso, hora_inicio, hora_fin, asistencia) VALUES
    ('50001020', '10:02', '10:33', 'Asistió'),
    ('50001021', '11:48', '12:21', 'Asistió'),
    ('50001022', '11:43', '12:07', 'Asistió'),
    ('50001023', '11:48', '12:13', 'Asistió'),
    ('50001024', '12:02', '12:20', 'Asistió'),
    ('50001025', '16:01', '16:29', 'Asistió'),
    ('50001026', '15:54', '16:13', 'Asistió'),
    ('50001027', '15:49', '16:15', 'Asistió'),
    ('50001028', '17:54', '18:28', 'Asistió'),
    ('50001029', '18:04', '18:32', 'Asistió'),
    ('50001030', '09:47', NULL, 'No asistió'),
    ('50001031', '09:51', '10:24', 'Asistió'),
    ('50001032', '10:05', '10:40', 'Asistió'),
    ('50001033', '11:52', '12:27', 'Asistió'),
    ('50001034', '11:47', '12:18', 'Asistió'),
    ('50001035', '16:05', '16:40', 'Asistió'),
    ('50001036', '15:50', '16:09', 'Asistió'),
    ('50001037', '17:44', '18:02', 'Asistió'),
    ('50001038', '17:54', '18:17', 'Asistió'),
    ('50001039', '17:53', '18:20', 'Asistió'),
    ('50001040', '09:49', '10:20', 'Asistió'),
    ('50001041', '09:49', NULL, 'No asistió'),
    ('50001042', '11:42', '12:17', 'Asistió'),
    ('50001043', '16:02', '16:28', 'Asistió'),
    ('50001044', '15:58', '16:19', 'Asistió'),
    ('50001045', '17:50', '18:25', 'Asistió'),
    ('50001046', '17:41', '18:01', 'Asistió'),
    ('50001047', '17:45', '18:10', 'Asistió'),
    ('50001048', '17:58', '18:26', 'Asistió'),
    ('50001049', '09:58', '10:20', 'Asistió'),
    ('50001050', '09:43', '10:17', 'Asistió'),
    ('50001051', '10:00', '10:18', 'Asistió'),
    ('50001052', '09:45', '10:20', 'Asistió'),
    ('50001053', '11:56', '12:15', 'Asistió'),
    ('50001054', '15:51', '16:10', 'Asistió'),
    ('50001055', '17:50', '18:09', 'Asistió'),
    ('50001056', '09:45', '10:08', 'Asistió'),
    ('50001057', '09:56', '10:29', 'Asistió'),
    ('50001058', '09:50', '10:20', 'Asistió'),
    ('50001059', '09:56', '10:14', 'Asistió'),
    ('50001060', '11:41', '12:16', 'Asistió'),
    ('50001061', '15:49', '16:23', 'Asistió'),
    ('50001062', '15:45', '16:11', 'Asistió'),
    ('50001063', '15:53', '16:14', 'Asistió'),
    ('50001064', '11:59', '12:27', 'Asistió'),
    ('50001065', '11:53', '12:14', 'Asistió'),
    ('50001066', '12:01', '12:36', 'Asistió'),
    ('50001067', '17:57', '18:28', 'Asistió'),
    ('50001068', '09:57', '10:31', 'Asistió'),
    ('50001069', '09:47', '10:17', 'Asistió'),
    ('50001070', '11:53', '12:17', 'Asistió'),
    ('50001071', '11:52', '12:13', 'Asistió'),
    ('50001072', '11:49', '12:21', 'Asistió'),
    ('50001073', '12:02', '12:30', 'Asistió'),
    ('50001074', '11:49', '12:11', 'Asistió'),
    ('50001075', '15:43', '16:12', 'Asistió'),
    ('50001076', '15:37', '16:12', 'Asistió'),
    ('50001077', '15:49', '16:14', 'Asistió'),
    ('50001078', '09:52', NULL, 'No asistió'),
    ('50001079', '09:50', '10:22', 'Asistió'),
    ('50001080', '11:50', NULL, 'No asistió'),
    ('50001081', '11:43', '12:13', 'Asistió'),
    ('50001082', '11:53', '12:24', 'Asistió'),
    ('50001083', '15:44', '16:14', 'Asistió'),
    ('50001084', '15:53', NULL, 'No asistió'),
    ('50001085', '15:42', '16:13', 'Asistió'),
    ('50001086', '16:00', '16:35', 'Asistió'),
    ('50001087', '17:45', '18:06', 'Asistió'),
    ('50001088', '17:48', '18:18', 'Asistió'),
    ('50001089', '10:00', '10:26', 'Asistió'),
    ('50001090', '09:45', '10:12', 'Asistió'),
    ('50001091', '11:51', '12:14', 'Asistió'),
    ('50001092', '11:39', '11:59', 'Asistió'),
    ('50001093', '15:45', '16:14', 'Asistió'),
    ('50001094', '15:50', '16:23', 'Asistió'),
    ('50001095', '16:04', NULL, 'No asistió'),
    ('50001096', '17:50', '18:12', 'Asistió'),
    ('50001097', '17:51', '18:18', 'Asistió'),
    ('50001098', '17:52', '18:10', 'Asistió'),
    ('50001099', '09:53', '10:26', 'Asistió'),
    ('50001100', '09:51', '10:17', 'Asistió'),
    ('50001101', '09:42', '10:00', 'Asistió'),
    ('50001102', '09:48', '10:17', 'Asistió'),
    ('50001103', '11:46', '12:18', 'Asistió'),
    ('50001104', '11:40', '12:02', 'Asistió'),
    ('50001105', '11:48', '12:19', 'Asistió'),
    ('50001106', '15:42', '16:15', 'Asistió'),
    ('50001107', '16:00', '16:25', 'Asistió'),
    ('50001108', '17:51', '18:10', 'Asistió'),
    ('50001109', '17:49', '18:23', 'Asistió'),
    ('50001110', '09:53', '10:19', 'Asistió'),
    ('50001111', '11:58', '12:27', 'Asistió'),
    ('50001112', '11:56', '12:14', 'Asistió'),
    ('50001113', '16:01', '16:25', 'Asistió'),
    ('50001114', '15:38', '15:57', 'Asistió'),
    ('50001115', '15:59', '16:20', 'Asistió'),
    ('50001116', '18:00', '18:18', 'Asistió'),
    ('50001117', '09:49', '10:20', 'Asistió'),
    ('50001118', '09:56', '10:16', 'Asistió'),
    ('50001119', '09:49', '10:17', 'Asistió'),
    ('50001120', '11:43', '12:02', 'Asistió'),
    ('50001121', '17:46', '18:07', 'Asistió'),
    ('50001122', '09:51', '10:25', 'Asistió'),
    ('50001123', '11:42', '12:14', 'Asistió'),
    ('50001124', '11:43', '12:06', 'Asistió'),
    ('50001125', '11:54', '12:16', 'Asistió'),
    ('50001126', '15:51', '16:09', 'Asistió'),
    ('50001127', '16:02', '16:37', 'Asistió'),
    ('50001128', '15:37', '16:02', 'Asistió'),
    ('50001129', '17:48', '18:19', 'Asistió'),
    ('50001130', '09:42', '10:00', 'Asistió'),
    ('50001131', '09:53', '10:18', 'Asistió'),
    ('50001132', '09:48', '10:07', 'Asistió'),
    ('50001133', '12:04', '12:25', 'Asistió'),
    ('50001134', '11:59', NULL, 'No asistió'),
    ('50001135', '15:49', '16:09', 'Asistió'),
    ('50001136', '15:45', '16:06', 'Asistió'),
    ('50001137', '17:52', '18:16', 'Asistió'),
    ('50001138', '17:51', '18:11', 'Asistió'),
    ('50001139', '17:41', '18:05', 'Asistió'),
    ('50001140', '17:58', '18:25', 'Asistió'),
    ('50001141', '09:52', '10:24', 'Asistió'),
    ('50001142', '09:50', '10:17', 'Asistió'),
    ('50001143', '11:52', '12:17', 'Asistió'),
    ('50001144', '11:42', '12:12', 'Asistió'),
    ('50001145', '11:42', '12:14', 'Asistió'),
    ('50001146', '11:45', '12:15', 'Asistió'),
    ('50001147', '15:56', '16:31', 'Asistió'),
    ('50001148', '15:50', '16:13', 'Asistió'),
    ('50001149', '17:55', '18:28', 'Asistió'),
    ('50001150', '17:50', '18:08', 'Asistió'),
    ('50001151', '10:02', '10:21', 'Asistió'),
    ('50001152', '09:53', '10:25', 'Asistió'),
    ('50001153', '09:56', '10:28', 'Asistió'),
    ('50001154', '09:45', '10:12', 'Asistió'),
    ('50001155', '09:58', '10:18', 'Asistió'),
    ('50001156', '15:43', '16:06', 'Asistió'),
    ('50001157', '17:41', '18:07', 'Asistió'),
    ('50001158', '17:46', '18:09', 'Asistió'),
    ('50001159', '17:52', '18:16', 'Asistió'),
    ('50001160', '09:36', '10:07', 'Asistió'),
    ('50001161', '09:44', NULL, 'No asistió'),
    ('50001162', '10:00', '10:18', 'Asistió'),
    ('50001163', '09:44', '10:18', 'Asistió'),
    ('50001164', '11:45', '12:06', 'Asistió'),
    ('50001165', '11:58', '12:27', 'Asistió'),
    ('50001166', '11:49', '12:08', 'Asistió'),
    ('50001167', '15:44', '16:04', 'Asistió'),
    ('50001168', '17:49', '18:14', 'Asistió'),
    ('50001169', '11:57', '12:29', 'Asistió'),
    ('50001170', '11:54', '12:28', 'Asistió'),
    ('50001171', '15:53', '16:15', 'Asistió'),
    ('50001172', '15:56', '16:30', 'Asistió'),
    ('50001173', '17:45', '18:14', 'Asistió'),
    ('50001174', '17:58', '18:33', 'Asistió'),
    ('50001175', '09:45', '10:20', 'Asistió'),
    ('50001176', '09:54', '10:20', 'Asistió'),
    ('50001177', '09:56', NULL, 'No asistió'),
    ('50001178', '09:51', '10:21', 'Asistió'),
    ('50001179', '11:46', '12:21', 'Asistió'),
    ('50001180', '15:57', '16:32', 'Asistió'),
    ('50001181', '15:51', '16:23', 'Asistió'),
    ('50001182', '15:57', '16:30', 'Asistió'),
    ('50001183', '17:47', '18:19', 'Asistió'),
    ('50001184', '12:03', '12:36', 'Asistió'),
    ('50001185', '11:51', '12:25', 'Asistió'),
    ('50001186', '11:43', '12:07', 'Asistió'),
    ('50001187', '11:55', '12:27', 'Asistió'),
    ('50001188', '11:45', '12:09', 'Asistió'),
    ('50001189', '15:58', '16:24', 'Asistió'),
    ('50001190', '15:49', '16:13', 'Asistió'),
    ('50001191', '15:51', '16:18', 'Asistió'),
    ('50001192', '17:46', '18:21', 'Asistió');

COMMIT;

-- Conteo final por tabla
SELECT 'paciente' AS tabla, COUNT(*) AS filas FROM paciente
UNION ALL SELECT 'alumno', COUNT(*) FROM alumno
UNION ALL SELECT 'personal', COUNT(*) FROM personal
UNION ALL SELECT 'programacion', COUNT(*) FROM programacion
UNION ALL SELECT 'ingreso', COUNT(*) FROM ingreso
UNION ALL SELECT 'permiso', COUNT(*) FROM permiso
UNION ALL SELECT 'esterilizacion', COUNT(*) FROM esterilizacion;


-- #####################################################################
-- ##  09_funciones_procedimientos.sql
-- #####################################################################

-- =====================================================================
--  Script 9 - Funciones y procedimientos almacenados del aplicativo
--  Base de datos: bd_ingreso_odontologico (MySQL 8.0)
--  Ejecutar con root en Workbench, después de 01, 11 y 02.
--  El aplicativo PHP no escribe consultas: solo llama a estas rutinas.
--    - FUNCIONES      : devuelven un solo valor   -> SELECT fn_...(...)
--    - PROCEDIMIENTOS : devuelven filas (listas)  -> CALL sp_...(...)
-- =====================================================================
SET NAMES utf8mb4;
USE bd_ingreso_odontologico;

DROP FUNCTION  IF EXISTS fn_dia_semana;
DROP FUNCTION  IF EXISTS fn_fecha_con_datos;
DROP FUNCTION  IF EXISTS fn_citas_dia;
DROP FUNCTION  IF EXISTS fn_ingresos_dia;
DROP FUNCTION  IF EXISTS fn_permisos_abiertos;
DROP FUNCTION  IF EXISTS fn_esterilizaciones_curso;
DROP FUNCTION  IF EXISTS fn_total_sillones;
DROP PROCEDURE IF EXISTS sp_info_servidor;
DROP PROCEDURE IF EXISTS sp_conteo_tablas;
DROP PROCEDURE IF EXISTS sp_objetos_base;
DROP PROCEDURE IF EXISTS sp_listar_personal;
DROP PROCEDURE IF EXISTS sp_obtener_personal;
DROP PROCEDURE IF EXISTS sp_ocupacion_sillones;
DROP PROCEDURE IF EXISTS sp_agenda_dia;
DROP PROCEDURE IF EXISTS sp_agenda_fecha;
DROP PROCEDURE IF EXISTS sp_buscar_alumno_qr;
DROP PROCEDURE IF EXISTS sp_atenciones_alumno;
DROP PROCEDURE IF EXISTS sp_ingresos_dia;

DELIMITER $$

-- ---------------------------------------------------------------------
--  FUNCIONES
-- ---------------------------------------------------------------------

-- Nombre del día de la semana de una fecha (Lunes ... Domingo)
CREATE FUNCTION fn_dia_semana(p_fecha DATE)
RETURNS VARCHAR(9)
DETERMINISTIC
BEGIN
    RETURN ELT(WEEKDAY(p_fecha) + 1,
               'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo');
END$$

-- Devuelve la fecha pedida si tiene ingresos; si no, la última fecha con ingresos
CREATE FUNCTION fn_fecha_con_datos(p_fecha DATE)
RETURNS DATE
READS SQL DATA
BEGIN
    IF EXISTS (SELECT 1 FROM ingreso WHERE fecha = p_fecha) THEN
        RETURN p_fecha;
    END IF;
    RETURN COALESCE((SELECT MAX(fecha) FROM ingreso), p_fecha);
END$$

-- Cantidad de citas pendientes (vigentes, sin asistencia ni ingreso) de un día de la semana
CREATE FUNCTION fn_citas_dia(p_dia VARCHAR(9))
RETURNS INT
READS SQL DATA
BEGIN
    RETURN (SELECT COUNT(*) FROM programacion p
            WHERE p.dia_semana = p_dia AND p.activo = 1 AND p.asistencia IS NULL
              AND NOT EXISTS (SELECT 1 FROM ingreso i WHERE i.codigo_programacion = p.codigo_programacion));
END$$

-- Cantidad de ingresos de una fecha; si el turno es NULL cuenta todo el día
CREATE FUNCTION fn_ingresos_dia(p_fecha DATE, p_turno VARCHAR(6))
RETURNS INT
READS SQL DATA
BEGIN
    RETURN (SELECT COUNT(*) FROM ingreso
            WHERE fecha = p_fecha
              AND (p_turno IS NULL OR turno = p_turno));
END$$

-- Alumnos que siguen fuera con permiso (sin hora de retorno) en una fecha
CREATE FUNCTION fn_permisos_abiertos(p_fecha DATE)
RETURNS INT
READS SQL DATA
BEGIN
    RETURN (SELECT COUNT(*)
            FROM permiso pm
            JOIN ingreso i ON i.codigo_ingreso = pm.codigo_ingreso
            WHERE i.fecha = p_fecha AND pm.hora_retorno IS NULL);
END$$

-- Ciclos de esterilización sin hora de fin en una fecha
CREATE FUNCTION fn_esterilizaciones_curso(p_fecha DATE)
RETURNS INT
READS SQL DATA
BEGIN
    RETURN (SELECT COUNT(*)
            FROM esterilizacion e
            JOIN ingreso i ON i.codigo_ingreso = e.codigo_ingreso
            WHERE i.fecha = p_fecha AND e.hora_fin IS NULL AND e.asistencia = 'Asistió');
END$$

-- Total de sillones en servicio
CREATE FUNCTION fn_total_sillones()
RETURNS INT
READS SQL DATA
BEGIN
    RETURN (SELECT COUNT(*) FROM sillon WHERE activo = 1);
END$$

-- ---------------------------------------------------------------------
--  PROCEDIMIENTOS: prueba de conexión
-- ---------------------------------------------------------------------

-- Datos del servidor y de la sesión del aplicativo
CREATE PROCEDURE sp_info_servidor()
READS SQL DATA
BEGIN
    SELECT VERSION()                  AS version,
           DATABASE()                 AS base,
           USER()                     AS usuario_conectado,
           @@character_set_database   AS charset,
           @@collation_database       AS collation,
           NOW()                      AS hora_servidor;
END$$

-- Filas de cada tabla de la base
CREATE PROCEDURE sp_conteo_tablas()
READS SQL DATA
BEGIN
    SELECT 'alumno'         AS tabla, COUNT(*) AS filas FROM alumno
    UNION ALL SELECT 'doctor',         COUNT(*) FROM doctor
    UNION ALL SELECT 'esterilizacion', COUNT(*) FROM esterilizacion
    UNION ALL SELECT 'ingreso',        COUNT(*) FROM ingreso
    UNION ALL SELECT 'paciente',       COUNT(*) FROM paciente
    UNION ALL SELECT 'permiso',        COUNT(*) FROM permiso
    UNION ALL SELECT 'personal',       COUNT(*) FROM personal
    UNION ALL SELECT 'programacion',   COUNT(*) FROM programacion
    UNION ALL SELECT 'sala',           COUNT(*) FROM sala
    UNION ALL SELECT 'sillon',         COUNT(*) FROM sillon
    UNION ALL SELECT 'auditoria',      COUNT(*) FROM auditoria;
END$$

-- Restricciones, índices, triggers y rutinas de la base
CREATE PROCEDURE sp_objetos_base()
READS SQL DATA
BEGIN
    SELECT constraint_type AS objeto, COUNT(*) AS cantidad
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE()
    GROUP BY constraint_type
    UNION ALL
    SELECT 'INDEX', COUNT(DISTINCT table_name, index_name)
    FROM information_schema.statistics WHERE table_schema = DATABASE()
    UNION ALL
    SELECT 'TRIGGER', COUNT(*)
    FROM information_schema.triggers WHERE trigger_schema = DATABASE()
    UNION ALL
    SELECT routine_type, COUNT(*)
    FROM information_schema.routines WHERE routine_schema = DATABASE()
    GROUP BY routine_type;
END$$

-- ---------------------------------------------------------------------
--  PROCEDIMIENTOS: recepción
-- ---------------------------------------------------------------------

-- Lista del personal de recepción (para el inicio de turno)
CREATE PROCEDURE sp_listar_personal()
READS SQL DATA
BEGIN
    SELECT codigo_personal, nombre FROM personal WHERE activo = 1 ORDER BY nombre;
END$$

-- Un integrante del personal por su código
CREATE PROCEDURE sp_obtener_personal(IN p_codigo SMALLINT)
READS SQL DATA
BEGIN
    SELECT codigo_personal, nombre FROM personal WHERE codigo_personal = p_codigo AND activo = 1;
END$$

-- Estado de cada sillón (Ocupado/Libre) en una fecha y turno
CREATE PROCEDURE sp_ocupacion_sillones(IN p_fecha DATE, IN p_turno VARCHAR(6))
READS SQL DATA
BEGIN
    SELECT s.codigo_sillon, s.piso,
           IF(EXISTS (SELECT 1
                      FROM ingreso i
                      JOIN programacion p ON p.codigo_programacion = i.codigo_programacion
                      WHERE i.fecha = p_fecha AND i.turno = p_turno
                        AND p.codigo_sillon = s.codigo_sillon),
              'Ocupado', 'Libre') AS estado
    FROM sillon s
    WHERE s.activo = 1
    ORDER BY s.piso, s.codigo_sillon;
END$$

-- Citas programadas para un día de la semana
CREATE PROCEDURE sp_agenda_dia(IN p_dia VARCHAR(9))
READS SQL DATA
BEGIN
    SELECT p.bloque_horario, p.codigo_programacion, pa.dni, pa.nombre AS paciente,
           pa.condicion, p.codigo_sillon, s.piso, p.asistencia
    FROM programacion p
    JOIN paciente pa ON pa.dni = p.dni
    LEFT JOIN sillon s ON s.codigo_sillon = p.codigo_sillon
    WHERE p.dia_semana = p_dia AND p.activo = 1
    ORDER BY p.bloque_horario, p.codigo_programacion;
END$$

-- Agenda de una fecha: citas atendidas ese día y citas pendientes de ese día de la semana
CREATE PROCEDURE sp_agenda_fecha(IN p_fecha DATE)
READS SQL DATA
BEGIN
    SELECT p.bloque_horario, p.codigo_programacion, pa.dni, pa.nombre AS paciente,
           pa.condicion, p.codigo_sillon, s.piso,
           IF(i.codigo_ingreso IS NULL, 'Pendiente', 'Atendida') AS estado,
           i.hora_ingreso
    FROM programacion p
    JOIN paciente pa ON pa.dni = p.dni
    LEFT JOIN sillon s ON s.codigo_sillon = p.codigo_sillon
    LEFT JOIN ingreso i ON i.codigo_programacion = p.codigo_programacion
    WHERE p.activo = 1
      AND (i.fecha = p_fecha
           OR (i.codigo_ingreso IS NULL AND p.asistencia IS NULL AND p.dia_semana = fn_dia_semana(p_fecha)))
    ORDER BY p.bloque_horario, p.codigo_programacion;
END$$

-- Busca un alumno por su código QR
CREATE PROCEDURE sp_buscar_alumno_qr(IN p_qr VARCHAR(10))
READS SQL DATA
BEGIN
    SELECT codigo_alumno, codigo_qr, nombre FROM alumno WHERE codigo_qr = p_qr;
END$$

-- Atenciones (ingresos) de un alumno, de la más reciente a la más antigua
CREATE PROCEDURE sp_atenciones_alumno(IN p_codigo_alumno VARCHAR(10))
READS SQL DATA
BEGIN
    SELECT i.fecha, i.hora_ingreso, i.turno, pa.nombre AS paciente,
           COALESCE(p.codigo_sillon, sa.nombre_sala) AS ubicacion
    FROM ingreso i
    JOIN programacion p ON p.codigo_programacion = i.codigo_programacion
    JOIN paciente pa ON pa.dni = p.dni
    LEFT JOIN sala sa ON sa.codigo_sala = i.codigo_sala
    WHERE i.codigo_alumno = p_codigo_alumno
    ORDER BY i.fecha DESC, i.hora_ingreso DESC;
END$$

-- Ingresos de una fecha; si el turno es NULL muestra todo el día
CREATE PROCEDURE sp_ingresos_dia(IN p_fecha DATE, IN p_turno VARCHAR(6))
READS SQL DATA
BEGIN
    SELECT i.codigo_ingreso, i.hora_ingreso, i.turno,
           pa.nombre AS paciente, a.nombre AS alumno, pe.nombre AS validado_por,
           COALESCE(p.codigo_sillon, sa.nombre_sala) AS ubicacion,
           i.tipo_procedimiento, d.nombre AS doctor
    FROM ingreso i
    JOIN programacion p ON p.codigo_programacion = i.codigo_programacion
    JOIN paciente pa    ON pa.dni = p.dni
    JOIN alumno a       ON a.codigo_alumno = i.codigo_alumno
    JOIN personal pe    ON pe.codigo_personal = i.codigo_personal
    LEFT JOIN sala sa   ON sa.codigo_sala = i.codigo_sala
    LEFT JOIN doctor d  ON d.codigo_doctor = i.codigo_doctor
    WHERE i.fecha = p_fecha
      AND (p_turno IS NULL OR i.turno = p_turno)
    ORDER BY i.hora_ingreso;
END$$

DELIMITER ;

-- Verificación: rutinas creadas
SELECT routine_type AS tipo, routine_name AS nombre
FROM information_schema.routines
WHERE routine_schema = 'bd_ingreso_odontologico'
ORDER BY routine_type, routine_name;


-- #####################################################################
-- ##  10_procedimientos_crud.sql
-- #####################################################################

-- =====================================================================
--  Script 10 - Procedimientos de registro y mantenimiento (CRUD)
--  Base de datos: bd_ingreso_odontologico (MySQL 8.0)
--  Ejecutar con root en Workbench, después de 01, 11, 02 y 09.
--  Entrega 5: las eliminaciones de catálogos y citas son lógicas
--  (columna activo = 0); los registros no se borran de la base.
--  El aplicativo registra, modifica y elimina datos solo a través de
--  estos procedimientos. Las reglas CHECK, las claves foráneas y los
--  triggers de la base siguen validando cada operación.
-- =====================================================================
SET NAMES utf8mb4;
USE bd_ingreso_odontologico;

DROP PROCEDURE IF EXISTS sp_paciente_listar;
DROP PROCEDURE IF EXISTS sp_paciente_obtener;
DROP PROCEDURE IF EXISTS sp_paciente_insertar;
DROP PROCEDURE IF EXISTS sp_paciente_actualizar;
DROP PROCEDURE IF EXISTS sp_paciente_eliminar;
DROP PROCEDURE IF EXISTS sp_paciente_restaurar;
DROP PROCEDURE IF EXISTS sp_alumno_listar;
DROP PROCEDURE IF EXISTS sp_alumno_obtener;
DROP PROCEDURE IF EXISTS sp_alumno_insertar;
DROP PROCEDURE IF EXISTS sp_alumno_actualizar;
DROP PROCEDURE IF EXISTS sp_alumno_eliminar;
DROP PROCEDURE IF EXISTS sp_alumno_restaurar;
DROP PROCEDURE IF EXISTS sp_listar_sillones;
DROP PROCEDURE IF EXISTS sp_listar_salas;
DROP PROCEDURE IF EXISTS sp_listar_doctores;
DROP PROCEDURE IF EXISTS sp_cita_obtener;
DROP PROCEDURE IF EXISTS sp_cita_insertar;
DROP PROCEDURE IF EXISTS sp_cita_actualizar;
DROP PROCEDURE IF EXISTS sp_cita_marcar_asistencia;
DROP PROCEDURE IF EXISTS sp_cita_eliminar;
DROP PROCEDURE IF EXISTS sp_cita_restaurar;
DROP PROCEDURE IF EXISTS sp_citas_pendientes;
DROP PROCEDURE IF EXISTS sp_ingreso_registrar;
DROP PROCEDURE IF EXISTS sp_ingreso_anular;
DROP PROCEDURE IF EXISTS sp_ingresos_combo;
DROP PROCEDURE IF EXISTS sp_permiso_listar;
DROP PROCEDURE IF EXISTS sp_permiso_registrar_salida;
DROP PROCEDURE IF EXISTS sp_permiso_registrar_retorno;
DROP PROCEDURE IF EXISTS sp_permiso_eliminar;
DROP PROCEDURE IF EXISTS sp_esterilizacion_listar;
DROP PROCEDURE IF EXISTS sp_esterilizacion_registrar_inicio;
DROP PROCEDURE IF EXISTS sp_esterilizacion_registrar_fin;
DROP PROCEDURE IF EXISTS sp_esterilizacion_eliminar;

DELIMITER $$

-- =====================================================================
--  PACIENTES
-- =====================================================================

-- Lista de pacientes activos (p_inactivos = 1 lista los desactivados);
-- filtra por DNI o nombre si se envía un texto
CREATE PROCEDURE sp_paciente_listar(IN p_buscar VARCHAR(60), IN p_inactivos TINYINT)
READS SQL DATA
BEGIN
    SELECT pa.dni, pa.nombre, pa.condicion, pa.activo,
           (SELECT COUNT(*) FROM programacion p WHERE p.dni = pa.dni AND p.activo = 1) AS citas
    FROM paciente pa
    WHERE pa.activo = IF(COALESCE(p_inactivos, 0) = 1, 0, 1)
      AND (p_buscar IS NULL OR p_buscar = ''
           OR pa.dni LIKE CONCAT(p_buscar, '%')
           OR pa.nombre LIKE CONCAT('%', p_buscar, '%'))
    ORDER BY pa.nombre;
END$$

CREATE PROCEDURE sp_paciente_obtener(IN p_dni CHAR(8))
READS SQL DATA
BEGIN
    SELECT dni, nombre, condicion, activo FROM paciente WHERE dni = p_dni;
END$$

CREATE PROCEDURE sp_paciente_insertar(IN p_dni CHAR(8), IN p_nombre VARCHAR(60), IN p_condicion VARCHAR(8))
MODIFIES SQL DATA
BEGIN
    IF EXISTS (SELECT 1 FROM paciente WHERE dni = p_dni AND activo = 0) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ese DNI pertenece a un paciente desactivado; restáurelo desde la lista de inactivos.';
    END IF;
    IF EXISTS (SELECT 1 FROM paciente WHERE dni = p_dni) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un paciente registrado con ese DNI.';
    END IF;
    INSERT INTO paciente (dni, nombre, condicion) VALUES (p_dni, TRIM(p_nombre), p_condicion);
    SELECT p_dni AS dni;
END$$

CREATE PROCEDURE sp_paciente_actualizar(IN p_dni CHAR(8), IN p_nombre VARCHAR(60), IN p_condicion VARCHAR(8))
MODIFIES SQL DATA
BEGIN
    IF NOT EXISTS (SELECT 1 FROM paciente WHERE dni = p_dni) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El paciente no existe.';
    END IF;
    UPDATE paciente SET nombre = TRIM(p_nombre), condicion = p_condicion WHERE dni = p_dni;
    SELECT p_dni AS dni;
END$$

-- Borrado lógico: el paciente se desactiva y su historial se conserva
CREATE PROCEDURE sp_paciente_eliminar(IN p_dni CHAR(8))
MODIFIES SQL DATA
BEGIN
    IF EXISTS (SELECT 1 FROM programacion p
               WHERE p.dni = p_dni AND p.activo = 1 AND p.asistencia IS NULL
                 AND NOT EXISTS (SELECT 1 FROM ingreso i WHERE i.codigo_programacion = p.codigo_programacion)) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede desactivar: el paciente tiene citas pendientes. Elimine primero esas citas.';
    END IF;
    UPDATE paciente SET activo = 0 WHERE dni = p_dni;
    SELECT ROW_COUNT() AS desactivados;
END$$

CREATE PROCEDURE sp_paciente_restaurar(IN p_dni CHAR(8))
MODIFIES SQL DATA
BEGIN
    UPDATE paciente SET activo = 1 WHERE dni = p_dni;
    SELECT ROW_COUNT() AS restaurados;
END$$

-- =====================================================================
--  ALUMNOS
-- =====================================================================

-- Lista de alumnos activos (p_inactivos = 1 lista los desactivados)
CREATE PROCEDURE sp_alumno_listar(IN p_buscar VARCHAR(60), IN p_inactivos TINYINT)
READS SQL DATA
BEGIN
    SELECT a.codigo_alumno, a.codigo_qr, a.nombre, a.activo,
           (SELECT COUNT(*) FROM ingreso i WHERE i.codigo_alumno = a.codigo_alumno) AS atenciones
    FROM alumno a
    WHERE a.activo = IF(COALESCE(p_inactivos, 0) = 1, 0, 1)
      AND (p_buscar IS NULL OR p_buscar = ''
           OR a.codigo_alumno LIKE CONCAT(p_buscar, '%')
           OR a.codigo_qr LIKE CONCAT(p_buscar, '%')
           OR a.nombre LIKE CONCAT('%', p_buscar, '%'))
    ORDER BY a.nombre;
END$$

CREATE PROCEDURE sp_alumno_obtener(IN p_codigo VARCHAR(10))
READS SQL DATA
BEGIN
    SELECT codigo_alumno, codigo_qr, nombre, activo FROM alumno WHERE codigo_alumno = p_codigo;
END$$

CREATE PROCEDURE sp_alumno_insertar(IN p_codigo VARCHAR(10), IN p_qr VARCHAR(10), IN p_nombre VARCHAR(60))
MODIFIES SQL DATA
BEGIN
    IF EXISTS (SELECT 1 FROM alumno WHERE codigo_alumno = p_codigo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un alumno con ese código.';
    END IF;
    INSERT INTO alumno (codigo_alumno, codigo_qr, nombre) VALUES (p_codigo, UPPER(p_qr), TRIM(p_nombre));
    SELECT p_codigo AS codigo_alumno;
END$$

CREATE PROCEDURE sp_alumno_actualizar(IN p_codigo VARCHAR(10), IN p_qr VARCHAR(10), IN p_nombre VARCHAR(60))
MODIFIES SQL DATA
BEGIN
    IF NOT EXISTS (SELECT 1 FROM alumno WHERE codigo_alumno = p_codigo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El alumno no existe.';
    END IF;
    UPDATE alumno SET codigo_qr = UPPER(p_qr), nombre = TRIM(p_nombre) WHERE codigo_alumno = p_codigo;
    SELECT p_codigo AS codigo_alumno;
END$$

-- Borrado lógico: el alumno ya no puede registrar ingresos, pero su historial se conserva
CREATE PROCEDURE sp_alumno_eliminar(IN p_codigo VARCHAR(10))
MODIFIES SQL DATA
BEGIN
    UPDATE alumno SET activo = 0 WHERE codigo_alumno = p_codigo;
    SELECT ROW_COUNT() AS desactivados;
END$$

CREATE PROCEDURE sp_alumno_restaurar(IN p_codigo VARCHAR(10))
MODIFIES SQL DATA
BEGIN
    UPDATE alumno SET activo = 1 WHERE codigo_alumno = p_codigo;
    SELECT ROW_COUNT() AS restaurados;
END$$

-- =====================================================================
--  CATÁLOGOS (para las listas de selección)
-- =====================================================================

CREATE PROCEDURE sp_listar_sillones()
READS SQL DATA
BEGIN
    SELECT codigo_sillon, piso FROM sillon WHERE activo = 1 ORDER BY codigo_sillon;
END$$

CREATE PROCEDURE sp_listar_salas()
READS SQL DATA
BEGIN
    SELECT codigo_sala, nombre_sala FROM sala WHERE activo = 1 ORDER BY codigo_sala;
END$$

CREATE PROCEDURE sp_listar_doctores()
READS SQL DATA
BEGIN
    SELECT codigo_doctor, nombre FROM doctor WHERE activo = 1 ORDER BY nombre;
END$$

-- =====================================================================
--  CITAS (PROGRAMACIÓN)
-- =====================================================================

CREATE PROCEDURE sp_cita_obtener(IN p_codigo VARCHAR(8))
READS SQL DATA
BEGIN
    SELECT p.codigo_programacion, p.dia_semana, p.bloque_horario, p.asistencia,
           p.dni, pa.nombre AS paciente, p.codigo_sillon, p.activo,
           EXISTS (SELECT 1 FROM ingreso i WHERE i.codigo_programacion = p.codigo_programacion) AS tiene_ingreso
    FROM programacion p
    JOIN paciente pa ON pa.dni = p.dni
    WHERE p.codigo_programacion = p_codigo;
END$$

-- Registra una cita. Genera el código y valida que el sillón no tenga otra
-- cita pendiente en un bloque que se cruce el mismo día de la semana
-- (las citas ya atendidas o con inasistencia no ocupan el sillón).
CREATE PROCEDURE sp_cita_insertar(IN p_dia VARCHAR(9), IN p_bloque VARCHAR(11),
                                  IN p_dni CHAR(8), IN p_sillon VARCHAR(3))
MODIFIES SQL DATA
BEGIN
    DECLARE v_codigo VARCHAR(8);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;

    SET p_sillon = NULLIF(p_sillon, '');
    IF NOT EXISTS (SELECT 1 FROM paciente WHERE dni = p_dni AND activo = 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El paciente no existe o está desactivado.';
    END IF;
    IF p_sillon IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sillon WHERE codigo_sillon = p_sillon AND activo = 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El sillón no existe o está fuera de servicio.';
    END IF;
    START TRANSACTION;

    IF p_sillon IS NOT NULL AND EXISTS (
        SELECT 1 FROM programacion
        WHERE dia_semana = p_dia AND codigo_sillon = p_sillon AND activo = 1
          AND asistencia IS NULL
          AND SUBSTRING(bloque_horario, 1, 5) < SUBSTRING(p_bloque, 7, 5)
          AND SUBSTRING(bloque_horario, 7, 5) > SUBSTRING(p_bloque, 1, 5)
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El sillón ya tiene una cita en un horario que se cruza ese día.';
    END IF;

    SELECT LPAD(COALESCE(MAX(CAST(codigo_programacion AS UNSIGNED)), 10000000) + 1, 8, '0')
      INTO v_codigo
      FROM programacion FOR UPDATE;

    INSERT INTO programacion (codigo_programacion, dia_semana, bloque_horario, asistencia, dni, codigo_sillon)
    VALUES (v_codigo, p_dia, p_bloque, NULL, p_dni, p_sillon);

    COMMIT;
    SELECT v_codigo AS codigo_programacion;
END$$

-- Modifica una cita que todavía no tiene ingreso
CREATE PROCEDURE sp_cita_actualizar(IN p_codigo VARCHAR(8), IN p_dia VARCHAR(9), IN p_bloque VARCHAR(11),
                                    IN p_dni CHAR(8), IN p_sillon VARCHAR(3))
MODIFIES SQL DATA
BEGIN
    SET p_sillon = NULLIF(p_sillon, '');
    IF NOT EXISTS (SELECT 1 FROM programacion WHERE codigo_programacion = p_codigo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cita no existe.';
    END IF;
    IF EXISTS (SELECT 1 FROM ingreso WHERE codigo_programacion = p_codigo) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede modificar: la cita ya tiene un ingreso registrado.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM paciente WHERE dni = p_dni AND activo = 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El paciente no existe o está desactivado.';
    END IF;
    IF p_sillon IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sillon WHERE codigo_sillon = p_sillon AND activo = 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El sillón no existe o está fuera de servicio.';
    END IF;
    IF p_sillon IS NOT NULL AND EXISTS (
        SELECT 1 FROM programacion
        WHERE dia_semana = p_dia AND codigo_sillon = p_sillon AND activo = 1 AND asistencia IS NULL
          AND codigo_programacion <> p_codigo
          AND SUBSTRING(bloque_horario, 1, 5) < SUBSTRING(p_bloque, 7, 5)
          AND SUBSTRING(bloque_horario, 7, 5) > SUBSTRING(p_bloque, 1, 5)
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El sillón ya tiene una cita en un horario que se cruza ese día.';
    END IF;

    UPDATE programacion
       SET dia_semana = p_dia, bloque_horario = p_bloque, dni = p_dni, codigo_sillon = p_sillon
     WHERE codigo_programacion = p_codigo;
    SELECT p_codigo AS codigo_programacion;
END$$

-- Marca la asistencia de una cita (NULL deja la cita como pendiente)
CREATE PROCEDURE sp_cita_marcar_asistencia(IN p_codigo VARCHAR(8), IN p_asistencia VARCHAR(10))
MODIFIES SQL DATA
BEGIN
    IF p_asistencia = 'No asistió' AND EXISTS (SELECT 1 FROM ingreso WHERE codigo_programacion = p_codigo) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La cita tiene un ingreso registrado; no se puede marcar como No asistió.';
    END IF;
    UPDATE programacion SET asistencia = NULLIF(p_asistencia, '') WHERE codigo_programacion = p_codigo;
    SELECT ROW_COUNT() AS actualizados;
END$$

-- Borrado lógico de una cita que todavía no tiene ingreso
CREATE PROCEDURE sp_cita_eliminar(IN p_codigo VARCHAR(8))
MODIFIES SQL DATA
BEGIN
    IF EXISTS (SELECT 1 FROM ingreso WHERE codigo_programacion = p_codigo) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede eliminar: la cita ya tiene un ingreso. Primero anule el ingreso.';
    END IF;
    UPDATE programacion SET activo = 0 WHERE codigo_programacion = p_codigo;
    SELECT ROW_COUNT() AS desactivados;
END$$

-- Restaura una cita eliminada, siempre que su sillón siga libre en ese horario
CREATE PROCEDURE sp_cita_restaurar(IN p_codigo VARCHAR(8))
MODIFIES SQL DATA
BEGIN
    DECLARE v_dia VARCHAR(9);
    DECLARE v_bloque VARCHAR(11);
    DECLARE v_sillon VARCHAR(3);
    SELECT dia_semana, bloque_horario, codigo_sillon INTO v_dia, v_bloque, v_sillon
      FROM programacion WHERE codigo_programacion = p_codigo;
    IF v_sillon IS NOT NULL AND EXISTS (
        SELECT 1 FROM programacion
        WHERE dia_semana = v_dia AND codigo_sillon = v_sillon AND activo = 1 AND asistencia IS NULL
          AND codigo_programacion <> p_codigo
          AND SUBSTRING(bloque_horario, 1, 5) < SUBSTRING(v_bloque, 7, 5)
          AND SUBSTRING(bloque_horario, 7, 5) > SUBSTRING(v_bloque, 1, 5)
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede restaurar: el sillón ya tiene otra cita en ese horario.';
    END IF;
    UPDATE programacion SET activo = 1 WHERE codigo_programacion = p_codigo;
    SELECT ROW_COUNT() AS restaurados;
END$$

-- Citas del día de la semana de una fecha que todavía no tienen ingreso
CREATE PROCEDURE sp_citas_pendientes(IN p_fecha DATE)
READS SQL DATA
BEGIN
    SELECT p.codigo_programacion, p.bloque_horario, pa.nombre AS paciente,
           COALESCE(p.codigo_sillon, 'Sala') AS ubicacion
    FROM programacion p
    JOIN paciente pa ON pa.dni = p.dni
    WHERE p.dia_semana = fn_dia_semana(p_fecha)
      AND p.activo = 1
      AND (p.asistencia IS NULL OR p.asistencia <> 'No asistió')
      AND NOT EXISTS (SELECT 1 FROM ingreso i WHERE i.codigo_programacion = p.codigo_programacion)
    ORDER BY p.bloque_horario;
END$$

-- =====================================================================
--  INGRESOS
-- =====================================================================

-- Registra el ingreso de un alumno con su paciente.
-- Valida la cita, el día, el QR del alumno y el tipo de atención;
-- genera el código, calcula el turno y marca la asistencia de la cita.
CREATE PROCEDURE sp_ingreso_registrar(
    IN p_codigo_programacion VARCHAR(8), IN p_codigo_qr VARCHAR(10), IN p_codigo_personal SMALLINT,
    IN p_fecha DATE, IN p_hora TIME,
    IN p_procedimiento VARCHAR(30), IN p_codigo_sala SMALLINT, IN p_codigo_doctor SMALLINT)
MODIFIES SQL DATA
BEGIN
    DECLARE v_dia VARCHAR(9);
    DECLARE v_sillon VARCHAR(3);
    DECLARE v_alumno VARCHAR(10);
    DECLARE v_codigo VARCHAR(8);
    DECLARE v_mensaje VARCHAR(200);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;

    SET p_procedimiento = NULLIF(TRIM(p_procedimiento), '');

    SELECT dia_semana, codigo_sillon INTO v_dia, v_sillon
      FROM programacion WHERE codigo_programacion = p_codigo_programacion AND activo = 1;
    IF v_dia IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cita seleccionada no existe.';
    END IF;
    IF v_dia <> fn_dia_semana(p_fecha) THEN
        SET v_mensaje = CONCAT('La cita es del día ', v_dia, ' y la fecha elegida es ', fn_dia_semana(p_fecha), '.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_mensaje;
    END IF;

    SELECT codigo_alumno INTO v_alumno FROM alumno WHERE codigo_qr = UPPER(p_codigo_qr);
    IF v_alumno IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El código QR no corresponde a ningún alumno registrado.';
    END IF;
    IF EXISTS (SELECT 1 FROM alumno WHERE codigo_alumno = v_alumno AND activo = 0) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El alumno está desactivado y no puede registrar ingresos.';
    END IF;

    IF v_sillon IS NOT NULL THEN
        -- Atención en sillón: no lleva procedimiento, sala ni doctor
        IF p_procedimiento IS NOT NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'La cita es en sillón; los procedimientos en sala se programan sin sillón.';
        END IF;
        SET p_codigo_sala = NULL, p_codigo_doctor = NULL;
    ELSE
        -- Atención en sala: requiere procedimiento y doctor supervisor
        IF p_procedimiento IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'La cita es en sala: indique el tipo de procedimiento.';
        END IF;
        IF p_codigo_doctor IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Los procedimientos en sala requieren un doctor supervisor.';
        END IF;
        IF EXISTS (SELECT 1 FROM doctor WHERE codigo_doctor = p_codigo_doctor AND activo = 0)
           OR EXISTS (SELECT 1 FROM sala WHERE codigo_sala = p_codigo_sala AND activo = 0) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La sala o el doctor elegido está desactivado.';
        END IF;
    END IF;

    START TRANSACTION;

    SELECT LPAD(COALESCE(MAX(CAST(codigo_ingreso AS UNSIGNED)), 50000000) + 1, 8, '0')
      INTO v_codigo
      FROM ingreso FOR UPDATE;

    UPDATE programacion SET asistencia = 'Asistió' WHERE codigo_programacion = p_codigo_programacion;

    -- Si hay procedimiento sin sala, el trigger trg_ingreso_bi rechaza la fila
    INSERT INTO ingreso (codigo_ingreso, fecha, hora_ingreso, turno, tipo_procedimiento,
                         codigo_programacion, codigo_alumno, codigo_personal, codigo_sala, codigo_doctor)
    VALUES (v_codigo, p_fecha, p_hora, IF(p_hora < '13:00:00', 'Mañana', 'Tarde'), p_procedimiento,
            p_codigo_programacion, v_alumno, p_codigo_personal, p_codigo_sala, p_codigo_doctor);

    COMMIT;
    SELECT v_codigo AS codigo_ingreso;
END$$

-- Anula un ingreso: se eliminan en cascada sus permisos y esterilizaciones
-- y la cita vuelve a quedar pendiente.
CREATE PROCEDURE sp_ingreso_anular(IN p_codigo VARCHAR(8))
MODIFIES SQL DATA
BEGIN
    DECLARE v_cita VARCHAR(8);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;

    SELECT codigo_programacion INTO v_cita FROM ingreso WHERE codigo_ingreso = p_codigo;
    IF v_cita IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El ingreso no existe.';
    END IF;

    START TRANSACTION;
    -- Se borran explícitamente (y no solo por la cascada) para que los
    -- triggers de auditoría registren cada permiso y ciclo anulado.
    DELETE FROM permiso WHERE codigo_ingreso = p_codigo;
    DELETE FROM esterilizacion WHERE codigo_ingreso = p_codigo;
    DELETE FROM ingreso WHERE codigo_ingreso = p_codigo;
    UPDATE programacion SET asistencia = NULL WHERE codigo_programacion = v_cita;
    COMMIT;
    SELECT p_codigo AS codigo_ingreso;
END$$

-- Ingresos de una fecha para las listas de selección
CREATE PROCEDURE sp_ingresos_combo(IN p_fecha DATE)
READS SQL DATA
BEGIN
    SELECT i.codigo_ingreso, i.hora_ingreso, a.nombre AS alumno, pa.nombre AS paciente
    FROM ingreso i
    JOIN alumno a ON a.codigo_alumno = i.codigo_alumno
    JOIN programacion p ON p.codigo_programacion = i.codigo_programacion
    JOIN paciente pa ON pa.dni = p.dni
    WHERE i.fecha = p_fecha
    ORDER BY i.hora_ingreso;
END$$

-- =====================================================================
--  PERMISOS
-- =====================================================================

CREATE PROCEDURE sp_permiso_listar(IN p_fecha DATE)
READS SQL DATA
BEGIN
    SELECT pm.codigo_ingreso, a.nombre AS alumno, pm.hora_salida, pm.hora_retorno, pm.motivo,
           TIMEDIFF(pm.hora_retorno, pm.hora_salida) AS tiempo_fuera
    FROM permiso pm
    JOIN ingreso i ON i.codigo_ingreso = pm.codigo_ingreso
    JOIN alumno a ON a.codigo_alumno = i.codigo_alumno
    WHERE i.fecha = p_fecha
    ORDER BY pm.hora_retorno IS NOT NULL, pm.hora_salida;
END$$

CREATE PROCEDURE sp_permiso_registrar_salida(IN p_codigo_ingreso VARCHAR(8), IN p_hora TIME, IN p_motivo VARCHAR(50))
MODIFIES SQL DATA
BEGIN
    DECLARE v_hora_ingreso TIME;
    SELECT hora_ingreso INTO v_hora_ingreso FROM ingreso WHERE codigo_ingreso = p_codigo_ingreso;
    IF v_hora_ingreso IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El ingreso no existe.';
    END IF;
    IF p_hora < v_hora_ingreso THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La hora de salida no puede ser anterior a la hora de ingreso.';
    END IF;
    IF EXISTS (SELECT 1 FROM permiso WHERE codigo_ingreso = p_codigo_ingreso AND hora_retorno IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El alumno ya tiene un permiso abierto; registre primero su retorno.';
    END IF;
    INSERT INTO permiso (codigo_ingreso, hora_salida, hora_retorno, motivo)
    VALUES (p_codigo_ingreso, p_hora, NULL, TRIM(p_motivo));
    SELECT p_codigo_ingreso AS codigo_ingreso;
END$$

-- La regla CHECK ck_permiso_retorno valida que el retorno sea posterior a la salida
CREATE PROCEDURE sp_permiso_registrar_retorno(IN p_codigo_ingreso VARCHAR(8), IN p_hora_salida TIME, IN p_hora_retorno TIME)
MODIFIES SQL DATA
BEGIN
    UPDATE permiso SET hora_retorno = p_hora_retorno
     WHERE codigo_ingreso = p_codigo_ingreso AND hora_salida = p_hora_salida;
    SELECT ROW_COUNT() AS actualizados;
END$$

CREATE PROCEDURE sp_permiso_eliminar(IN p_codigo_ingreso VARCHAR(8), IN p_hora_salida TIME)
MODIFIES SQL DATA
BEGIN
    DELETE FROM permiso WHERE codigo_ingreso = p_codigo_ingreso AND hora_salida = p_hora_salida;
    SELECT ROW_COUNT() AS eliminados;
END$$

-- =====================================================================
--  ESTERILIZACIÓN
-- =====================================================================

CREATE PROCEDURE sp_esterilizacion_listar(IN p_fecha DATE)
READS SQL DATA
BEGIN
    SELECT e.codigo_ingreso, a.nombre AS alumno, e.hora_inicio, e.hora_fin, e.asistencia,
           TIMEDIFF(e.hora_fin, e.hora_inicio) AS duracion,
           (e.hora_fin IS NULL AND e.asistencia = 'Asistió') AS en_curso
    FROM esterilizacion e
    JOIN ingreso i ON i.codigo_ingreso = e.codigo_ingreso
    JOIN alumno a ON a.codigo_alumno = i.codigo_alumno
    WHERE i.fecha = p_fecha
    ORDER BY e.hora_fin IS NOT NULL, e.hora_inicio;
END$$

CREATE PROCEDURE sp_esterilizacion_registrar_inicio(IN p_codigo_ingreso VARCHAR(8), IN p_hora TIME, IN p_asistencia VARCHAR(10))
MODIFIES SQL DATA
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ingreso WHERE codigo_ingreso = p_codigo_ingreso) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El ingreso no existe.';
    END IF;
    IF EXISTS (SELECT 1 FROM esterilizacion WHERE codigo_ingreso = p_codigo_ingreso AND hora_fin IS NULL AND asistencia = 'Asistió') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ese ingreso ya tiene un ciclo de esterilización en curso.';
    END IF;
    INSERT INTO esterilizacion (codigo_ingreso, hora_inicio, hora_fin, asistencia)
    VALUES (p_codigo_ingreso, p_hora, NULL, p_asistencia);
    SELECT p_codigo_ingreso AS codigo_ingreso;
END$$

-- La regla CHECK ck_esterilizacion_fin valida que el fin sea posterior al inicio
CREATE PROCEDURE sp_esterilizacion_registrar_fin(IN p_codigo_ingreso VARCHAR(8), IN p_hora_inicio TIME, IN p_hora_fin TIME)
MODIFIES SQL DATA
BEGIN
    UPDATE esterilizacion SET hora_fin = p_hora_fin
     WHERE codigo_ingreso = p_codigo_ingreso AND hora_inicio = p_hora_inicio;
    SELECT ROW_COUNT() AS actualizados;
END$$

CREATE PROCEDURE sp_esterilizacion_eliminar(IN p_codigo_ingreso VARCHAR(8), IN p_hora_inicio TIME)
MODIFIES SQL DATA
BEGIN
    DELETE FROM esterilizacion WHERE codigo_ingreso = p_codigo_ingreso AND hora_inicio = p_hora_inicio;
    SELECT ROW_COUNT() AS eliminados;
END$$

DELIMITER ;

-- Verificación: procedimientos de este script
SELECT routine_name AS procedimiento
FROM information_schema.routines
WHERE routine_schema = 'bd_ingreso_odontologico'
  AND routine_type = 'PROCEDURE'
  AND routine_name REGEXP '^sp_(paciente|alumno|cita_|citas|ingreso_|ingresos_combo|permiso|esterilizacion|listar_(sillones|salas|doctores))'
ORDER BY routine_name;


-- #####################################################################
-- ##  12_catalogos_reportes.sql
-- #####################################################################

-- =====================================================================
--  Script 12 - Sesión, mantenimiento de catálogos y reportes
--  Base de datos: bd_ingreso_odontologico (MySQL 8.0)
--  Ejecutar con root en Workbench, después de 01, 11, 02, 09 y 10.
-- =====================================================================
SET NAMES utf8mb4;
USE bd_ingreso_odontologico;

DROP PROCEDURE IF EXISTS sp_sesion_iniciar;
DROP PROCEDURE IF EXISTS sp_cita_listar_eliminadas;
DROP PROCEDURE IF EXISTS sp_sillon_listar;
DROP PROCEDURE IF EXISTS sp_sillon_insertar;
DROP PROCEDURE IF EXISTS sp_sillon_actualizar;
DROP PROCEDURE IF EXISTS sp_sillon_cambiar_estado;
DROP PROCEDURE IF EXISTS sp_sala_listar;
DROP PROCEDURE IF EXISTS sp_sala_insertar;
DROP PROCEDURE IF EXISTS sp_sala_actualizar;
DROP PROCEDURE IF EXISTS sp_sala_cambiar_estado;
DROP PROCEDURE IF EXISTS sp_personal_listar;
DROP PROCEDURE IF EXISTS sp_personal_insertar;
DROP PROCEDURE IF EXISTS sp_personal_actualizar;
DROP PROCEDURE IF EXISTS sp_personal_cambiar_estado;
DROP PROCEDURE IF EXISTS sp_doctor_listar;
DROP PROCEDURE IF EXISTS sp_doctor_insertar;
DROP PROCEDURE IF EXISTS sp_doctor_actualizar;
DROP PROCEDURE IF EXISTS sp_doctor_cambiar_estado;
DROP PROCEDURE IF EXISTS sp_rep_asistencia_dia;
DROP PROCEDURE IF EXISTS sp_rep_atenciones_alumno;
DROP PROCEDURE IF EXISTS sp_rep_ingresos_personal;
DROP PROCEDURE IF EXISTS sp_rep_uso_sillones;
DROP PROCEDURE IF EXISTS sp_rep_procedimientos_sala;
DROP PROCEDURE IF EXISTS sp_rep_permisos_alumno;
DROP PROCEDURE IF EXISTS sp_rep_permisos_largos;
DROP PROCEDURE IF EXISTS sp_rep_esterilizacion_alumno;
DROP PROCEDURE IF EXISTS sp_rep_historial_paciente;
DROP PROCEDURE IF EXISTS sp_rep_citas_sin_ingreso;
DROP PROCEDURE IF EXISTS sp_rep_pacientes_condicion;
DROP PROCEDURE IF EXISTS sp_rep_ingresos_diarios;
DROP PROCEDURE IF EXISTS sp_rep_auditoria;

DELIMITER $$

-- =====================================================================
--  SESIÓN: guarda en la conexión quién de recepción tiene el turno,
--  para que los triggers de auditoría lo registren.
-- =====================================================================
CREATE PROCEDURE sp_sesion_iniciar(IN p_codigo_personal SMALLINT)
NO SQL
BEGIN
    SET @personal_app = p_codigo_personal;
    SELECT @personal_app AS personal;
END$$

-- Citas eliminadas (borrado lógico) de un día, para poder restaurarlas
CREATE PROCEDURE sp_cita_listar_eliminadas(IN p_dia VARCHAR(9))
READS SQL DATA
BEGIN
    SELECT p.codigo_programacion, p.bloque_horario, pa.nombre AS paciente, p.codigo_sillon, p.asistencia
    FROM programacion p
    JOIN paciente pa ON pa.dni = p.dni
    WHERE p.dia_semana = p_dia AND p.activo = 0
    ORDER BY p.bloque_horario;
END$$

-- =====================================================================
--  SILLONES (borrado lógico = fuera de servicio)
-- =====================================================================
CREATE PROCEDURE sp_sillon_listar(IN p_inactivos TINYINT)
READS SQL DATA
BEGIN
    SELECT s.codigo_sillon AS codigo, s.piso, s.activo,
           (SELECT COUNT(*) FROM programacion p WHERE p.codigo_sillon = s.codigo_sillon AND p.activo = 1) AS citas
    FROM sillon s
    WHERE s.activo = IF(COALESCE(p_inactivos, 0) = 1, 0, 1)
    ORDER BY s.piso, s.codigo_sillon;
END$$

CREATE PROCEDURE sp_sillon_insertar(IN p_codigo VARCHAR(3), IN p_piso SMALLINT)
MODIFIES SQL DATA
BEGIN
    IF EXISTS (SELECT 1 FROM sillon WHERE codigo_sillon = UPPER(p_codigo)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un sillón con ese código.';
    END IF;
    INSERT INTO sillon (codigo_sillon, piso) VALUES (UPPER(p_codigo), p_piso);
    SELECT UPPER(p_codigo) AS codigo;
END$$

CREATE PROCEDURE sp_sillon_actualizar(IN p_codigo VARCHAR(3), IN p_piso SMALLINT)
MODIFIES SQL DATA
BEGIN
    UPDATE sillon SET piso = p_piso WHERE codigo_sillon = p_codigo;
    SELECT ROW_COUNT() AS actualizados;
END$$

CREATE PROCEDURE sp_sillon_cambiar_estado(IN p_codigo VARCHAR(3), IN p_activo TINYINT)
MODIFIES SQL DATA
BEGIN
    IF p_activo = 0 AND EXISTS (
        SELECT 1 FROM programacion p
        WHERE p.codigo_sillon = p_codigo AND p.activo = 1 AND p.asistencia IS NULL
          AND NOT EXISTS (SELECT 1 FROM ingreso i WHERE i.codigo_programacion = p.codigo_programacion)) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede poner fuera de servicio: el sillón tiene citas pendientes. Reasígnelas primero.';
    END IF;
    UPDATE sillon SET activo = p_activo WHERE codigo_sillon = p_codigo;
    SELECT ROW_COUNT() AS actualizados;
END$$

-- =====================================================================
--  SALAS
-- =====================================================================
CREATE PROCEDURE sp_sala_listar(IN p_inactivos TINYINT)
READS SQL DATA
BEGIN
    SELECT s.codigo_sala AS codigo, s.nombre_sala AS nombre, s.activo,
           (SELECT COUNT(*) FROM ingreso i WHERE i.codigo_sala = s.codigo_sala) AS atenciones
    FROM sala s
    WHERE s.activo = IF(COALESCE(p_inactivos, 0) = 1, 0, 1)
    ORDER BY s.codigo_sala;
END$$

CREATE PROCEDURE sp_sala_insertar(IN p_codigo SMALLINT, IN p_nombre VARCHAR(30))
MODIFIES SQL DATA
BEGIN
    IF EXISTS (SELECT 1 FROM sala WHERE codigo_sala = p_codigo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una sala con ese código.';
    END IF;
    INSERT INTO sala (codigo_sala, nombre_sala) VALUES (p_codigo, TRIM(p_nombre));
    SELECT p_codigo AS codigo;
END$$

CREATE PROCEDURE sp_sala_actualizar(IN p_codigo SMALLINT, IN p_nombre VARCHAR(30))
MODIFIES SQL DATA
BEGIN
    UPDATE sala SET nombre_sala = TRIM(p_nombre) WHERE codigo_sala = p_codigo;
    SELECT ROW_COUNT() AS actualizados;
END$$

CREATE PROCEDURE sp_sala_cambiar_estado(IN p_codigo SMALLINT, IN p_activo TINYINT)
MODIFIES SQL DATA
BEGIN
    UPDATE sala SET activo = p_activo WHERE codigo_sala = p_codigo;
    SELECT ROW_COUNT() AS actualizados;
END$$

-- =====================================================================
--  PERSONAL DE RECEPCIÓN
-- =====================================================================
CREATE PROCEDURE sp_personal_listar(IN p_inactivos TINYINT)
READS SQL DATA
BEGIN
    SELECT pe.codigo_personal AS codigo, pe.nombre, pe.activo,
           (SELECT COUNT(*) FROM ingreso i WHERE i.codigo_personal = pe.codigo_personal) AS ingresos_validados
    FROM personal pe
    WHERE pe.activo = IF(COALESCE(p_inactivos, 0) = 1, 0, 1)
    ORDER BY pe.nombre;
END$$

CREATE PROCEDURE sp_personal_insertar(IN p_codigo SMALLINT, IN p_nombre VARCHAR(60))
MODIFIES SQL DATA
BEGIN
    IF EXISTS (SELECT 1 FROM personal WHERE codigo_personal = p_codigo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un integrante del personal con ese código.';
    END IF;
    INSERT INTO personal (codigo_personal, nombre) VALUES (p_codigo, TRIM(p_nombre));
    SELECT p_codigo AS codigo;
END$$

CREATE PROCEDURE sp_personal_actualizar(IN p_codigo SMALLINT, IN p_nombre VARCHAR(60))
MODIFIES SQL DATA
BEGIN
    UPDATE personal SET nombre = TRIM(p_nombre) WHERE codigo_personal = p_codigo;
    SELECT ROW_COUNT() AS actualizados;
END$$

CREATE PROCEDURE sp_personal_cambiar_estado(IN p_codigo SMALLINT, IN p_activo TINYINT)
MODIFIES SQL DATA
BEGIN
    IF p_activo = 0 AND p_codigo = @personal_app THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No puede desactivarse a sí mismo mientras tiene el turno abierto.';
    END IF;
    UPDATE personal SET activo = p_activo WHERE codigo_personal = p_codigo;
    SELECT ROW_COUNT() AS actualizados;
END$$

-- =====================================================================
--  DOCTORES
-- =====================================================================
CREATE PROCEDURE sp_doctor_listar(IN p_inactivos TINYINT)
READS SQL DATA
BEGIN
    SELECT d.codigo_doctor AS codigo, d.nombre, d.activo,
           (SELECT COUNT(*) FROM ingreso i WHERE i.codigo_doctor = d.codigo_doctor) AS supervisiones
    FROM doctor d
    WHERE d.activo = IF(COALESCE(p_inactivos, 0) = 1, 0, 1)
    ORDER BY d.nombre;
END$$

CREATE PROCEDURE sp_doctor_insertar(IN p_codigo SMALLINT, IN p_nombre VARCHAR(60))
MODIFIES SQL DATA
BEGIN
    IF EXISTS (SELECT 1 FROM doctor WHERE codigo_doctor = p_codigo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un doctor con ese código.';
    END IF;
    INSERT INTO doctor (codigo_doctor, nombre) VALUES (p_codigo, TRIM(p_nombre));
    SELECT p_codigo AS codigo;
END$$

CREATE PROCEDURE sp_doctor_actualizar(IN p_codigo SMALLINT, IN p_nombre VARCHAR(60))
MODIFIES SQL DATA
BEGIN
    UPDATE doctor SET nombre = TRIM(p_nombre) WHERE codigo_doctor = p_codigo;
    SELECT ROW_COUNT() AS actualizados;
END$$

CREATE PROCEDURE sp_doctor_cambiar_estado(IN p_codigo SMALLINT, IN p_activo TINYINT)
MODIFIES SQL DATA
BEGIN
    UPDATE doctor SET activo = p_activo WHERE codigo_doctor = p_codigo;
    SELECT ROW_COUNT() AS actualizados;
END$$

-- =====================================================================
--  REPORTES (13). Los marcados con [JOIN] combinan varias tablas.
-- =====================================================================

-- R01. Asistencia por día de la semana (citas vigentes)
CREATE PROCEDURE sp_rep_asistencia_dia()
READS SQL DATA
BEGIN
    SELECT dia_semana AS dia,
           COUNT(*) AS citas,
           SUM(asistencia = 'Asistió') AS asistieron,
           SUM(asistencia = 'No asistió') AS no_asistieron,
           SUM(asistencia IS NULL) AS pendientes,
           ROUND(100 * SUM(asistencia = 'Asistió') / NULLIF(SUM(asistencia IS NOT NULL), 0), 1) AS porcentaje_asistencia
    FROM programacion
    WHERE activo = 1
    GROUP BY dia_semana
    ORDER BY FIELD(dia_semana, 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado');
END$$

-- R02. [JOIN] Atenciones por alumno en un rango de fechas
CREATE PROCEDURE sp_rep_atenciones_alumno(IN p_desde DATE, IN p_hasta DATE)
READS SQL DATA
BEGIN
    SELECT a.codigo_alumno, a.nombre AS alumno,
           COUNT(i.codigo_ingreso) AS atenciones,
           SUM(i.codigo_sala IS NULL AND i.codigo_ingreso IS NOT NULL) AS en_sillon,
           SUM(i.codigo_sala IS NOT NULL) AS en_sala,
           COUNT(DISTINCT p.dni) AS pacientes_distintos,
           MAX(i.fecha) AS ultima_atencion
    FROM alumno a
    LEFT JOIN ingreso i ON i.codigo_alumno = a.codigo_alumno AND i.fecha BETWEEN p_desde AND p_hasta
    LEFT JOIN programacion p ON p.codigo_programacion = i.codigo_programacion
    WHERE a.activo = 1
    GROUP BY a.codigo_alumno, a.nombre
    ORDER BY atenciones DESC, a.nombre;
END$$

-- R03. [JOIN] Ingresos validados por cada integrante de recepción, por turno
CREATE PROCEDURE sp_rep_ingresos_personal(IN p_desde DATE, IN p_hasta DATE)
READS SQL DATA
BEGIN
    SELECT pe.nombre AS personal,
           SUM(i.turno = 'Mañana') AS turno_manana,
           SUM(i.turno = 'Tarde') AS turno_tarde,
           COUNT(i.codigo_ingreso) AS total,
           COUNT(DISTINCT i.fecha) AS dias_trabajados
    FROM personal pe
    LEFT JOIN ingreso i ON i.codigo_personal = pe.codigo_personal AND i.fecha BETWEEN p_desde AND p_hasta
    GROUP BY pe.codigo_personal, pe.nombre
    ORDER BY total DESC;
END$$

-- R04. [JOIN] Uso de sillones: atenciones por sillón y piso
CREATE PROCEDURE sp_rep_uso_sillones(IN p_desde DATE, IN p_hasta DATE)
READS SQL DATA
BEGIN
    SELECT s.codigo_sillon AS sillon, s.piso,
           COUNT(i.codigo_ingreso) AS atenciones,
           SUM(i.turno = 'Mañana') AS manana,
           SUM(i.turno = 'Tarde') AS tarde,
           (SELECT COUNT(*) FROM programacion p2
             WHERE p2.codigo_sillon = s.codigo_sillon AND p2.activo = 1) AS citas_programadas
    FROM sillon s
    LEFT JOIN programacion p ON p.codigo_sillon = s.codigo_sillon
    LEFT JOIN ingreso i ON i.codigo_programacion = p.codigo_programacion AND i.fecha BETWEEN p_desde AND p_hasta
    WHERE s.activo = 1
    GROUP BY s.codigo_sillon, s.piso
    ORDER BY atenciones DESC, s.codigo_sillon;
END$$

-- R05. [JOIN] Procedimientos en sala con su doctor supervisor
CREATE PROCEDURE sp_rep_procedimientos_sala(IN p_desde DATE, IN p_hasta DATE)
READS SQL DATA
BEGIN
    SELECT sa.nombre_sala AS sala, i.tipo_procedimiento AS procedimiento, d.nombre AS doctor,
           COUNT(*) AS cantidad, MIN(i.fecha) AS primera_fecha, MAX(i.fecha) AS ultima_fecha
    FROM ingreso i
    JOIN sala sa  ON sa.codigo_sala = i.codigo_sala
    JOIN doctor d ON d.codigo_doctor = i.codigo_doctor
    WHERE i.fecha BETWEEN p_desde AND p_hasta
    GROUP BY sa.nombre_sala, i.tipo_procedimiento, d.nombre
    ORDER BY sa.nombre_sala, cantidad DESC;
END$$

-- R06. [JOIN] Permisos por alumno: cantidad y tiempo fuera (minutos)
CREATE PROCEDURE sp_rep_permisos_alumno(IN p_desde DATE, IN p_hasta DATE)
READS SQL DATA
BEGIN
    SELECT a.nombre AS alumno,
           COUNT(*) AS permisos,
           SUM(pm.hora_retorno IS NULL) AS abiertos,
           ROUND(SUM(TIME_TO_SEC(TIMEDIFF(pm.hora_retorno, pm.hora_salida))) / 60) AS minutos_totales,
           ROUND(AVG(TIME_TO_SEC(TIMEDIFF(pm.hora_retorno, pm.hora_salida))) / 60, 1) AS minutos_promedio,
           ROUND(MAX(TIME_TO_SEC(TIMEDIFF(pm.hora_retorno, pm.hora_salida))) / 60) AS minutos_maximo
    FROM permiso pm
    JOIN ingreso i ON i.codigo_ingreso = pm.codigo_ingreso
    JOIN alumno a  ON a.codigo_alumno = i.codigo_alumno
    WHERE i.fecha BETWEEN p_desde AND p_hasta
    GROUP BY a.codigo_alumno, a.nombre
    ORDER BY minutos_totales DESC;
END$$

-- R07. [JOIN] Permisos que superan un tiempo máximo (minutos)
CREATE PROCEDURE sp_rep_permisos_largos(IN p_desde DATE, IN p_hasta DATE, IN p_minutos INT)
READS SQL DATA
BEGIN
    SELECT i.fecha, a.nombre AS alumno, pa.nombre AS paciente, pm.motivo,
           pm.hora_salida, pm.hora_retorno,
           ROUND(TIME_TO_SEC(TIMEDIFF(pm.hora_retorno, pm.hora_salida)) / 60) AS minutos_fuera
    FROM permiso pm
    JOIN ingreso i       ON i.codigo_ingreso = pm.codigo_ingreso
    JOIN alumno a        ON a.codigo_alumno = i.codigo_alumno
    JOIN programacion p  ON p.codigo_programacion = i.codigo_programacion
    JOIN paciente pa     ON pa.dni = p.dni
    WHERE i.fecha BETWEEN p_desde AND p_hasta
      AND pm.hora_retorno IS NOT NULL
      AND TIME_TO_SEC(TIMEDIFF(pm.hora_retorno, pm.hora_salida)) > COALESCE(p_minutos, 30) * 60
    ORDER BY minutos_fuera DESC;
END$$

-- R08. [JOIN] Esterilización por alumno: ciclos, inasistencias y duración
CREATE PROCEDURE sp_rep_esterilizacion_alumno(IN p_desde DATE, IN p_hasta DATE)
READS SQL DATA
BEGIN
    SELECT a.nombre AS alumno,
           COUNT(*) AS ciclos,
           SUM(e.asistencia = 'No asistió') AS inasistencias,
           SUM(e.hora_fin IS NULL AND e.asistencia = 'Asistió') AS en_curso,
           ROUND(AVG(TIME_TO_SEC(TIMEDIFF(e.hora_fin, e.hora_inicio))) / 60, 1) AS minutos_promedio
    FROM esterilizacion e
    JOIN ingreso i ON i.codigo_ingreso = e.codigo_ingreso
    JOIN alumno a  ON a.codigo_alumno = i.codigo_alumno
    WHERE i.fecha BETWEEN p_desde AND p_hasta
    GROUP BY a.codigo_alumno, a.nombre
    ORDER BY inasistencias DESC, ciclos DESC;
END$$

-- R09. [JOIN] Historial completo de un paciente
CREATE PROCEDURE sp_rep_historial_paciente(IN p_dni CHAR(8))
READS SQL DATA
BEGIN
    SELECT p.codigo_programacion AS cita, p.dia_semana AS dia, p.bloque_horario AS bloque,
           COALESCE(p.asistencia, 'Pendiente') AS asistencia,
           i.fecha, i.hora_ingreso, a.nombre AS alumno,
           COALESCE(p.codigo_sillon, sa.nombre_sala) AS ubicacion,
           i.tipo_procedimiento AS procedimiento
    FROM programacion p
    LEFT JOIN ingreso i ON i.codigo_programacion = p.codigo_programacion
    LEFT JOIN alumno a  ON a.codigo_alumno = i.codigo_alumno
    LEFT JOIN sala sa   ON sa.codigo_sala = i.codigo_sala
    WHERE p.dni = p_dni AND p.activo = 1
    ORDER BY i.fecha IS NULL, i.fecha DESC, p.codigo_programacion;
END$$

-- R10. [JOIN] Citas vigentes que no generaron ingreso
CREATE PROCEDURE sp_rep_citas_sin_ingreso()
READS SQL DATA
BEGIN
    SELECT p.codigo_programacion AS cita, p.dia_semana AS dia, p.bloque_horario AS bloque,
           pa.dni, pa.nombre AS paciente, COALESCE(p.codigo_sillon, 'Sala') AS ubicacion,
           COALESCE(p.asistencia, 'Pendiente') AS estado
    FROM programacion p
    JOIN paciente pa ON pa.dni = p.dni
    WHERE p.activo = 1
      AND NOT EXISTS (SELECT 1 FROM ingreso i WHERE i.codigo_programacion = p.codigo_programacion)
    ORDER BY FIELD(p.dia_semana, 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'), p.bloque_horario;
END$$

-- R11. [JOIN] Pacientes por condición con sus citas y atenciones
CREATE PROCEDURE sp_rep_pacientes_condicion()
READS SQL DATA
BEGIN
    SELECT pa.condicion,
           COUNT(DISTINCT pa.dni) AS pacientes,
           COUNT(DISTINCT p.codigo_programacion) AS citas,
           COUNT(DISTINCT i.codigo_ingreso) AS atenciones
    FROM paciente pa
    LEFT JOIN programacion p ON p.dni = pa.dni AND p.activo = 1
    LEFT JOIN ingreso i ON i.codigo_programacion = p.codigo_programacion
    WHERE pa.activo = 1
    GROUP BY pa.condicion
    ORDER BY pacientes DESC;
END$$

-- R12. Resumen diario de ingresos
CREATE PROCEDURE sp_rep_ingresos_diarios(IN p_desde DATE, IN p_hasta DATE)
READS SQL DATA
BEGIN
    SELECT fecha, fn_dia_semana(fecha) AS dia,
           COUNT(*) AS ingresos,
           SUM(turno = 'Mañana') AS manana,
           SUM(turno = 'Tarde') AS tarde,
           SUM(codigo_sala IS NOT NULL) AS en_sala,
           MIN(hora_ingreso) AS primer_ingreso,
           MAX(hora_ingreso) AS ultimo_ingreso
    FROM ingreso
    WHERE fecha BETWEEN p_desde AND p_hasta
    GROUP BY fecha
    ORDER BY fecha;
END$$

-- R13. Auditoría: operaciones registradas por los triggers
CREATE PROCEDURE sp_rep_auditoria(IN p_desde DATE, IN p_hasta DATE, IN p_tabla VARCHAR(20))
READS SQL DATA
BEGIN
    SELECT au.fecha_hora, au.tabla, au.operacion, au.clave, au.detalle, au.usuario_bd,
           pe.nombre AS personal
    FROM auditoria au
    LEFT JOIN personal pe ON pe.codigo_personal = au.personal
    WHERE DATE(au.fecha_hora) BETWEEN p_desde AND p_hasta
      AND (p_tabla IS NULL OR p_tabla = '' OR au.tabla = p_tabla)
    ORDER BY au.id_auditoria DESC
    LIMIT 500;
END$$

DELIMITER ;

-- Verificación
SELECT routine_name AS procedimiento
FROM information_schema.routines
WHERE routine_schema = 'bd_ingreso_odontologico'
  AND routine_name REGEXP '^sp_(sesion|sillon|sala|personal|doctor|rep)_|^sp_cita_listar_eliminadas'
ORDER BY routine_name;


-- #####################################################################
-- ##  13_triggers_auditoria.sql
-- #####################################################################

-- =====================================================================
--  Script 13 - Triggers de auditoría y de borrado lógico
--  Base de datos: bd_ingreso_odontologico (MySQL 8.0)
--  Ejecutar con root en Workbench, después de cargar los datos.
--
--  - AFTER INSERT / AFTER UPDATE en las 10 tablas: registran la operación
--    en la tabla auditoria, con el usuario de MySQL y el personal del turno.
--  - AFTER DELETE en ingreso, permiso y esterilización: registran los datos
--    borrados al anular un registro de movimiento.
--  - BEFORE DELETE en catálogos y citas: impiden el borrado físico; en esas
--    tablas solo se permite el borrado lógico (activo = 0).
--  Los triggers trg_ingreso_bi y trg_ingreso_bu del script 01 se mantienen.
-- =====================================================================
SET NAMES utf8mb4;
USE bd_ingreso_odontologico;

DROP TRIGGER IF EXISTS trg_paciente_ai;
DROP TRIGGER IF EXISTS trg_paciente_au;
DROP TRIGGER IF EXISTS trg_paciente_ad;
DROP TRIGGER IF EXISTS trg_paciente_bd;
DROP TRIGGER IF EXISTS trg_alumno_ai;
DROP TRIGGER IF EXISTS trg_alumno_au;
DROP TRIGGER IF EXISTS trg_alumno_ad;
DROP TRIGGER IF EXISTS trg_alumno_bd;
DROP TRIGGER IF EXISTS trg_sillon_ai;
DROP TRIGGER IF EXISTS trg_sillon_au;
DROP TRIGGER IF EXISTS trg_sillon_ad;
DROP TRIGGER IF EXISTS trg_sillon_bd;
DROP TRIGGER IF EXISTS trg_sala_ai;
DROP TRIGGER IF EXISTS trg_sala_au;
DROP TRIGGER IF EXISTS trg_sala_ad;
DROP TRIGGER IF EXISTS trg_sala_bd;
DROP TRIGGER IF EXISTS trg_personal_ai;
DROP TRIGGER IF EXISTS trg_personal_au;
DROP TRIGGER IF EXISTS trg_personal_ad;
DROP TRIGGER IF EXISTS trg_personal_bd;
DROP TRIGGER IF EXISTS trg_doctor_ai;
DROP TRIGGER IF EXISTS trg_doctor_au;
DROP TRIGGER IF EXISTS trg_doctor_ad;
DROP TRIGGER IF EXISTS trg_doctor_bd;
DROP TRIGGER IF EXISTS trg_programacion_ai;
DROP TRIGGER IF EXISTS trg_programacion_au;
DROP TRIGGER IF EXISTS trg_programacion_ad;
DROP TRIGGER IF EXISTS trg_programacion_bd;
DROP TRIGGER IF EXISTS trg_ingreso_ai;
DROP TRIGGER IF EXISTS trg_ingreso_au;
DROP TRIGGER IF EXISTS trg_ingreso_ad;
DROP TRIGGER IF EXISTS trg_ingreso_bd;
DROP TRIGGER IF EXISTS trg_permiso_ai;
DROP TRIGGER IF EXISTS trg_permiso_au;
DROP TRIGGER IF EXISTS trg_permiso_ad;
DROP TRIGGER IF EXISTS trg_permiso_bd;
DROP TRIGGER IF EXISTS trg_esterilizacion_ai;
DROP TRIGGER IF EXISTS trg_esterilizacion_au;
DROP TRIGGER IF EXISTS trg_esterilizacion_ad;
DROP TRIGGER IF EXISTS trg_esterilizacion_bd;

DELIMITER $$

-- ------------------------------------------------------------ paciente
CREATE TRIGGER trg_paciente_ai AFTER INSERT ON paciente
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('paciente', 'INSERT', NEW.dni, LEFT(CONCAT_WS(' | ', NEW.nombre, NEW.condicion, CONCAT('activo=', NEW.activo)), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_paciente_au AFTER UPDATE ON paciente
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('paciente', 'UPDATE', NEW.dni, LEFT(CONCAT(CASE WHEN OLD.activo = 1 AND NEW.activo = 0 THEN 'DESACTIVADO. ' WHEN OLD.activo = 0 AND NEW.activo = 1 THEN 'RESTAURADO. ' ELSE '' END, 'antes: ', CONCAT_WS(' | ', OLD.nombre, OLD.condicion, CONCAT('activo=', OLD.activo)), ' / ahora: ', CONCAT_WS(' | ', NEW.nombre, NEW.condicion, CONCAT('activo=', NEW.activo))), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_paciente_bd BEFORE DELETE ON paciente
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se permite el borrado físico en paciente: use la desactivación (borrado lógico).';
END$$

-- ------------------------------------------------------------ alumno
CREATE TRIGGER trg_alumno_ai AFTER INSERT ON alumno
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('alumno', 'INSERT', NEW.codigo_alumno, LEFT(CONCAT_WS(' | ', NEW.codigo_qr, NEW.nombre, CONCAT('activo=', NEW.activo)), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_alumno_au AFTER UPDATE ON alumno
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('alumno', 'UPDATE', NEW.codigo_alumno, LEFT(CONCAT(CASE WHEN OLD.activo = 1 AND NEW.activo = 0 THEN 'DESACTIVADO. ' WHEN OLD.activo = 0 AND NEW.activo = 1 THEN 'RESTAURADO. ' ELSE '' END, 'antes: ', CONCAT_WS(' | ', OLD.codigo_qr, OLD.nombre, CONCAT('activo=', OLD.activo)), ' / ahora: ', CONCAT_WS(' | ', NEW.codigo_qr, NEW.nombre, CONCAT('activo=', NEW.activo))), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_alumno_bd BEFORE DELETE ON alumno
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se permite el borrado físico en alumno: use la desactivación (borrado lógico).';
END$$

-- ------------------------------------------------------------ sillon
CREATE TRIGGER trg_sillon_ai AFTER INSERT ON sillon
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('sillon', 'INSERT', NEW.codigo_sillon, LEFT(CONCAT('piso=', NEW.piso, ' | activo=', NEW.activo), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_sillon_au AFTER UPDATE ON sillon
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('sillon', 'UPDATE', NEW.codigo_sillon, LEFT(CONCAT(CASE WHEN OLD.activo = 1 AND NEW.activo = 0 THEN 'DESACTIVADO. ' WHEN OLD.activo = 0 AND NEW.activo = 1 THEN 'RESTAURADO. ' ELSE '' END, 'antes: ', CONCAT('piso=', OLD.piso, ' | activo=', OLD.activo), ' / ahora: ', CONCAT('piso=', NEW.piso, ' | activo=', NEW.activo)), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_sillon_bd BEFORE DELETE ON sillon
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se permite el borrado físico en sillon: use la desactivación (borrado lógico).';
END$$

-- ------------------------------------------------------------ sala
CREATE TRIGGER trg_sala_ai AFTER INSERT ON sala
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('sala', 'INSERT', CONCAT(NEW.codigo_sala), LEFT(CONCAT_WS(' | ', NEW.nombre_sala, CONCAT('activo=', NEW.activo)), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_sala_au AFTER UPDATE ON sala
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('sala', 'UPDATE', CONCAT(NEW.codigo_sala), LEFT(CONCAT(CASE WHEN OLD.activo = 1 AND NEW.activo = 0 THEN 'DESACTIVADO. ' WHEN OLD.activo = 0 AND NEW.activo = 1 THEN 'RESTAURADO. ' ELSE '' END, 'antes: ', CONCAT_WS(' | ', OLD.nombre_sala, CONCAT('activo=', OLD.activo)), ' / ahora: ', CONCAT_WS(' | ', NEW.nombre_sala, CONCAT('activo=', NEW.activo))), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_sala_bd BEFORE DELETE ON sala
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se permite el borrado físico en sala: use la desactivación (borrado lógico).';
END$$

-- ------------------------------------------------------------ personal
CREATE TRIGGER trg_personal_ai AFTER INSERT ON personal
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('personal', 'INSERT', CONCAT(NEW.codigo_personal), LEFT(CONCAT_WS(' | ', NEW.nombre, CONCAT('activo=', NEW.activo)), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_personal_au AFTER UPDATE ON personal
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('personal', 'UPDATE', CONCAT(NEW.codigo_personal), LEFT(CONCAT(CASE WHEN OLD.activo = 1 AND NEW.activo = 0 THEN 'DESACTIVADO. ' WHEN OLD.activo = 0 AND NEW.activo = 1 THEN 'RESTAURADO. ' ELSE '' END, 'antes: ', CONCAT_WS(' | ', OLD.nombre, CONCAT('activo=', OLD.activo)), ' / ahora: ', CONCAT_WS(' | ', NEW.nombre, CONCAT('activo=', NEW.activo))), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_personal_bd BEFORE DELETE ON personal
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se permite el borrado físico en personal: use la desactivación (borrado lógico).';
END$$

-- ------------------------------------------------------------ doctor
CREATE TRIGGER trg_doctor_ai AFTER INSERT ON doctor
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('doctor', 'INSERT', CONCAT(NEW.codigo_doctor), LEFT(CONCAT_WS(' | ', NEW.nombre, CONCAT('activo=', NEW.activo)), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_doctor_au AFTER UPDATE ON doctor
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('doctor', 'UPDATE', CONCAT(NEW.codigo_doctor), LEFT(CONCAT(CASE WHEN OLD.activo = 1 AND NEW.activo = 0 THEN 'DESACTIVADO. ' WHEN OLD.activo = 0 AND NEW.activo = 1 THEN 'RESTAURADO. ' ELSE '' END, 'antes: ', CONCAT_WS(' | ', OLD.nombre, CONCAT('activo=', OLD.activo)), ' / ahora: ', CONCAT_WS(' | ', NEW.nombre, CONCAT('activo=', NEW.activo))), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_doctor_bd BEFORE DELETE ON doctor
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se permite el borrado físico en doctor: use la desactivación (borrado lógico).';
END$$

-- ------------------------------------------------------------ programacion
CREATE TRIGGER trg_programacion_ai AFTER INSERT ON programacion
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('programacion', 'INSERT', NEW.codigo_programacion, LEFT(CONCAT_WS(' | ', NEW.dia_semana, NEW.bloque_horario, NEW.dni, IFNULL(NEW.codigo_sillon, 'sala'), IFNULL(NEW.asistencia, 'pendiente'), CONCAT('activo=', NEW.activo)), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_programacion_au AFTER UPDATE ON programacion
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('programacion', 'UPDATE', NEW.codigo_programacion, LEFT(CONCAT(CASE WHEN OLD.activo = 1 AND NEW.activo = 0 THEN 'DESACTIVADO. ' WHEN OLD.activo = 0 AND NEW.activo = 1 THEN 'RESTAURADO. ' ELSE '' END, 'antes: ', CONCAT_WS(' | ', OLD.dia_semana, OLD.bloque_horario, OLD.dni, IFNULL(OLD.codigo_sillon, 'sala'), IFNULL(OLD.asistencia, 'pendiente'), CONCAT('activo=', OLD.activo)), ' / ahora: ', CONCAT_WS(' | ', NEW.dia_semana, NEW.bloque_horario, NEW.dni, IFNULL(NEW.codigo_sillon, 'sala'), IFNULL(NEW.asistencia, 'pendiente'), CONCAT('activo=', NEW.activo))), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_programacion_bd BEFORE DELETE ON programacion
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se permite el borrado físico en programacion: use la desactivación (borrado lógico).';
END$$

-- ------------------------------------------------------------ ingreso
CREATE TRIGGER trg_ingreso_ai AFTER INSERT ON ingreso
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('ingreso', 'INSERT', NEW.codigo_ingreso, LEFT(CONCAT_WS(' | ', NEW.fecha, NEW.hora_ingreso, NEW.turno, CONCAT('cita ', NEW.codigo_programacion), CONCAT('alumno ', NEW.codigo_alumno), IFNULL(NEW.tipo_procedimiento, 'sillón')), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_ingreso_au AFTER UPDATE ON ingreso
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('ingreso', 'UPDATE', NEW.codigo_ingreso, LEFT(CONCAT('antes: ', CONCAT_WS(' | ', OLD.fecha, OLD.hora_ingreso, OLD.turno, CONCAT('cita ', OLD.codigo_programacion), CONCAT('alumno ', OLD.codigo_alumno), IFNULL(OLD.tipo_procedimiento, 'sillón')), ' / ahora: ', CONCAT_WS(' | ', NEW.fecha, NEW.hora_ingreso, NEW.turno, CONCAT('cita ', NEW.codigo_programacion), CONCAT('alumno ', NEW.codigo_alumno), IFNULL(NEW.tipo_procedimiento, 'sillón'))), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_ingreso_ad AFTER DELETE ON ingreso
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('ingreso', 'DELETE', OLD.codigo_ingreso, LEFT(CONCAT('anulado: ', CONCAT_WS(' | ', OLD.fecha, OLD.hora_ingreso, OLD.turno, CONCAT('cita ', OLD.codigo_programacion), CONCAT('alumno ', OLD.codigo_alumno), IFNULL(OLD.tipo_procedimiento, 'sillón'))), 255), USER(), @personal_app);
END$$

-- ------------------------------------------------------------ permiso
CREATE TRIGGER trg_permiso_ai AFTER INSERT ON permiso
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('permiso', 'INSERT', CONCAT(NEW.codigo_ingreso, ' ', NEW.hora_salida), LEFT(CONCAT_WS(' | ', NEW.motivo, CONCAT('retorno ', IFNULL(NEW.hora_retorno, 'pendiente'))), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_permiso_au AFTER UPDATE ON permiso
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('permiso', 'UPDATE', CONCAT(NEW.codigo_ingreso, ' ', NEW.hora_salida), LEFT(CONCAT('antes: ', CONCAT_WS(' | ', OLD.motivo, CONCAT('retorno ', IFNULL(OLD.hora_retorno, 'pendiente'))), ' / ahora: ', CONCAT_WS(' | ', NEW.motivo, CONCAT('retorno ', IFNULL(NEW.hora_retorno, 'pendiente')))), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_permiso_ad AFTER DELETE ON permiso
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('permiso', 'DELETE', CONCAT(OLD.codigo_ingreso, ' ', OLD.hora_salida), LEFT(CONCAT('anulado: ', CONCAT_WS(' | ', OLD.motivo, CONCAT('retorno ', IFNULL(OLD.hora_retorno, 'pendiente')))), 255), USER(), @personal_app);
END$$

-- ------------------------------------------------------------ esterilizacion
CREATE TRIGGER trg_esterilizacion_ai AFTER INSERT ON esterilizacion
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('esterilizacion', 'INSERT', CONCAT(NEW.codigo_ingreso, ' ', NEW.hora_inicio), LEFT(CONCAT_WS(' | ', NEW.asistencia, CONCAT('fin ', IFNULL(NEW.hora_fin, 'en curso'))), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_esterilizacion_au AFTER UPDATE ON esterilizacion
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('esterilizacion', 'UPDATE', CONCAT(NEW.codigo_ingreso, ' ', NEW.hora_inicio), LEFT(CONCAT('antes: ', CONCAT_WS(' | ', OLD.asistencia, CONCAT('fin ', IFNULL(OLD.hora_fin, 'en curso'))), ' / ahora: ', CONCAT_WS(' | ', NEW.asistencia, CONCAT('fin ', IFNULL(NEW.hora_fin, 'en curso')))), 255), USER(), @personal_app);
END$$

CREATE TRIGGER trg_esterilizacion_ad AFTER DELETE ON esterilizacion
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla, operacion, clave, detalle, usuario_bd, personal)
    VALUES ('esterilizacion', 'DELETE', CONCAT(OLD.codigo_ingreso, ' ', OLD.hora_inicio), LEFT(CONCAT('anulado: ', CONCAT_WS(' | ', OLD.asistencia, CONCAT('fin ', IFNULL(OLD.hora_fin, 'en curso')))), 255), USER(), @personal_app);
END$$

DELIMITER ;

-- Verificación: triggers de la base
SELECT trigger_name AS trigger_, event_object_table AS tabla, action_timing AS momento, event_manipulation AS evento
FROM information_schema.triggers
WHERE trigger_schema = 'bd_ingreso_odontologico'
ORDER BY event_object_table, action_timing, event_manipulation;


-- #####################################################################
-- ##  08_usuario_aplicativo.sql
-- #####################################################################

-- =====================================================================
--  Script 8 - Usuario de MySQL para el aplicativo
--  Ejecutar con root en Workbench, después de 01, 02 y 09
--  El aplicativo solo puede EJECUTAR las funciones y procedimientos;
--  no puede leer ni modificar las tablas directamente.
-- =====================================================================
DROP USER IF EXISTS 'app_ingreso'@'localhost';
CREATE USER 'app_ingreso'@'localhost' IDENTIFIED BY 'Ingreso2026!';

GRANT EXECUTE ON bd_ingreso_odontologico.* TO 'app_ingreso'@'localhost';

FLUSH PRIVILEGES;
SHOW GRANTS FOR 'app_ingreso'@'localhost';

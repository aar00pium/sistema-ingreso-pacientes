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

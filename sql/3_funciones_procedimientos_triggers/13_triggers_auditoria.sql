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

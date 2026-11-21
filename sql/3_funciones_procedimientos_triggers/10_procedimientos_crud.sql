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

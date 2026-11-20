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

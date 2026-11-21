<?php
/*
 * Conexión a MySQL con PDO y funciones para llamar a las rutinas de la base.
 * El aplicativo no escribe consultas SQL: solo llama a funciones (fn_...)
 * y procedimientos almacenados (sp_...) definidos en sql/3_funciones_procedimientos_triggers/
 */
require_once __DIR__ . '/../config.php';

/**
 * Abre una conexión a la base de datos cuyo nombre se recibe como parámetro.
 */
function conectar(string $baseDatos): PDO
{
    $dsn = 'mysql:host=' . DB_HOST . ';port=' . DB_PORT . ';dbname=' . $baseDatos . ';charset=utf8mb4';
    return new PDO($dsn, DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
        PDO::ATTR_TIMEOUT            => 5,
    ]);
}

/**
 * Conexión única por petición a la base configurada en config.php.
 */
function db(): PDO
{
    static $pdo = null;
    if ($pdo === null) {
        $pdo = conectar(DB_NAME);
        // Informa a la base quién tiene el turno abierto: los triggers de
        // auditoría lo guardan junto con cada operación.
        if (!empty($_SESSION['personal']['codigo_personal'])) {
            llamar_procedimiento('sp_sesion_iniciar', [$_SESSION['personal']['codigo_personal']], $pdo);
        }
    }
    return $pdo;
}

/**
 * Llama a un procedimiento almacenado y devuelve sus filas.
 * Ejemplo: llamar_procedimiento('sp_agenda_dia', ['Martes'])  ->  CALL sp_agenda_dia(?)
 */
function llamar_procedimiento(string $nombre, array $parametros = [], ?PDO $pdo = null): array
{
    if (!preg_match('/^sp_[a-z_]+$/', $nombre)) {
        throw new InvalidArgumentException("Nombre de procedimiento no válido: $nombre");
    }
    $pdo = $pdo ?? db();
    $marcas = implode(', ', array_fill(0, count($parametros), '?'));
    $stmt = $pdo->prepare("CALL $nombre($marcas)");
    $stmt->execute(array_values($parametros));
    // Un CALL puede devolver varios resultados; se toma el primero que tenga filas
    // y se descartan los demás (incluido el resultado de estado que agrega MySQL).
    $filas = null;
    do {
        if ($stmt->columnCount() > 0) {
            $resultado = $stmt->fetchAll();
            if ($filas === null) {
                $filas = $resultado;
            }
        }
    } while ($stmt->nextRowset());
    $stmt->closeCursor();
    $filas = $filas ?? [];
    return $filas;
}

/**
 * Llama a una función almacenada y devuelve su valor.
 * Ejemplo: llamar_funcion('fn_dia_semana', ['2026-10-19'])  ->  SELECT fn_dia_semana(?)
 */
function llamar_funcion(string $nombre, array $parametros = [], ?PDO $pdo = null)
{
    if (!preg_match('/^fn_[a-z_]+$/', $nombre)) {
        throw new InvalidArgumentException("Nombre de función no válido: $nombre");
    }
    $pdo = $pdo ?? db();
    $marcas = implode(', ', array_fill(0, count($parametros), '?'));
    $stmt = $pdo->prepare("SELECT $nombre($marcas) AS valor");
    $stmt->execute(array_values($parametros));
    $valor = $stmt->fetchColumn();
    $stmt->closeCursor();
    return $valor;
}

/**
 * Prueba la conexión a una base de datos y reúne información con sus procedimientos.
 */
function probar_conexion(string $baseDatos): array
{
    $info = [
        'ok' => false, 'host' => DB_HOST, 'puerto' => DB_PORT,
        'usuario' => DB_USER, 'base' => $baseDatos,
    ];
    $inicio = microtime(true);
    try {
        $pdo = conectar($baseDatos);
        $info['ms'] = round((microtime(true) - $inicio) * 1000, 1);

        $info['servidor'] = llamar_procedimiento('sp_info_servidor', [], $pdo)[0];
        $info['tablas']   = llamar_procedimiento('sp_conteo_tablas', [], $pdo);
        $info['objetos']  = llamar_procedimiento('sp_objetos_base', [], $pdo);
        $info['dia_hoy']  = llamar_funcion('fn_dia_semana', [date('Y-m-d')], $pdo);

        // Prueba de seguridad: el usuario del aplicativo NO debe poder leer tablas directamente
        try {
            $pdo->query('SELECT COUNT(*) FROM paciente');
            $info['acceso_directo'] = 'Permitido (revisar permisos del usuario)';
        } catch (PDOException $e) {
            $info['acceso_directo'] = 'Bloqueado: ' . $e->errorInfo[2];
        }
        $info['ok'] = true;
    } catch (PDOException $e) {
        $info['ms'] = $info['ms'] ?? round((microtime(true) - $inicio) * 1000, 1);
        $info['error_codigo'] = $e->errorInfo[1] ?? $e->getCode();
        $info['error'] = $e->getMessage();
    }
    return $info;
}

/**
 * Convierte un error de MySQL en un mensaje claro para el usuario.
 * Los mensajes de los procedimientos (SIGNAL) se muestran tal cual; los de las
 * reglas de la base (CHECK, UNIQUE, claves foráneas) se traducen por su nombre.
 */
function mensaje_error(PDOException $e): string
{
    $codigo = (int)($e->errorInfo[1] ?? 0);
    $texto  = (string)($e->errorInfo[2] ?? $e->getMessage());

    $reglas = [
        'ck_paciente_dni'              => 'El DNI debe tener exactamente 8 dígitos.',
        'ck_paciente_condicion'        => 'La condición del paciente debe ser Adulto, Niño o Prenatal.',
        'ck_alumno_codigo'             => 'El código de alumno debe tener solo números (hasta 10 dígitos).',
        'ck_programacion_dia'          => 'El día de la cita debe ser de lunes a sábado.',
        'ck_programacion_bloque'       => 'El bloque horario no es válido: la hora de inicio debe ser menor que la de fin.',
        'ck_programacion_asistencia'   => 'La asistencia debe ser Asistió o No asistió.',
        'ck_ingreso_turno'             => 'El turno debe ser Mañana o Tarde.',
        'ck_permiso_retorno'           => 'La hora de retorno debe ser posterior a la hora de salida.',
        'ck_esterilizacion_fin'        => 'La hora de fin debe ser posterior a la hora de inicio.',
        'ck_esterilizacion_asistencia' => 'La asistencia debe ser Asistió o No asistió.',
        'ck_sillon_codigo'             => 'El código del sillón debe ser una letra mayúscula seguida de uno o dos dígitos (por ejemplo A1).',
        'ck_sillon_piso'               => 'El piso debe estar entre 1 y 3.',
        'ck_sala_codigo'               => 'El código de sala debe estar entre 1 y 99.',
        'ck_personal_codigo'           => 'El código del personal debe estar entre 1 y 9999.',
        'ck_doctor_codigo'             => 'El código del doctor debe estar entre 1 y 9999.',
        'uq_alumno_qr'                 => 'Ese código QR ya está asignado a otro alumno.',
        'uq_ingreso_programacion'      => 'Esa cita ya tiene un ingreso registrado.',
    ];

    switch ($codigo) {
        case 1644:                       // SIGNAL de un procedimiento o trigger
            return $texto;
        case 3819:                       // regla CHECK incumplida
        case 1062:                       // valor repetido (PRIMARY KEY o UNIQUE)
            foreach ($reglas as $nombre => $mensaje) {
                if (strpos($texto, $nombre) !== false) {
                    return "$mensaje (regla $nombre)";
                }
            }
            return $codigo === 1062 ? 'Ya existe un registro con ese código.' : 'Un dato no cumple las reglas de la base de datos.';
        case 1451:
            return 'No se puede eliminar porque tiene registros relacionados.';
        case 1452:
            return 'El dato relacionado (paciente, sillón, sala o doctor) no existe.';
        case 1406:
            return 'Uno de los datos es demasiado largo.';
        case 1048:
            return 'Falta completar un dato obligatorio.';
        default:
            return "Error $codigo: $texto";
    }
}


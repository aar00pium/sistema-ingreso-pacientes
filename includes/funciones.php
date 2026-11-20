<?php
/**
 * Funciones de apoyo para todas las pantallas.
 *
 * Sesión y zona horaria, turno obligatorio, menú, plantilla común (cabecera y pie),
 * mensajes de resultado, formato de fechas y horas, escape de HTML y manejo de errores.
 */
require_once __DIR__ . '/conexion.php';

session_start();
date_default_timezone_set('America/Lima');

const TURNOS = ['Mañana', 'Tarde'];
const DIAS = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
const CONDICIONES = ['Adulto', 'Niño', 'Prenatal'];

/** Escapa texto para mostrarlo en HTML. */
function e($texto): string
{
    return htmlspecialchars((string)($texto ?? ''), ENT_QUOTES, 'UTF-8');
}

/** '08:08:00' -> '08:08' */
function hora(?string $valor): string
{
    return $valor ? substr($valor, 0, 5) : '-';
}

/** '2026-10-19' -> '19/10/2026' */
function fecha_corta(string $valor): string
{
    return date('d/m/Y', strtotime($valor));
}

/** Fecha pedida en la URL; si no hay, la de hoy o la última con ingresos (fn_fecha_con_datos). */
function leer_fecha(): string
{
    $texto = $_GET['fecha'] ?? '';
    $f = DateTime::createFromFormat('Y-m-d', $texto);
    if ($f && $f->format('Y-m-d') === $texto) {
        return $texto;
    }
    return llamar_funcion('fn_fecha_con_datos', [date('Y-m-d')]);
}

/** Obliga a iniciar turno antes de usar los módulos de recepción. */
function requiere_turno(): void
{
    if (empty($_SESSION['personal'])) {
        header('Location: turno.php');
        exit;
    }
}

/** Si ocurre un error de base de datos en cualquier pantalla, se muestra un aviso. */
set_exception_handler(function (Throwable $ex) {
    http_response_code(503);
    cabecera('Error de base de datos', '');
    echo '<h1>No se pudo completar la operación</h1>';
    echo '<div class="estado mal">Error de base de datos</div>';
    echo '<p>' . e($ex->getMessage()) . '</p>';
    echo '<p><a class="boton" href="prueba_conexion.php">Ir a la prueba de conexión</a></p>';
    pie();
});

/* Menú: grupo => [archivo => nombre] */
const MENU = [
    'Recepción' => [
        'index.php'             => 'Inicio',
        'agenda.php'            => 'Agenda del día',
        'qr.php'                => 'Validar alumno (QR)',
        'registrar_ingreso.php' => 'Registrar ingreso',
        'ingresos.php'          => 'Ingresos del día',
        'permisos.php'          => 'Permisos de salida',
        'esterilizacion.php'    => 'Esterilización',
    ],
    'Administración' => [
        'citas.php'                     => 'Citas',
        'pacientes.php'                 => 'Pacientes',
        'alumnos.php'                   => 'Alumnos',
        'catalogos.php?t=sillon'        => 'Sillones',
        'catalogos.php?t=sala'          => 'Salas',
        'catalogos.php?t=personal'      => 'Personal',
        'catalogos.php?t=doctor'        => 'Doctores',
    ],
    'Consultas' => [
        'reportes.php'          => 'Reportes',
    ],
    'Sistema' => [
        'prueba_conexion.php'   => 'Prueba de conexión',
    ],
];

/** Guarda un mensaje para mostrarlo en la siguiente pantalla. */
function avisar(string $tipo, string $mensaje): void
{
    $_SESSION['avisos'][] = [$tipo, $mensaje];
}

/** Redirige (patrón POST, luego GET) y termina. */
function ir(string $url): void
{
    header('Location: ' . $url);
    exit;
}

/**
 * Ejecuta una operación de escritura (un procedimiento) y muestra el resultado.
 * Si la base rechaza la operación, se muestra el motivo traducido.
 */
function ejecutar(callable $operacion, string $exito): bool
{
    try {
        $operacion();
        if ($exito !== '') {
            avisar('ok', $exito);
        }
        return true;
    } catch (PDOException $e) {
        avisar('error', mensaje_error($e));
        return false;
    }
}

/** Opciones de un <select> a partir de filas. */
function opciones(array $filas, string $valor, string $texto, $elegido = null, string $vacio = ''): string
{
    $html = $vacio !== '' ? '<option value="">' . e($vacio) . '</option>' : '';
    foreach ($filas as $f) {
        $sel = ((string)$f[$valor] === (string)$elegido) ? ' selected' : '';
        $html .= '<option value="' . e($f[$valor]) . '"' . $sel . '>' . e($f[$texto]) . '</option>';
    }
    return $html;
}

/** Opciones de un <select> a partir de una lista simple. */
function opciones_lista(array $lista, $elegido = null): string
{
    $html = '';
    foreach ($lista as $v) {
        $html .= '<option' . ((string)$v === (string)$elegido ? ' selected' : '') . '>' . e($v) . '</option>';
    }
    return $html;
}

/** Valor de un campo POST sin espacios extra. */
function campo(string $nombre): string
{
    return trim((string)($_POST[$nombre] ?? ''));
}

function cabecera(string $titulo, string $activo): void
{
    $p = $_SESSION['personal'] ?? null;
    ?><!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?= e($titulo) ?></title>
  <link rel="stylesheet" href="css/estilos.css">
</head>
<body>
<header class="barra">
  <div class="marca">Sistema de Ingreso de Pacientes</div>
  <?php if ($p): ?>
  <div class="usuario"><?= e($p['nombre']) ?> &middot; Turno <?= e($_SESSION['turno']) ?>
    <a href="salir.php">Cerrar turno</a></div>
  <?php endif; ?>
</header>
<div class="contenedor">
  <?php if ($p): ?>
  <nav class="menu">
    <?php foreach (MENU as $grupo => $items): ?>
      <div class="sep"><?= e($grupo) ?></div>
      <?php foreach ($items as $archivo => $nombre): ?>
        <a href="<?= $archivo ?>" class="<?= $archivo === $activo ? 'activo' : '' ?>"><?= e($nombre) ?></a>
      <?php endforeach; ?>
    <?php endforeach; ?>
  </nav>
  <?php endif; ?>
  <main class="contenido">
  <?php if (!empty($_SESSION['aviso'])): ?>
    <div class="aviso"><?= e($_SESSION['aviso']) ?></div>
    <?php unset($_SESSION['aviso']); ?>
  <?php endif;
  foreach ($_SESSION['avisos'] ?? [] as [$tipo, $mensaje]) {
      echo '<div class="mensaje ' . $tipo . '">' . e($mensaje) . '</div>';
  }
  unset($_SESSION['avisos']);
}

function pie(): void
{
    echo "  </main>\n</div>\n</body>\n</html>\n";
}

/** Formulario de filtro por fecha (y turno opcional). */
function filtro_fecha(string $fecha, ?array $turnos = null, ?string $turnoSel = null): void
{
    echo '<form class="filtro" method="get">';
    echo '<label>Fecha <input type="date" name="fecha" value="' . e($fecha) . '"></label>';
    if ($turnos) {
        echo '<label>Turno <select name="turno">';
        foreach ($turnos as $t) {
            echo '<option' . ($t === $turnoSel ? ' selected' : '') . '>' . e($t) . '</option>';
        }
        echo '</select></label>';
    }
    echo '<button class="boton">Ver</button></form>';
}

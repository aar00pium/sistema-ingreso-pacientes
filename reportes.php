<?php
/**
 * Reportes del sistema.
 *
 * Cada reporte es un procedimiento almacenado (sp_rep_...). La pantalla muestra la
 * lista de reportes, pide los parámetros que necesita el elegido (rango de fechas,
 * DNI, minutos o tabla), lo ejecuta y muestra el resultado. Permite imprimir y
 * exportar el resultado a CSV.
 */
require_once 'includes/funciones.php';
requiere_turno();

/* id => [título, descripción, procedimiento, parámetros, usa JOIN] */
$REPORTES = [
    'r01' => ['Asistencia por día de la semana', 'Citas vigentes, asistencias, inasistencias, pendientes y porcentaje de asistencia por día.', 'sp_rep_asistencia_dia', [], false],
    'r02' => ['Atenciones por alumno', 'Atenciones de cada alumno en sillón y en sala, pacientes distintos y última atención.', 'sp_rep_atenciones_alumno', ['desde', 'hasta'], true],
    'r03' => ['Ingresos por personal de recepción', 'Ingresos validados por cada integrante de recepción en cada turno y días trabajados.', 'sp_rep_ingresos_personal', ['desde', 'hasta'], true],
    'r04' => ['Uso de sillones', 'Atenciones por sillón y piso, separadas por turno, con las citas vigentes de cada sillón.', 'sp_rep_uso_sillones', ['desde', 'hasta'], true],
    'r05' => ['Procedimientos en sala', 'Procedimientos realizados en cada sala con el doctor que los supervisó.', 'sp_rep_procedimientos_sala', ['desde', 'hasta'], true],
    'r06' => ['Permisos por alumno', 'Cantidad de permisos y minutos fuera (total, promedio y máximo) por alumno.', 'sp_rep_permisos_alumno', ['desde', 'hasta'], true],
    'r07' => ['Permisos que superan un tiempo', 'Permisos cuyo tiempo fuera supera los minutos indicados, con el paciente que se atendía.', 'sp_rep_permisos_largos', ['desde', 'hasta', 'minutos'], true],
    'r08' => ['Esterilización por alumno', 'Ciclos de esterilización, inasistencias, ciclos en curso y duración promedio por alumno.', 'sp_rep_esterilizacion_alumno', ['desde', 'hasta'], true],
    'r09' => ['Historial de un paciente', 'Todas las citas de un paciente con su asistencia, el alumno que lo atendió y la ubicación.', 'sp_rep_historial_paciente', ['dni'], true],
    'r10' => ['Citas sin ingreso', 'Citas vigentes que no generaron ingreso: inasistencias y citas pendientes.', 'sp_rep_citas_sin_ingreso', [], true],
    'r11' => ['Pacientes por condición', 'Pacientes, citas y atenciones agrupados por condición (Adulto, Niño, Prenatal).', 'sp_rep_pacientes_condicion', [], true],
    'r12' => ['Resumen diario de ingresos', 'Ingresos por fecha, por turno y en sala, con la hora del primer y último ingreso.', 'sp_rep_ingresos_diarios', ['desde', 'hasta'], false],
    'r13' => ['Auditoría de operaciones', 'Operaciones registradas por los triggers: tabla, operación, datos, usuario y personal del turno.', 'sp_rep_auditoria', ['desde', 'hasta', 'tabla'], true],
];
$TABLAS = ['', 'paciente', 'alumno', 'programacion', 'ingreso', 'permiso', 'esterilizacion', 'sillon', 'sala', 'personal', 'doctor'];

/* ---------- Parámetros ---------- */
$id = $_GET['r'] ?? '';
$p = [
    'desde'   => $_GET['desde'] ?? '2026-10-01',
    'hasta'   => $_GET['hasta'] ?? date('Y-m-d'),
    'dni'     => trim($_GET['dni'] ?? ''),
    'minutos' => (int)($_GET['minutos'] ?? 30),
    'tabla'   => $_GET['tabla'] ?? '',
];
$filas = null;
if (isset($REPORTES[$id])) {
    [$titulo, $descripcion, $proc, $params] = $REPORTES[$id];
    $valores = array_map(fn($k) => $p[$k], $params);
    if (!in_array('dni', $params, true) || $p['dni'] !== '') {
        $filas = llamar_procedimiento($proc, $valores);
    }
    /* Exportar a CSV (separado por punto y coma, para Excel en español) */
    if (isset($_GET['csv']) && $filas !== null) {
        header('Content-Type: text/csv; charset=utf-8');
        header('Content-Disposition: attachment; filename="' . $id . '_' . date('Ymd') . '.csv"');
        $salida = fopen('php://output', 'w');
        fwrite($salida, "\xEF\xBB\xBF");
        if ($filas) {
            fputcsv($salida, array_keys($filas[0]), ';');
        }
        foreach ($filas as $f) {
            fputcsv($salida, $f, ';');
        }
        exit;
    }
}

/** Da formato a un valor según su tipo: fecha, hora o texto. */
function celda($v): string
{
    if ($v === null) {
        return '-';
    }
    if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $v)) {
        return fecha_corta($v);
    }
    if (preg_match('/^\d{2}:\d{2}:\d{2}$/', $v)) {
        return substr($v, 0, 5);
    }
    return e($v);
}

cabecera('Reportes', 'reportes.php');
?>
<h1>Reportes</h1>

<?php if (!isset($REPORTES[$id])): ?>
<p class="nota">Elija un reporte. Todos se obtienen con procedimientos almacenados; los marcados con JOIN combinan varias tablas.</p>
<div class="reportes">
  <?php foreach ($REPORTES as $rid => [$t, $d, $proc, $params, $join]): ?>
    <a class="reporte" href="reportes.php?r=<?= $rid ?>">
      <b><?= strtoupper($rid) ?>. <?= e($t) ?></b>
      <span><?= e($d) ?></span>
      <small><?= e($proc) ?><?= $join ? ' · JOIN' : '' ?></small>
    </a>
  <?php endforeach; ?>
</div>
<?php else: ?>
<p><a href="reportes.php">&larr; Todos los reportes</a></p>
<h2><?= strtoupper($id) ?>. <?= e($titulo) ?></h2>
<p class="nota"><?= e($descripcion) ?> <code>CALL <?= e($proc) ?></code></p>

<?php if ($params): ?>
<form class="filtro no-imprimir" method="get">
  <input type="hidden" name="r" value="<?= e($id) ?>">
  <?php if (in_array('desde', $params, true)): ?>
    <label>Desde <input type="date" name="desde" value="<?= e($p['desde']) ?>"></label>
    <label>Hasta <input type="date" name="hasta" value="<?= e($p['hasta']) ?>"></label>
  <?php endif; ?>
  <?php if (in_array('dni', $params, true)): ?>
    <label>DNI del paciente <input name="dni" value="<?= e($p['dni']) ?>" maxlength="8" required></label>
  <?php endif; ?>
  <?php if (in_array('minutos', $params, true)): ?>
    <label>Más de (minutos) <input type="number" name="minutos" min="1" value="<?= e($p['minutos']) ?>"></label>
  <?php endif; ?>
  <?php if (in_array('tabla', $params, true)): ?>
    <label>Tabla <select name="tabla"><?php foreach ($TABLAS as $tb): ?><option value="<?= $tb ?>" <?= $tb === $p['tabla'] ? 'selected' : '' ?>><?= $tb === '' ? 'Todas' : e($tb) ?></option><?php endforeach; ?></select></label>
  <?php endif; ?>
  <button class="boton">Generar</button>
</form>
<?php endif; ?>

<?php if ($filas === null): ?>
  <p class="vacio">Complete los datos y genere el reporte.</p>
<?php elseif (!$filas): ?>
  <p class="vacio">El reporte no tiene resultados para los datos elegidos.</p>
<?php else: ?>
  <div class="botones no-imprimir">
    <button class="boton claro" onclick="window.print()">Imprimir</button>
    <a class="boton claro" href="reportes.php?<?= e(http_build_query(array_merge($_GET, ['csv' => 1]))) ?>">Exportar CSV</a>
  </div>
  <table class="lista">
    <thead><tr><?php foreach (array_keys($filas[0]) as $col): ?><th><?= e(ucfirst(str_replace('_', ' ', $col))) ?></th><?php endforeach; ?></tr></thead>
    <tbody>
    <?php foreach ($filas as $f): ?>
      <tr><?php foreach ($f as $v): ?><td><?= celda($v) ?></td><?php endforeach; ?></tr>
    <?php endforeach; ?>
    </tbody>
  </table>
  <p class="nota"><?= count($filas) ?> filas.</p>
<?php endif; ?>
<?php endif; ?>
<?php pie();

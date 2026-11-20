<?php
/**
 * Ingresos de una fecha y turno, con opción de anular un ingreso.
 *
 * Al anular se eliminan sus permisos y esterilizaciones (quedan en auditoría) y la
 * cita vuelve a pendiente. Procedimientos: sp_ingresos_dia, sp_ingreso_anular.
 */
require_once 'includes/funciones.php';
requiere_turno();

/* Anular un ingreso: se eliminan sus permisos y esterilizaciones y la cita vuelve a pendiente */
if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['accion'] ?? '') === 'anular') {
    ejecutar(fn() => llamar_procedimiento('sp_ingreso_anular', [campo('codigo')]),
             'Ingreso ' . campo('codigo') . ' anulado. La cita volvió a quedar pendiente.');
    ir('ingresos.php?fecha=' . urlencode(campo('fecha')) . '&turno=' . urlencode(campo('turno')));
}

$fecha    = leer_fecha();
$opciones = array_merge(TURNOS, ['Todos']);
// Por defecto se muestran todos los turnos del día
$turno    = $_GET['turno'] ?? 'Todos';
if (!in_array($turno, $opciones, true)) {
    $turno = 'Todos';
}
// NULL en el turno = todo el día (así lo interpreta sp_ingresos_dia)
$filas = llamar_procedimiento('sp_ingresos_dia', [$fecha, $turno === 'Todos' ? null : $turno]);
$todos = $turno === 'Todos';

cabecera('Ingresos del día', 'ingresos.php');
?>
<h1>Ingresos del <?= fecha_corta($fecha) ?><?= $todos ? '' : ' &middot; turno ' . e(mb_strtolower($turno)) ?></h1>
<?php filtro_fecha($fecha, $opciones, $turno); ?>
<?php if ($filas): ?>
<table class="lista">
  <thead><tr><th>Hora</th><th>Ingreso</th><?= $todos ? '<th>Turno</th>' : '' ?><th>Paciente</th><th>Alumno</th><th>Ubicación</th><th>Procedimiento</th><th>Validado por</th><th></th></tr></thead>
  <tbody>
  <?php foreach ($filas as $f): ?>
    <tr>
      <td><?= hora($f['hora_ingreso']) ?></td><td><?= e($f['codigo_ingreso']) ?></td>
      <?= $todos ? '<td>' . e($f['turno']) . '</td>' : '' ?>
      <td><?= e($f['paciente']) ?></td><td><?= e($f['alumno']) ?></td><td><?= e($f['ubicacion']) ?></td>
      <td><?php if ($f['tipo_procedimiento']): ?><?= e($f['tipo_procedimiento']) ?><br><small><?= e($f['doctor']) ?></small><?php else: ?>-<?php endif; ?></td>
      <td><?= e($f['validado_por']) ?></td>
      <td>
        <form method="post" onsubmit="return confirm('¿Anular el ingreso <?= e($f['codigo_ingreso']) ?>? Se eliminarán sus permisos y esterilizaciones.');">
          <input type="hidden" name="accion" value="anular">
          <input type="hidden" name="codigo" value="<?= e($f['codigo_ingreso']) ?>">
          <input type="hidden" name="fecha" value="<?= e($fecha) ?>">
          <input type="hidden" name="turno" value="<?= e($turno) ?>">
          <button class="boton chico peligro">Anular</button>
        </form>
      </td>
    </tr>
  <?php endforeach; ?>
  </tbody>
</table>
<p class="nota"><?= count($filas) ?> ingresos.</p>
<?php else: ?>
<p class="vacio">No hay ingresos registrados para el <?= fecha_corta($fecha) ?> en el turno <?= e(mb_strtolower($turno)) ?>.
  Los datos de ejemplo son del 19/10/2026 al 24/10/2026; pruebe una de esas fechas con el turno Todos.</p>
<?php endif; ?>
<?php pie();

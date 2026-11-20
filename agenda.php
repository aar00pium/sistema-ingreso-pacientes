<?php
/**
 * Agenda de una fecha: citas atendidas ese día (con su hora de ingreso) y citas
 * pendientes del mismo día de la semana. Procedimientos: fn_dia_semana, sp_agenda_fecha.
 */
require_once 'includes/funciones.php';
requiere_turno();

$texto = $_GET['fecha'] ?? '';
$fecha = (DateTime::createFromFormat('Y-m-d', $texto) && strlen($texto) === 10) ? $texto : date('Y-m-d');
$dia   = llamar_funcion('fn_dia_semana', [$fecha]);
$citas = llamar_procedimiento('sp_agenda_fecha', [$fecha]);
$pendientes = count(array_filter($citas, fn($c) => $c['estado'] === 'Pendiente'));

cabecera('Agenda del día', 'agenda.php');
?>
<h1>Agenda del <?= e(mb_strtolower($dia)) ?> <?= fecha_corta($fecha) ?></h1>
<?php filtro_fecha($fecha); ?>
<?php if ($citas): ?>
<table class="lista">
  <thead><tr><th>Bloque</th><th>Cita</th><th>DNI</th><th>Paciente</th><th>Condición</th><th>Sillón</th><th>Piso</th><th>Estado</th></tr></thead>
  <tbody>
  <?php foreach ($citas as $c): ?>
    <tr>
      <td><?= e($c['bloque_horario']) ?></td><td><?= e($c['codigo_programacion']) ?></td>
      <td><?= e($c['dni']) ?></td><td><?= e($c['paciente']) ?></td><td><?= e($c['condicion']) ?></td>
      <td><?= e($c['codigo_sillon'] ?? 'Sala') ?></td><td><?= e($c['piso'] ?? '-') ?></td>
      <td><?php if ($c['estado'] === 'Atendida'): ?><span class="etiqueta cerrado">Atendida <?= hora($c['hora_ingreso']) ?></span>
          <?php else: ?><span class="etiqueta abierto">Pendiente</span><?php endif; ?></td>
    </tr>
  <?php endforeach; ?>
  </tbody>
</table>
<p class="nota"><?= count($citas) ?> citas: <?= count($citas) - $pendientes ?> atendidas y <?= $pendientes ?> pendientes. Las citas sin sillón corresponden a procedimientos en sala.</p>
<?php else: ?>
<p class="vacio">No hay citas para el <?= e(mb_strtolower($dia)) ?> <?= fecha_corta($fecha) ?>.</p>
<?php endif; ?>
<?php pie();

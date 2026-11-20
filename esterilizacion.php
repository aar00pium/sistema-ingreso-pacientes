<?php
/**
 * Control de esterilización del instrumental.
 *
 * Registrar el inicio y el fin de cada ciclo y eliminar registros erróneos.
 * Procedimientos: sp_ingresos_combo, sp_esterilizacion_listar,
 * sp_esterilizacion_registrar_inicio, sp_esterilizacion_registrar_fin, sp_esterilizacion_eliminar.
 */
require_once 'includes/funciones.php';
requiere_turno();

/* ---------- Acciones ---------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $fecha  = campo('fecha');
    $accion = $_POST['accion'] ?? '';
    if ($accion === 'inicio') {
        ejecutar(fn() => llamar_procedimiento('sp_esterilizacion_registrar_inicio', [campo('ingreso'), campo('hora'), campo('asistencia')]),
                 'Inicio del ciclo registrado.');
    }
    if ($accion === 'fin') {
        ejecutar(fn() => llamar_procedimiento('sp_esterilizacion_registrar_fin', [campo('ingreso'), campo('inicio'), campo('hora')]),
                 'Fin del ciclo registrado.');
    }
    if ($accion === 'eliminar') {
        ejecutar(fn() => llamar_procedimiento('sp_esterilizacion_eliminar', [campo('ingreso'), campo('inicio')]), 'Registro eliminado.');
    }
    ir('esterilizacion.php?fecha=' . urlencode($fecha));
}

/* ---------- Datos ---------- */
$fecha    = leer_fecha();
$ingresos = llamar_procedimiento('sp_ingresos_combo', [$fecha]);
foreach ($ingresos as &$i) {
    $i['texto'] = hora($i['hora_ingreso']) . ' | ' . $i['alumno'] . ' | ' . $i['codigo_ingreso'];
}
unset($i);
$ciclos   = llamar_procedimiento('sp_esterilizacion_listar', [$fecha]);
$en_curso = count(array_filter($ciclos, fn($c) => (int)$c['en_curso'] === 1));

cabecera('Esterilización', 'esterilizacion.php');
?>
<h1>Esterilización del <?= fecha_corta($fecha) ?></h1>
<?php filtro_fecha($fecha); ?>

<div class="panel">
  <h2>Registrar inicio de ciclo</h2>
  <?php if (!$ingresos): ?>
    <p class="vacio">No hay ingresos en esta fecha.</p>
  <?php else: ?>
  <form method="post">
    <input type="hidden" name="accion" value="inicio">
    <input type="hidden" name="fecha" value="<?= e($fecha) ?>">
    <div class="form-grid">
      <label class="ancho">Alumno (ingreso) <select name="ingreso" required><?= opciones($ingresos, 'codigo_ingreso', 'texto', null, 'Seleccione...') ?></select></label>
      <label>Hora de inicio <input type="time" name="hora" value="<?= date('H:i') ?>" required></label>
      <label>Asistencia <select name="asistencia"><?= opciones_lista(['Asistió', 'No asistió']) ?></select></label>
    </div>
    <div class="botones"><button class="boton">Registrar inicio</button></div>
  </form>
  <?php endif; ?>
</div>

<h2>Ciclos del día <small class="nota">(<?= $en_curso ?> en curso)</small></h2>
<?php if ($ciclos): ?>
<table class="lista">
  <thead><tr><th>Alumno</th><th>Asistencia</th><th>Inicio</th><th>Fin</th><th>Duración</th><th>Acciones</th></tr></thead>
  <tbody>
  <?php foreach ($ciclos as $c): ?>
    <tr>
      <td><?= e($c['alumno']) ?></td>
      <td><span class="etiqueta <?= $c['asistencia'] === 'Asistió' ? 'cerrado' : 'falta' ?>"><?= e($c['asistencia']) ?></span></td>
      <td><?= hora($c['hora_inicio']) ?></td>
      <td><?php if ($c['hora_fin']): ?><?= hora($c['hora_fin']) ?>
          <?php elseif ((int)$c['en_curso'] === 1): ?><span class="etiqueta abierto">En curso</span>
          <?php else: ?>-<?php endif; ?></td>
      <td><?= $c['duracion'] ? hora($c['duracion']) : '-' ?></td>
      <td class="acciones">
        <?php if ((int)$c['en_curso'] === 1): ?>
        <form method="post">
          <input type="hidden" name="accion" value="fin">
          <input type="hidden" name="fecha" value="<?= e($fecha) ?>">
          <input type="hidden" name="ingreso" value="<?= e($c['codigo_ingreso']) ?>">
          <input type="hidden" name="inicio" value="<?= e($c['hora_inicio']) ?>">
          <input type="time" name="hora" value="<?= date('H:i') ?>" required>
          <button class="boton chico">Registrar fin</button>
        </form>
        <?php endif; ?>
        <form method="post" onsubmit="return confirm('¿Eliminar este registro?');">
          <input type="hidden" name="accion" value="eliminar">
          <input type="hidden" name="fecha" value="<?= e($fecha) ?>">
          <input type="hidden" name="ingreso" value="<?= e($c['codigo_ingreso']) ?>">
          <input type="hidden" name="inicio" value="<?= e($c['hora_inicio']) ?>">
          <button class="boton chico peligro">Eliminar</button>
        </form>
      </td>
    </tr>
  <?php endforeach; ?>
  </tbody>
</table>
<?php else: ?>
<p class="vacio">No hay ciclos de esterilización en esta fecha.</p>
<?php endif; ?>
<?php pie();

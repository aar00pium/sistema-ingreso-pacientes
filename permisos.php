<?php
/**
 * Permisos de salida de los alumnos durante una atención.
 *
 * Registrar salida y retorno, y eliminar registros erróneos.
 * Procedimientos: sp_ingresos_combo, sp_permiso_listar, sp_permiso_registrar_salida,
 * sp_permiso_registrar_retorno, sp_permiso_eliminar.
 */
require_once 'includes/funciones.php';
requiere_turno();

/* ---------- Acciones ---------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $fecha  = campo('fecha');
    $accion = $_POST['accion'] ?? '';
    if ($accion === 'salida') {
        ejecutar(fn() => llamar_procedimiento('sp_permiso_registrar_salida', [campo('ingreso'), campo('hora'), campo('motivo')]),
                 'Salida registrada. El alumno figura fuera con permiso.');
    }
    if ($accion === 'retorno') {
        ejecutar(fn() => llamar_procedimiento('sp_permiso_registrar_retorno', [campo('ingreso'), campo('salida'), campo('hora')]),
                 'Retorno registrado.');
    }
    if ($accion === 'eliminar') {
        ejecutar(fn() => llamar_procedimiento('sp_permiso_eliminar', [campo('ingreso'), campo('salida')]), 'Permiso eliminado.');
    }
    ir('permisos.php?fecha=' . urlencode($fecha));
}

/* ---------- Datos ---------- */
$fecha    = leer_fecha();
$ingresos = llamar_procedimiento('sp_ingresos_combo', [$fecha]);
foreach ($ingresos as &$i) {
    $i['texto'] = hora($i['hora_ingreso']) . ' | ' . $i['alumno'] . ' | ' . $i['paciente'] . ' | ' . $i['codigo_ingreso'];
}
unset($i);
$permisos = llamar_procedimiento('sp_permiso_listar', [$fecha]);
$abiertos = count(array_filter($permisos, fn($p) => $p['hora_retorno'] === null));

cabecera('Permisos de salida', 'permisos.php');
?>
<h1>Permisos de salida del <?= fecha_corta($fecha) ?></h1>
<?php filtro_fecha($fecha); ?>

<div class="panel">
  <h2>Registrar salida</h2>
  <?php if (!$ingresos): ?>
    <p class="vacio">No hay ingresos en esta fecha.</p>
  <?php else: ?>
  <form method="post">
    <input type="hidden" name="accion" value="salida">
    <input type="hidden" name="fecha" value="<?= e($fecha) ?>">
    <div class="form-grid">
      <label class="ancho">Alumno (ingreso) <select name="ingreso" required><?= opciones($ingresos, 'codigo_ingreso', 'texto', null, 'Seleccione...') ?></select></label>
      <label>Hora de salida <input type="time" name="hora" value="<?= date('H:i') ?>" required></label>
      <label class="ancho">Motivo <input name="motivo" maxlength="50" placeholder="Ej. Compra de material" required></label>
    </div>
    <div class="botones"><button class="boton">Registrar salida</button></div>
  </form>
  <?php endif; ?>
</div>

<h2>Permisos del día <small class="nota">(<?= $abiertos ?> alumnos fuera)</small></h2>
<?php if ($permisos): ?>
<table class="lista">
  <thead><tr><th>Alumno</th><th>Motivo</th><th>Salida</th><th>Retorno</th><th>Tiempo fuera</th><th>Acciones</th></tr></thead>
  <tbody>
  <?php foreach ($permisos as $p): ?>
    <tr>
      <td><?= e($p['alumno']) ?></td><td><?= e($p['motivo']) ?></td><td><?= hora($p['hora_salida']) ?></td>
      <td><?= $p['hora_retorno'] ? hora($p['hora_retorno']) : '<span class="etiqueta abierto">Fuera</span>' ?></td>
      <td><?= $p['tiempo_fuera'] ? hora($p['tiempo_fuera']) : '-' ?></td>
      <td class="acciones">
        <?php if ($p['hora_retorno'] === null): ?>
        <form method="post">
          <input type="hidden" name="accion" value="retorno">
          <input type="hidden" name="fecha" value="<?= e($fecha) ?>">
          <input type="hidden" name="ingreso" value="<?= e($p['codigo_ingreso']) ?>">
          <input type="hidden" name="salida" value="<?= e($p['hora_salida']) ?>">
          <input type="time" name="hora" value="<?= date('H:i') ?>" required>
          <button class="boton chico">Registrar retorno</button>
        </form>
        <?php endif; ?>
        <form method="post" onsubmit="return confirm('¿Eliminar este permiso?');">
          <input type="hidden" name="accion" value="eliminar">
          <input type="hidden" name="fecha" value="<?= e($fecha) ?>">
          <input type="hidden" name="ingreso" value="<?= e($p['codigo_ingreso']) ?>">
          <input type="hidden" name="salida" value="<?= e($p['hora_salida']) ?>">
          <button class="boton chico peligro">Eliminar</button>
        </form>
      </td>
    </tr>
  <?php endforeach; ?>
  </tbody>
</table>
<?php else: ?>
<p class="vacio">No hay permisos registrados en esta fecha.</p>
<?php endif; ?>
<?php pie();

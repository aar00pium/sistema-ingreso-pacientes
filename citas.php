<?php
/**
 * Mantenimiento de citas (programación).
 *
 * Programar, modificar, marcar inasistencia, eliminar (borrado lógico) y restaurar
 * citas. El procedimiento impide cruzar dos citas pendientes en el mismo sillón.
 * Procedimientos: sp_agenda_dia, sp_cita_obtener, sp_cita_insertar, sp_cita_actualizar,
 * sp_cita_marcar_asistencia, sp_cita_eliminar, sp_cita_restaurar, sp_cita_listar_eliminadas.
 */
require_once 'includes/funciones.php';
requiere_turno();

/* ---------- Acciones ---------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $accion = $_POST['accion'] ?? '';
    $codigo = campo('codigo');
    $dia    = campo('dia') ?: 'Lunes';
    if ($accion === 'guardar') {
        $bloque = campo('inicio') . '-' . campo('fin');
        $datos  = [$dia, $bloque, campo('dni'), campo('sillon')];
        if ($codigo !== '') {
            ejecutar(fn() => llamar_procedimiento('sp_cita_actualizar', array_merge([$codigo], $datos)), 'Cita actualizada.');
        } else {
            ejecutar(function () use ($datos, $dia) {
                $r = llamar_procedimiento('sp_cita_insertar', $datos);
                avisar('ok', 'Cita ' . $r[0]['codigo_programacion'] . ' programada para el ' . mb_strtolower($dia) . '.');
            }, '');
        }
        ir('citas.php?dia=' . urlencode($dia));
    }
    if ($accion === 'no_asistio' || $accion === 'pendiente') {
        $valor = $accion === 'no_asistio' ? 'No asistió' : null;
        ejecutar(fn() => llamar_procedimiento('sp_cita_marcar_asistencia', [$codigo, $valor]), 'Asistencia actualizada.');
        ir('citas.php?dia=' . urlencode($dia));
    }
    if ($accion === 'eliminar') {
        ejecutar(fn() => llamar_procedimiento('sp_cita_eliminar', [$codigo]),
                 'Cita eliminada (borrado lógico). Puede restaurarla desde la lista de citas eliminadas.');
        ir('citas.php?dia=' . urlencode($dia));
    }
    if ($accion === 'restaurar') {
        ejecutar(fn() => llamar_procedimiento('sp_cita_restaurar', [$codigo]), 'Cita restaurada.');
        ir('citas.php?dia=' . urlencode($dia));
    }
}

/* ---------- Datos ---------- */
$dia = in_array($_GET['dia'] ?? '', DIAS, true) ? $_GET['dia'] : 'Lunes';
$todas     = !empty($_GET['todas']);
$citas     = llamar_procedimiento('sp_agenda_dia', [$dia]);
if (!$todas) {                                   // por defecto solo las pendientes
    $citas = array_values(array_filter($citas, fn($c) => $c['asistencia'] === null));
}
$eliminadas = llamar_procedimiento('sp_cita_listar_eliminadas', [$dia]);
$pacientes = llamar_procedimiento('sp_paciente_listar', ['', 0]);
$sillones  = llamar_procedimiento('sp_listar_sillones');
foreach ($sillones as &$s) { $s['texto'] = $s['codigo_sillon'] . ' (piso ' . $s['piso'] . ')'; }
unset($s);
foreach ($pacientes as &$p) { $p['texto'] = $p['nombre'] . ' - ' . $p['dni']; }
unset($p);

$editar = null;
if (!empty($_GET['editar'])) {
    $editar = llamar_procedimiento('sp_cita_obtener', [$_GET['editar']])[0] ?? null;
}
$f = $editar
    ? ['codigo' => $editar['codigo_programacion'], 'dia' => $editar['dia_semana'],
       'inicio' => substr($editar['bloque_horario'], 0, 5), 'fin' => substr($editar['bloque_horario'], 6, 5),
       'dni' => $editar['dni'], 'sillon' => $editar['codigo_sillon']]
    : ['codigo' => '', 'dia' => $dia, 'inicio' => '08:00', 'fin' => '10:00', 'dni' => '', 'sillon' => ''];

cabecera('Citas', 'citas.php');
?>
<h1>Citas programadas</h1>

<div class="panel">
  <h2><?= $editar ? 'Modificar cita ' . e($f['codigo']) : 'Nueva cita' ?></h2>
  <?php if ($editar && $editar['tiene_ingreso']): ?>
    <div class="mensaje error">Esta cita ya tiene un ingreso registrado y no se puede modificar.</div>
  <?php endif; ?>
  <form method="post">
    <input type="hidden" name="accion" value="guardar">
    <input type="hidden" name="codigo" value="<?= e($f['codigo']) ?>">
    <div class="form-grid">
      <label>Día <select name="dia"><?= opciones_lista(DIAS, $f['dia']) ?></select></label>
      <label>Hora de inicio <input type="time" name="inicio" value="<?= e($f['inicio']) ?>" required></label>
      <label>Hora de fin <input type="time" name="fin" value="<?= e($f['fin']) ?>" required></label>
      <label class="ancho">Paciente
        <select name="dni" required><?= opciones($pacientes, 'dni', 'texto', $f['dni'], 'Seleccione...') ?></select>
      </label>
      <label>Sillón
        <select name="sillon"><?= opciones($sillones, 'codigo_sillon', 'texto', $f['sillon'], 'Sin sillón (sala)') ?></select>
      </label>
    </div>
    <p class="ayuda">Las citas sin sillón son para procedimientos en sala (cirugía o radiología). El sistema no permite dos citas en el mismo sillón con horarios que se cruzan.</p>
    <div class="botones">
      <button class="boton"><?= $editar ? 'Guardar cambios' : 'Programar cita' ?></button>
      <?php if ($editar): ?><a class="boton claro" href="citas.php?dia=<?= urlencode($f['dia']) ?>">Cancelar</a><?php endif; ?>
    </div>
  </form>
</div>

<form class="filtro" method="get">
  <label>Día <select name="dia"><?= opciones_lista(DIAS, $dia) ?></select></label>
  <label>Mostrar <select name="todas"><option value="">Solo pendientes</option><option value="1" <?= $todas ? 'selected' : '' ?>>Todas (incluye atendidas e inasistencias)</option></select></label>
  <button class="boton">Ver</button>
</form>

<?php if ($citas): ?>
<table class="lista">
  <thead><tr><th>Bloque</th><th>Cita</th><th>Paciente</th><th>Sillón</th><th>Asistencia</th><th>Acciones</th></tr></thead>
  <tbody>
  <?php foreach ($citas as $c): ?>
    <tr>
      <td><?= e($c['bloque_horario']) ?></td><td><?= e($c['codigo_programacion']) ?></td>
      <td><?= e($c['paciente']) ?></td><td><?= e($c['codigo_sillon'] ?? 'Sala') ?></td>
      <td>
        <?php if ($c['asistencia'] === 'Asistió'): ?><span class="etiqueta cerrado">Asistió</span>
        <?php elseif ($c['asistencia'] === 'No asistió'): ?><span class="etiqueta falta">No asistió</span>
        <?php else: ?><span class="etiqueta abierto">Pendiente</span><?php endif; ?>
      </td>
      <td class="acciones">
        <a class="boton chico claro" href="citas.php?dia=<?= urlencode($dia) ?>&editar=<?= urlencode($c['codigo_programacion']) ?>">Editar</a>
        <form method="post">
          <input type="hidden" name="codigo" value="<?= e($c['codigo_programacion']) ?>">
          <input type="hidden" name="dia" value="<?= e($dia) ?>">
          <?php if ($c['asistencia'] === null): ?>
            <button class="boton chico claro" name="accion" value="no_asistio">No asistió</button>
          <?php elseif ($c['asistencia'] === 'No asistió'): ?>
            <button class="boton chico claro" name="accion" value="pendiente">Volver a pendiente</button>
          <?php endif; ?>
        </form>
        <form method="post" onsubmit="return confirm('¿Eliminar la cita <?= e($c['codigo_programacion']) ?>?');">
          <input type="hidden" name="codigo" value="<?= e($c['codigo_programacion']) ?>">
          <input type="hidden" name="dia" value="<?= e($dia) ?>">
          <button class="boton chico peligro" name="accion" value="eliminar">Eliminar</button>
        </form>
      </td>
    </tr>
  <?php endforeach; ?>
  </tbody>
</table>
<p class="nota"><?= count($citas) ?> citas <?= $todas ? '' : 'pendientes ' ?>de los <?= e(mb_strtolower($dia)) ?>.</p>
<?php else: ?>
<p class="vacio">No hay citas <?= $todas ? '' : 'pendientes ' ?>para los <?= e(mb_strtolower($dia)) ?>.</p>
<?php endif; ?>

<?php if ($eliminadas): ?>
<h2>Citas eliminadas del <?= e(mb_strtolower($dia)) ?></h2>
<table class="lista">
  <thead><tr><th>Bloque</th><th>Cita</th><th>Paciente</th><th>Sillón</th><th>Acciones</th></tr></thead>
  <tbody>
  <?php foreach ($eliminadas as $c): ?>
    <tr>
      <td><?= e($c['bloque_horario']) ?></td><td><?= e($c['codigo_programacion']) ?></td>
      <td><?= e($c['paciente']) ?></td><td><?= e($c['codigo_sillon'] ?? 'Sala') ?></td>
      <td class="acciones">
        <form method="post">
          <input type="hidden" name="codigo" value="<?= e($c['codigo_programacion']) ?>">
          <input type="hidden" name="dia" value="<?= e($dia) ?>">
          <button class="boton chico" name="accion" value="restaurar">Restaurar</button>
        </form>
      </td>
    </tr>
  <?php endforeach; ?>
  </tbody>
</table>
<?php endif; ?>
<?php pie();

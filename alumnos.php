<?php
/**
 * Mantenimiento de alumnos (CRUD con borrado lógico).
 *
 * Registrar, buscar, modificar, desactivar y restaurar alumnos.
 * Procedimientos: sp_alumno_listar, sp_alumno_obtener, sp_alumno_insertar,
 * sp_alumno_actualizar, sp_alumno_eliminar (desactiva) y sp_alumno_restaurar.
 */
require_once 'includes/funciones.php';
requiere_turno();

/* ---------- Acciones: registrar, modificar, eliminar ---------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $accion = $_POST['accion'] ?? '';
    $codigo = campo('codigo_alumno');
    if ($accion === 'guardar') {
        $datos = [$codigo, strtoupper(campo('codigo_qr')), campo('nombre')];
        if (($_POST['modo'] ?? '') === 'editar') {
            ejecutar(fn() => llamar_procedimiento('sp_alumno_actualizar', $datos), 'Alumno actualizado.');
            ir('alumnos.php?editar=' . urlencode($codigo));
        }
        if (ejecutar(fn() => llamar_procedimiento('sp_alumno_insertar', $datos), 'Alumno registrado.')) {
            ir('alumnos.php');
        }
        $_SESSION['form'] = $_POST;
        ir('alumnos.php');
    }
    if ($accion === 'eliminar') {
        ejecutar(fn() => llamar_procedimiento('sp_alumno_eliminar', [$codigo]),
                 'Alumno desactivado. Su historial se conserva y puede restaurarse.');
        ir('alumnos.php');
    }
    if ($accion === 'restaurar') {
        ejecutar(fn() => llamar_procedimiento('sp_alumno_restaurar', [$codigo]), 'Alumno restaurado.');
        ir('alumnos.php?inactivos=1');
    }
}

/* ---------- Datos para la pantalla ---------- */
$buscar = trim($_GET['buscar'] ?? '');
$inactivos = !empty($_GET['inactivos']) ? 1 : 0;
$lista  = llamar_procedimiento('sp_alumno_listar', [$buscar, $inactivos]);
$editar = null;
if (!empty($_GET['editar'])) {
    $editar = llamar_procedimiento('sp_alumno_obtener', [$_GET['editar']])[0] ?? null;
}
$form = $editar ?? ($_SESSION['form'] ?? ['codigo_alumno' => '', 'codigo_qr' => '', 'nombre' => '']);
unset($_SESSION['form']);

cabecera('Alumnos', 'alumnos.php');
?>
<h1>Alumnos</h1>

<div class="panel">
  <h2><?= $editar ? 'Modificar alumno' : 'Nuevo alumno' ?></h2>
  <form method="post">
    <input type="hidden" name="accion" value="guardar">
    <input type="hidden" name="modo" value="<?= $editar ? 'editar' : 'nuevo' ?>">
    <div class="form-grid">
      <label>Código de alumno
        <input name="codigo_alumno" value="<?= e($form['codigo_alumno']) ?>" maxlength="10" required <?= $editar ? 'readonly' : '' ?>>
      </label>
      <label>Código QR
        <input name="codigo_qr" value="<?= e($form['codigo_qr']) ?>" maxlength="10" placeholder="QR00000000" required>
      </label>
      <label class="ancho">Apellidos y nombres
        <input name="nombre" value="<?= e($form['nombre']) ?>" maxlength="60" placeholder="Apellido Apellido, Nombre" required>
      </label>
    </div>
    <div class="botones">
      <button class="boton"><?= $editar ? 'Guardar cambios' : 'Registrar alumno' ?></button>
      <?php if ($editar): ?><a class="boton claro" href="alumnos.php">Cancelar</a><?php endif; ?>
    </div>
  </form>
</div>

<form class="filtro" method="get">
  <label>Buscar por código, QR o nombre <input name="buscar" value="<?= e($buscar) ?>"></label>
  <?php if ($inactivos): ?><input type="hidden" name="inactivos" value="1"><?php endif; ?>
  <button class="boton">Buscar</button>
  <?php if ($buscar !== ''): ?><a class="boton claro" href="alumnos.php<?= $inactivos ? '?inactivos=1' : '' ?>">Ver todos</a><?php endif; ?>
  <?php if ($inactivos): ?>
    <a class="boton claro" href="alumnos.php">Ver activos</a>
  <?php else: ?>
    <a class="boton claro" href="alumnos.php?inactivos=1">Ver desactivados</a>
  <?php endif; ?>
</form>
<?php if ($inactivos): ?><h2>Alumnos desactivados</h2><?php endif; ?>

<table class="lista">
  <thead><tr><th>Código</th><th>Código QR</th><th>Alumno</th><th class="num">Atenciones</th><th>Acciones</th></tr></thead>
  <tbody>
  <?php foreach ($lista as $a): ?>
    <tr>
      <td><?= e($a['codigo_alumno']) ?></td><td><?= e($a['codigo_qr']) ?></td><td><?= e($a['nombre']) ?></td>
      <td class="num"><?= e($a['atenciones']) ?></td>
      <td class="acciones">
        <?php if (!$inactivos): ?>
        <a class="boton chico claro" href="alumnos.php?editar=<?= urlencode($a['codigo_alumno']) ?>">Editar</a>
        <form method="post" onsubmit="return confirm('¿Desactivar al alumno <?= e($a['nombre']) ?>?');">
          <input type="hidden" name="accion" value="eliminar">
          <input type="hidden" name="codigo_alumno" value="<?= e($a['codigo_alumno']) ?>">
          <button class="boton chico peligro">Desactivar</button>
        </form>
        <?php else: ?>
        <form method="post">
          <input type="hidden" name="accion" value="restaurar">
          <input type="hidden" name="codigo_alumno" value="<?= e($a['codigo_alumno']) ?>">
          <button class="boton chico">Restaurar</button>
        </form>
        <?php endif; ?>
      </td>
    </tr>
  <?php endforeach; ?>
  </tbody>
</table>
<p class="nota"><?= count($lista) ?> alumnos<?= $inactivos ? ' desactivados' : ' activos' ?>.</p>
<?php pie();

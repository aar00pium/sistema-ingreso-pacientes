<?php
/**
 * Mantenimiento de pacientes (CRUD con borrado lógico).
 *
 * Registrar, buscar, modificar, desactivar y restaurar pacientes. No se puede
 * desactivar un paciente con citas pendientes.
 * Procedimientos: sp_paciente_listar, sp_paciente_obtener, sp_paciente_insertar,
 * sp_paciente_actualizar, sp_paciente_eliminar (desactiva) y sp_paciente_restaurar.
 */
require_once 'includes/funciones.php';
requiere_turno();

/* ---------- Acciones: registrar, modificar, eliminar ---------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $accion = $_POST['accion'] ?? '';
    $dni = campo('dni');
    if ($accion === 'guardar') {
        $datos = [$dni, campo('nombre'), campo('condicion')];
        if (($_POST['modo'] ?? '') === 'editar') {
            ejecutar(fn() => llamar_procedimiento('sp_paciente_actualizar', $datos), 'Paciente actualizado.');
            ir('pacientes.php?editar=' . urlencode($dni));
        }
        if (ejecutar(fn() => llamar_procedimiento('sp_paciente_insertar', $datos), 'Paciente registrado.')) {
            ir('pacientes.php');
        }
        $_SESSION['form'] = $_POST;          // conserva lo escrito si hubo error
        ir('pacientes.php');
    }
    if ($accion === 'eliminar') {
        ejecutar(fn() => llamar_procedimiento('sp_paciente_eliminar', [$dni]),
                 'Paciente desactivado. Su historial se conserva y puede restaurarse.');
        ir('pacientes.php');
    }
    if ($accion === 'restaurar') {
        ejecutar(fn() => llamar_procedimiento('sp_paciente_restaurar', [$dni]), 'Paciente restaurado.');
        ir('pacientes.php?inactivos=1');
    }
}

/* ---------- Datos para la pantalla ---------- */
$buscar = trim($_GET['buscar'] ?? '');
$inactivos = !empty($_GET['inactivos']) ? 1 : 0;
$lista  = llamar_procedimiento('sp_paciente_listar', [$buscar, $inactivos]);
$editar = null;
if (!empty($_GET['editar'])) {
    $editar = llamar_procedimiento('sp_paciente_obtener', [$_GET['editar']])[0] ?? null;
}
$form = $editar ?? ($_SESSION['form'] ?? ['dni' => '', 'nombre' => '', 'condicion' => 'Adulto']);
unset($_SESSION['form']);

cabecera('Pacientes', 'pacientes.php');
?>
<h1>Pacientes</h1>

<div class="panel">
  <h2><?= $editar ? 'Modificar paciente' : 'Nuevo paciente' ?></h2>
  <form method="post">
    <input type="hidden" name="accion" value="guardar">
    <input type="hidden" name="modo" value="<?= $editar ? 'editar' : 'nuevo' ?>">
    <div class="form-grid">
      <label>DNI
        <input name="dni" value="<?= e($form['dni']) ?>" maxlength="8" required <?= $editar ? 'readonly' : '' ?>>
      </label>
      <label class="ancho">Apellidos y nombres
        <input name="nombre" value="<?= e($form['nombre']) ?>" maxlength="60" placeholder="Apellido Apellido, Nombre" required>
      </label>
      <label>Condición
        <select name="condicion"><?= opciones_lista(CONDICIONES, $form['condicion']) ?></select>
      </label>
    </div>
    <div class="botones">
      <button class="boton"><?= $editar ? 'Guardar cambios' : 'Registrar paciente' ?></button>
      <?php if ($editar): ?><a class="boton claro" href="pacientes.php">Cancelar</a><?php endif; ?>
    </div>
  </form>
</div>

<form class="filtro" method="get">
  <label>Buscar por DNI o nombre <input name="buscar" value="<?= e($buscar) ?>"></label>
  <?php if ($inactivos): ?><input type="hidden" name="inactivos" value="1"><?php endif; ?>
  <button class="boton">Buscar</button>
  <?php if ($buscar !== ''): ?><a class="boton claro" href="pacientes.php<?= $inactivos ? '?inactivos=1' : '' ?>">Ver todos</a><?php endif; ?>
  <?php if ($inactivos): ?>
    <a class="boton claro" href="pacientes.php">Ver activos</a>
  <?php else: ?>
    <a class="boton claro" href="pacientes.php?inactivos=1">Ver desactivados</a>
  <?php endif; ?>
</form>
<?php if ($inactivos): ?><h2>Pacientes desactivados</h2><?php endif; ?>

<table class="lista">
  <thead><tr><th>DNI</th><th>Paciente</th><th>Condición</th><th class="num">Citas</th><th>Acciones</th></tr></thead>
  <tbody>
  <?php foreach ($lista as $p): ?>
    <tr>
      <td><?= e($p['dni']) ?></td><td><?= e($p['nombre']) ?></td><td><?= e($p['condicion']) ?></td>
      <td class="num"><?= e($p['citas']) ?></td>
      <td class="acciones">
        <?php if (!$inactivos): ?>
        <a class="boton chico claro" href="pacientes.php?editar=<?= urlencode($p['dni']) ?>">Editar</a>
        <form method="post" onsubmit="return confirm('¿Desactivar al paciente <?= e($p['nombre']) ?>?');">
          <input type="hidden" name="accion" value="eliminar">
          <input type="hidden" name="dni" value="<?= e($p['dni']) ?>">
          <button class="boton chico peligro">Desactivar</button>
        </form>
        <?php else: ?>
        <form method="post">
          <input type="hidden" name="accion" value="restaurar">
          <input type="hidden" name="dni" value="<?= e($p['dni']) ?>">
          <button class="boton chico">Restaurar</button>
        </form>
        <?php endif; ?>
      </td>
    </tr>
  <?php endforeach; ?>
  </tbody>
</table>
<p class="nota"><?= count($lista) ?> pacientes<?= $inactivos ? ' desactivados' : ' activos' ?>.</p>
<?php pie();

<?php
/**
 * Mantenimiento de catálogos: sillones, salas, personal de recepción y doctores.
 *
 * Una sola pantalla atiende los cuatro catálogos; la configuración de cada uno
 * (campos, columnas y procedimientos) está en el arreglo $CATALOGOS.
 * Operaciones: registrar, modificar, desactivar (borrado lógico) y restaurar.
 * Procedimientos: sp_<catalogo>_listar, _insertar, _actualizar, _cambiar_estado.
 */
require_once 'includes/funciones.php';
requiere_turno();

$CATALOGOS = [
    'sillon' => [
        'titulo' => 'Sillones', 'singular' => 'sillón',
        'campos' => [
            'codigo' => ['Código', 'text', 'maxlength="3" placeholder="A1"'],
            'piso'   => ['Piso', 'select', [1, 2, 3]],
        ],
        'columnas'   => ['codigo' => 'Sillón', 'piso' => 'Piso', 'citas' => 'Citas vigentes'],
        'desactivar' => 'Fuera de servicio',
        'ayuda'      => 'Un sillón fuera de servicio no aparece al programar citas ni en el mapa de ocupación.',
    ],
    'sala' => [
        'titulo' => 'Salas', 'singular' => 'sala',
        'campos' => [
            'codigo' => ['Código', 'number', 'min="1" max="99"'],
            'nombre' => ['Nombre de la sala', 'text', 'maxlength="30"'],
        ],
        'columnas'   => ['codigo' => 'Código', 'nombre' => 'Sala', 'atenciones' => 'Atenciones'],
        'desactivar' => 'Deshabilitar',
        'ayuda'      => 'Una sala deshabilitada no se puede elegir al registrar un procedimiento.',
    ],
    'personal' => [
        'titulo' => 'Personal de recepción', 'singular' => 'integrante del personal',
        'campos' => [
            'codigo' => ['Código', 'number', 'min="1" max="9999"'],
            'nombre' => ['Apellidos y nombres', 'text', 'maxlength="60" placeholder="Apellido Apellido, Nombre"'],
        ],
        'columnas'   => ['codigo' => 'Código', 'nombre' => 'Personal', 'ingresos_validados' => 'Ingresos validados'],
        'desactivar' => 'Desactivar',
        'ayuda'      => 'El personal desactivado ya no aparece en el inicio de turno.',
    ],
    'doctor' => [
        'titulo' => 'Doctores', 'singular' => 'doctor',
        'campos' => [
            'codigo' => ['Código', 'number', 'min="1" max="9999"'],
            'nombre' => ['Nombre', 'text', 'maxlength="60" placeholder="Dr. Apellido Apellido, Nombre"'],
        ],
        'columnas'   => ['codigo' => 'Código', 'nombre' => 'Doctor', 'supervisiones' => 'Supervisiones'],
        'desactivar' => 'Desactivar',
        'ayuda'      => 'Un doctor desactivado no se puede elegir como supervisor de un procedimiento.',
    ],
];

$t = $_GET['t'] ?? $_POST['t'] ?? 'sillon';
if (!isset($CATALOGOS[$t])) {
    $t = 'sillon';
}
$cfg    = $CATALOGOS[$t];
$pagina = 'catalogos.php?t=' . $t;

/* ---------- Acciones ---------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $accion = $_POST['accion'] ?? '';
    $codigo = campo('codigo');
    if ($accion === 'guardar') {
        $valores = [];
        foreach (array_keys($cfg['campos']) as $c) {
            $valores[] = campo($c);
        }
        if (($_POST['modo'] ?? '') === 'editar') {
            ejecutar(fn() => llamar_procedimiento("sp_{$t}_actualizar", $valores), ucfirst($cfg['singular']) . ' actualizado.');
        } else {
            ejecutar(fn() => llamar_procedimiento("sp_{$t}_insertar", $valores), ucfirst($cfg['singular']) . ' registrado.');
        }
        ir($pagina);
    }
    if ($accion === 'desactivar' || $accion === 'restaurar') {
        $activo = $accion === 'restaurar' ? 1 : 0;
        ejecutar(fn() => llamar_procedimiento("sp_{$t}_cambiar_estado", [$codigo, $activo]),
                 $activo ? 'Registro restaurado.' : 'Registro desactivado (borrado lógico).');
        ir($pagina . ($activo ? '&inactivos=1' : ''));
    }
}

/* ---------- Datos ---------- */
$inactivos = !empty($_GET['inactivos']) ? 1 : 0;
$lista  = llamar_procedimiento("sp_{$t}_listar", [$inactivos]);
$editar = null;
if (isset($_GET['editar'])) {
    foreach ($lista as $fila) {
        if ((string)$fila['codigo'] === (string)$_GET['editar']) {
            $editar = $fila;
        }
    }
}

cabecera($cfg['titulo'], $pagina);
?>
<h1><?= e($cfg['titulo']) ?></h1>

<div class="panel">
  <h2><?= $editar ? 'Modificar ' . e($cfg['singular']) : 'Nuevo ' . e($cfg['singular']) ?></h2>
  <form method="post">
    <input type="hidden" name="t" value="<?= e($t) ?>">
    <input type="hidden" name="accion" value="guardar">
    <input type="hidden" name="modo" value="<?= $editar ? 'editar' : 'nuevo' ?>">
    <div class="form-grid">
      <?php foreach ($cfg['campos'] as $nombre => [$etiqueta, $tipo, $extra]): ?>
        <label class="<?= $nombre === 'nombre' ? 'ancho' : '' ?>"><?= e($etiqueta) ?>
          <?php if ($tipo === 'select'): ?>
            <select name="<?= $nombre ?>"><?= opciones_lista($extra, $editar[$nombre] ?? null) ?></select>
          <?php else: ?>
            <input type="<?= $tipo ?>" name="<?= $nombre ?>" value="<?= e($editar[$nombre] ?? '') ?>" <?= $extra ?> required
                   <?= ($editar && $nombre === 'codigo') ? 'readonly' : '' ?>>
          <?php endif; ?>
        </label>
      <?php endforeach; ?>
    </div>
    <p class="ayuda"><?= e($cfg['ayuda']) ?></p>
    <div class="botones">
      <button class="boton"><?= $editar ? 'Guardar cambios' : 'Registrar' ?></button>
      <?php if ($editar): ?><a class="boton claro" href="<?= e($pagina) ?>">Cancelar</a><?php endif; ?>
    </div>
  </form>
</div>

<div class="filtro">
  <?php if ($inactivos): ?>
    <a class="boton claro" href="<?= e($pagina) ?>">Ver activos</a>
  <?php else: ?>
    <a class="boton claro" href="<?= e($pagina) ?>&amp;inactivos=1">Ver desactivados</a>
  <?php endif; ?>
</div>
<?php if ($inactivos): ?><h2>Registros desactivados</h2><?php endif; ?>

<?php if ($lista): ?>
<table class="lista">
  <thead><tr><?php foreach ($cfg['columnas'] as $titulo): ?><th><?= e($titulo) ?></th><?php endforeach; ?><th>Acciones</th></tr></thead>
  <tbody>
  <?php foreach ($lista as $fila): ?>
    <tr>
      <?php foreach (array_keys($cfg['columnas']) as $col): ?><td><?= e($fila[$col]) ?></td><?php endforeach; ?>
      <td class="acciones">
        <?php if (!$inactivos): ?>
          <a class="boton chico claro" href="<?= e($pagina) ?>&amp;editar=<?= urlencode($fila['codigo']) ?>">Editar</a>
          <form method="post" onsubmit="return confirm('¿Confirmar: <?= e($cfg['desactivar']) ?>?');">
            <input type="hidden" name="t" value="<?= e($t) ?>">
            <input type="hidden" name="accion" value="desactivar">
            <input type="hidden" name="codigo" value="<?= e($fila['codigo']) ?>">
            <button class="boton chico peligro"><?= e($cfg['desactivar']) ?></button>
          </form>
        <?php else: ?>
          <form method="post">
            <input type="hidden" name="t" value="<?= e($t) ?>">
            <input type="hidden" name="accion" value="restaurar">
            <input type="hidden" name="codigo" value="<?= e($fila['codigo']) ?>">
            <button class="boton chico">Restaurar</button>
          </form>
        <?php endif; ?>
      </td>
    </tr>
  <?php endforeach; ?>
  </tbody>
</table>
<p class="nota"><?= count($lista) ?> registros.</p>
<?php else: ?>
<p class="vacio">No hay registros <?= $inactivos ? 'desactivados' : '' ?>.</p>
<?php endif; ?>
<?php pie();

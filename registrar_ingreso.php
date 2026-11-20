<?php
/**
 * Registro del ingreso de un alumno con su paciente.
 *
 * Lista las citas pendientes del día de la semana de la fecha elegida y registra el
 * ingreso con el QR del alumno. El procedimiento valida la cita, el día, el alumno y
 * la sala; genera el código, calcula el turno y marca la cita como Asistió.
 * Procedimientos: sp_citas_pendientes, sp_listar_salas, sp_listar_doctores,
 * sp_ingreso_registrar, sp_ingresos_dia.
 */
require_once 'includes/funciones.php';
requiere_turno();

/* ---------- Registrar el ingreso ---------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $fecha = campo('fecha');
    $datos = [
        campo('cita'),
        strtoupper(campo('qr')),
        $_SESSION['personal']['codigo_personal'],     // quien valida es el personal del turno
        $fecha,
        campo('hora'),
        campo('procedimiento'),
        campo('sala') === '' ? null : (int)campo('sala'),
        campo('doctor') === '' ? null : (int)campo('doctor'),
    ];
    $ok = ejecutar(function () use ($datos) {
        $r = llamar_procedimiento('sp_ingreso_registrar', $datos);
        avisar('ok', 'Ingreso ' . $r[0]['codigo_ingreso'] . ' registrado. La cita quedó marcada como Asistió.');
    }, '');
    if (!$ok) {
        $_SESSION['form'] = $_POST;
    }
    ir('registrar_ingreso.php?fecha=' . urlencode($fecha));
}

/* ---------- Datos ---------- */
$texto = $_GET['fecha'] ?? '';
$fecha = (DateTime::createFromFormat('Y-m-d', $texto) && strlen($texto) === 10) ? $texto : date('Y-m-d');
$dia   = llamar_funcion('fn_dia_semana', [$fecha]);
$pendientes = llamar_procedimiento('sp_citas_pendientes', [$fecha]);
foreach ($pendientes as &$c) {
    $c['texto'] = $c['bloque_horario'] . ' | ' . $c['paciente'] . ' | ' . $c['ubicacion'] . ' | cita ' . $c['codigo_programacion'];
}
unset($c);
$salas    = llamar_procedimiento('sp_listar_salas');
$doctores = llamar_procedimiento('sp_listar_doctores');
$hoy      = llamar_procedimiento('sp_ingresos_dia', [$fecha, null]);
$f = $_SESSION['form'] ?? ['cita' => '', 'qr' => '', 'hora' => date('H:i'), 'procedimiento' => '', 'sala' => '', 'doctor' => ''];
unset($_SESSION['form']);

cabecera('Registrar ingreso', 'registrar_ingreso.php');
?>
<h1>Registrar ingreso del <?= e(mb_strtolower($dia)) ?> <?= fecha_corta($fecha) ?></h1>
<?php filtro_fecha($fecha); ?>

<div class="panel">
  <h2>Datos del ingreso</h2>
  <?php if (!$pendientes): ?>
    <p class="vacio">No hay citas pendientes para el <?= e(mb_strtolower($dia)) ?>. Programe una cita en el módulo Citas o elija otra fecha.</p>
  <?php else: ?>
  <form method="post">
    <input type="hidden" name="fecha" value="<?= e($fecha) ?>">
    <div class="form-grid">
      <label class="ancho">Cita del paciente
        <select name="cita" required><?= opciones($pendientes, 'codigo_programacion', 'texto', $f['cita'], 'Seleccione la cita...') ?></select>
      </label>
      <label>Código QR del alumno
        <input name="qr" value="<?= e($f['qr']) ?>" placeholder="QR00000000" required autofocus>
      </label>
      <label>Hora de ingreso
        <input type="time" name="hora" value="<?= e($f['hora']) ?>" required>
        <span class="ayuda">Antes de las 13:00 es turno mañana.</span>
      </label>
    </div>
    <h2 style="margin-top:18px">Solo para citas en sala</h2>
    <div class="form-grid">
      <label class="ancho">Tipo de procedimiento
        <input name="procedimiento" value="<?= e($f['procedimiento']) ?>" maxlength="30" placeholder="Ej. Exodoncia">
      </label>
      <label>Sala <select name="sala"><?= opciones($salas, 'codigo_sala', 'nombre_sala', $f['sala'], 'Sin sala') ?></select></label>
      <label>Doctor supervisor <select name="doctor"><?= opciones($doctores, 'codigo_doctor', 'nombre', $f['doctor'], 'Sin doctor') ?></select></label>
    </div>
    <p class="ayuda">Valida: <?= e($_SESSION['personal']['nombre']) ?>. Al registrar, la cita se marca como Asistió.</p>
    <div class="botones"><button class="boton">Registrar ingreso</button></div>
  </form>
  <?php endif; ?>
</div>

<h2>Ingresos registrados el <?= fecha_corta($fecha) ?></h2>
<?php if ($hoy): ?>
<table class="lista">
  <thead><tr><th>Hora</th><th>Ingreso</th><th>Turno</th><th>Paciente</th><th>Alumno</th><th>Ubicación</th><th>Validado por</th></tr></thead>
  <tbody>
  <?php foreach ($hoy as $i): ?>
    <tr><td><?= hora($i['hora_ingreso']) ?></td><td><?= e($i['codigo_ingreso']) ?></td><td><?= e($i['turno']) ?></td>
        <td><?= e($i['paciente']) ?></td><td><?= e($i['alumno']) ?></td><td><?= e($i['ubicacion']) ?></td><td><?= e($i['validado_por']) ?></td></tr>
  <?php endforeach; ?>
  </tbody>
</table>
<?php else: ?>
<p class="vacio">Todavía no hay ingresos en esta fecha.</p>
<?php endif; ?>
<?php pie();

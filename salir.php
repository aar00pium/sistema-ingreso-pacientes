<?php
/**
 * Cierre del turno: elimina la sesión y vuelve al inicio de turno.
 */
session_start();
session_destroy();
header('Location: turno.php');

# Sistema de Ingreso de Pacientes - Centro Odontológico

Aplicativo web cliente de la base de datos `bd_ingreso_odontologico`, desarrollado para el curso
**Gestión de Datos e Información** (proyecto de laboratorio, entrega 5).

El aplicativo controla el ingreso de pacientes y alumnos al Centro Odontológico: citas, ingresos
validados con el código QR del alumno, permisos de salida, ciclos de esterilización, mantenimiento
de catálogos y reportes.

## Tecnología

| Componente | Herramienta |
|---|---|
| Lenguaje | PHP 8 sin frameworks |
| Acceso a datos | PDO (extensión `pdo_mysql`) con sentencias preparadas |
| Base de datos | MySQL 8.0 (InnoDB, utf8mb4) |
| Servidor web | Apache (XAMPP) o servidor integrado de PHP |
| Interfaz | HTML5 y CSS3 |

**Regla de diseño:** el código PHP no contiene consultas SQL. Toda la lógica de datos está en la
base como 7 funciones y 75 procedimientos almacenados, y 32 triggers. El usuario de MySQL del
aplicativo (`app_ingreso`) solo tiene permiso `EXECUTE`.

## Instalación

1. En MySQL Workbench, con `root`, ejecutar **`sql/script_completo_bd.sql`** (crea la base, los
   objetos, los datos de prueba y el usuario del aplicativo).
2. Copiar esta carpeta a `C:\xampp\htdocs\Aplicativo_GDI`.
3. Iniciar **solo Apache** en XAMPP (no el MySQL de XAMPP, porque usa el mismo puerto 3306).
4. Abrir `http://localhost/Aplicativo_GDI/`.

Sin Apache: ejecutar `iniciar_aplicativo.bat`, que levanta el servidor integrado de PHP en
`http://localhost:8000` y abre el navegador.

Los datos de conexión están en `config.php`. La prueba de conexión está en
`prueba_conexion.php` (navegador) y `prueba_conexion_cli.php` (consola).

## Estructura

```
config.php                 datos de conexión (host, puerto, nombre de la base, usuario)
includes/conexion.php      conexión PDO, llamada a funciones y procedimientos, traducción de errores
includes/funciones.php     sesión, menú, plantilla común y funciones de formato
index.php                  inicio: resumen del día y ocupación de sillones
turno.php, salir.php       inicio y cierre de turno del personal de recepción
agenda.php                 agenda de una fecha
qr.php                     validación del alumno por código QR
registrar_ingreso.php      registro del ingreso de una cita
ingresos.php               ingresos por fecha y turno; anulación
permisos.php               permisos de salida (salida y retorno)
esterilizacion.php         ciclos de esterilización (inicio y fin)
citas.php                  CRUD de citas con borrado lógico
pacientes.php, alumnos.php CRUD de pacientes y alumnos con borrado lógico
catalogos.php              CRUD de sillones, salas, personal y doctores
reportes.php               13 reportes (impresión y exportación CSV)
prueba_conexion*.php       prueba de conexión web y por consola
css/estilos.css            estilos
sql/                       scripts de la base de datos (ver sql/script_completo_bd.sql)
herramientas/gen_datos.py  generador de los datos ampliados (script 14)
```

## Scripts SQL

| Script | Contenido |
|---|---|
| 01 | Base, 10 tablas, restricciones, índices y triggers de validación |
| 11 | Columna `activo` (borrado lógico) y tabla `auditoria` |
| 02 | Datos de ejemplo (semana del 19 al 24/10/2026) |
| 14 | Datos ampliados (26/10 al 21/11/2026) |
| 09 | Funciones y procedimientos de consulta |
| 10 | Procedimientos de registro (CRUD) |
| 12 | Sesión, catálogos y 13 reportes |
| 13 | Triggers de auditoría y de bloqueo del borrado físico |
| 08 | Usuario `app_ingreso` con permiso `EXECUTE` |

`script_completo_bd.sql` reúne todos en ese orden.

## Normas de codificación

PSR-1 y PSR-12 (estilo de PHP), nombres en español y en minúsculas con guion bajo para objetos SQL
(`sp_`, `fn_`, `trg_`, `pk_`, `fk_`, `uq_`, `ck_`, `ix_`), comentarios de cabecera en cada archivo.

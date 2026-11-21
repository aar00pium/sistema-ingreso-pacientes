# Sistema de Ingreso de Pacientes - Centro Odontológico UCSM

Aplicativo web cliente de la base de datos `bd_ingreso_odontologico`, desarrollado para el curso
**Gestión de Datos e Información** (UCSM, Escuela Profesional de Ingeniería de Sistemas).

Controla el ingreso de pacientes y alumnos al Centro Odontológico: citas, ingresos validados con el
código QR del alumno, permisos de salida, ciclos de esterilización, mantenimiento de catálogos,
reportes y auditoría.

Integrantes: Flor Vilca, Guillermo Aaron Kenan; Quispe Cutipa, Marcelo Omar; Rojas Luna, Kevin Jostin;
Villacorta Gamarra, Hilary Rose.

## Contenido del archivo

| Contenido | Ubicación |
|---|---|
| Código fuente del frontend | `css/estilos.css` (estilos), plantilla HTML común en `includes/funciones.php` (`cabecera()` y `pie()`) y el HTML de cada pantalla `*.php` de la raíz |
| Código fuente del backend | `includes/conexion.php` (conexión PDO, llamada a rutinas, traducción de errores), `includes/funciones.php` (sesión, menú, formularios, mensajes) y la lógica de cada pantalla `*.php` |
| Archivos de configuración | `config.php` (servidor, puerto, base, usuario y contraseña de MySQL), `.gitignore`, `iniciar_aplicativo.bat` |
| Librerías o dependencias | `composer.json` (PHP 8 y extensiones `pdo`, `pdo_mysql`, `mbstring`). No usa librerías externas ni frameworks, así que no hay carpeta `vendor` |
| Script de creación de la base | `sql/1_creacion/` |
| Script de inserción de datos de prueba | `sql/2_datos_prueba/` |
| Procedimientos, funciones y triggers | `sql/3_funciones_procedimientos_triggers/` |
| Usuario de la base para el aplicativo | `sql/4_usuario_aplicativo/` |
| Script completo (todo lo anterior en orden) | `sql/script_completo_bd.sql` |
| Credenciales de prueba | `CREDENCIALES.md` |
| Generador de los datos de prueba | `herramientas/gen_datos.py` |

## Tecnología

| Componente | Herramienta |
|---|---|
| Lenguaje | PHP 8 sin frameworks |
| Acceso a datos | PDO (`pdo_mysql`) con sentencias preparadas |
| Base de datos | MySQL 8.0 (InnoDB, utf8mb4) |
| Servidor web | Apache (XAMPP) o servidor integrado de PHP |
| Interfaz | HTML5 y CSS3 |

**Regla de diseño:** el código PHP no contiene consultas SQL. Toda la lógica de datos está en la
base: 7 funciones, 75 procedimientos almacenados y 32 triggers. El usuario de MySQL del aplicativo
(`app_ingreso`) solo tiene permiso `EXECUTE`.

## Instalación

1. En MySQL Workbench, con `root`, abrir y ejecutar **`sql/script_completo_bd.sql`**. Crea la base,
   los objetos, los datos de prueba y el usuario del aplicativo.
2. Copiar esta carpeta a `C:\xampp\htdocs\Aplicativo_GDI`.
3. Iniciar **solo Apache** en XAMPP (no el MySQL de XAMPP, porque usa el mismo puerto 3306).
4. Abrir `http://localhost/Aplicativo_GDI/`.

Sin Apache: ejecutar `iniciar_aplicativo.bat`, que levanta el servidor integrado de PHP en
`http://localhost:8000` y abre el navegador.

Si MySQL usa otra contraseña o puerto, se cambian en `config.php`. La prueba de conexión está en
`prueba_conexion.php` (navegador) y `prueba_conexion_cli.php` (consola).

## Estructura

```
config.php                     configuración de la conexión
composer.json                  dependencias (PHP 8 y extensiones)
CREDENCIALES.md                credenciales y datos de prueba
iniciar_aplicativo.bat         ejecución sin Apache (servidor integrado de PHP)
includes/
  conexion.php                 backend: conexión PDO y llamada a funciones y procedimientos
  funciones.php                backend y plantilla: sesión, menú, cabecera, pie y formularios
css/
  estilos.css                  frontend: estilos de todas las pantallas
index.php                      inicio: resumen del día y ocupación de sillones
turno.php, salir.php           inicio y cierre de turno
agenda.php                     agenda de una fecha
qr.php                         validación del alumno por código QR
registrar_ingreso.php          registro del ingreso de una cita
ingresos.php                   ingresos por fecha y turno; anulación
permisos.php                   permisos de salida (salida y retorno)
esterilizacion.php             ciclos de esterilización (inicio y fin)
citas.php                      citas con borrado lógico y restauración
pacientes.php, alumnos.php     pacientes y alumnos con borrado lógico y restauración
catalogos.php                  sillones, salas, personal y doctores
reportes.php                   13 reportes (impresión y exportación CSV)
prueba_conexion.php            prueba de conexión en el navegador
prueba_conexion_cli.php        prueba de conexión por consola
sql/
  1_creacion/                  01 base, tablas, restricciones e índices; 11 borrado lógico y auditoría
  2_datos_prueba/              02 datos de ejemplo; 14 datos ampliados
  3_funciones_procedimientos_triggers/
                               09 consultas; 10 registro (CRUD); 12 catálogos y reportes; 13 triggers de auditoría
  4_usuario_aplicativo/        08 usuario app_ingreso con permiso EXECUTE
  script_completo_bd.sql       todos los scripts en orden de ejecución
herramientas/
  gen_datos.py                 generador de sql/2_datos_prueba/14_datos_ampliados.sql
```

## Orden de ejecución de los scripts

`script_completo_bd.sql` reúne los scripts en este orden: 01, 11, 02, 14, 09, 10, 12, 13 y 08.

## Normas de codificación

PSR-1 y PSR-12 (estilo de PHP), nombres en español y en minúsculas con guion bajo para objetos SQL
(`sp_`, `fn_`, `trg_`, `pk_`, `fk_`, `uq_`, `ck_`, `ix_`), comentarios de cabecera en cada archivo.

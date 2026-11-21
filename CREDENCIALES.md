# Credenciales y datos de prueba

## Acceso al sistema

El sistema no pide contraseña. En la pantalla de inicio de turno se elige a una de las seis personas
de recepción y el turno (Mañana o Tarde):

- Torres Lima, Juan
- Quispe Mamani, Rosa
- Flores Apaza, Carmen
- Huamán Ccori, Luis
- Valdivia Polar, Noemí
- Cárdenas Linares, Iván

## Base de datos

| Uso | Usuario | Contraseña |
|---|---|---|
| Instalar la base (ejecutar los scripts) | `root` | La definida al instalar MySQL 8.0 |
| Aplicativo (`config.php`) | `app_ingreso` | `Ingreso2026!` |

`app_ingreso` solo puede ejecutar funciones y procedimientos; un `SELECT` directo a las tablas
devuelve el error 1142.

## Datos para probar

| Dato | Valor |
|---|---|
| Fechas con ingresos | Del 19/10/2026 al 17/11/2026 (por ejemplo, el lunes 16/11/2026) |
| Citas pendientes | Miércoles, jueves, viernes y sábado (por ejemplo, el jueves 19/11/2026) |
| Código QR válido | `QR72623725` (Pérez Rojas, Ana) o `QR72623801` (Gutiérrez Lazo, Diego) |
| Código QR no válido | `QR00000000` |
| Paciente para el reporte R09 | DNI `71928723` (García López, Luis) |
| Rango para los reportes | Del 01/10/2026 al 30/11/2026 |

Para volver a los datos iniciales se ejecuta otra vez `sql/script_completo_bd.sql`.

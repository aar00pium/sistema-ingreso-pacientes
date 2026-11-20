"""Genera sql/14_datos_ampliados.sql: cuatro semanas más de operación del Centro
(26/10/2026 al 21/11/2026) sobre los datos de ejemplo del script 02.
Respeta todas las reglas de la base: formatos, días, bloques, una cita por ingreso,
sin cruces de sillón entre citas pendientes y horas coherentes."""
import random
from datetime import date, timedelta, datetime, time

random.seed(2026)
DIAS = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado']
BLOQUES = ['08:00-10:00', '10:00-12:00', '14:00-16:00', '16:00-18:00']
SILLONES = [f'{l}{n}' for l in 'ABCDEFGH' for n in (1, 2)]
HOY = date(2026, 11, 18)            # desde hoy las citas quedan pendientes

AP = ['Quispe', 'Mamani', 'Condori', 'Huamán', 'Flores', 'Apaza', 'Ccama', 'Choque', 'Rojas', 'Vargas',
      'Gutiérrez', 'Pérez', 'Torres', 'Chávez', 'Salazar', 'Paredes', 'Medina', 'Villanueva', 'Zúñiga', 'Cárdenas',
      'Delgado', 'Linares', 'Begazo', 'Valdivia', 'Zevallos', 'Bellido', 'Cuadros', 'Llerena', 'Rivera', 'Málaga',
      'Núñez', 'Herrera', 'Polar', 'Tejada', 'Benavente', 'Cornejo', 'Pacheco', 'Ticona', 'Larico', 'Mendoza']
NOM_M = ['Luis', 'Jorge', 'Carlos', 'José', 'Miguel', 'Raúl', 'Diego', 'Renzo', 'Marco', 'Andrés', 'Javier',
         'Fernando', 'Óscar', 'Iván', 'Sergio', 'Gonzalo', 'Rodrigo', 'Álvaro', 'Hugo', 'Martín']
NOM_F = ['María', 'Rosa', 'Lucía', 'Andrea', 'Sofía', 'Valeria', 'Camila', 'Daniela', 'Elena', 'Patricia',
         'Gabriela', 'Milagros', 'Ximena', 'Fiorella', 'Carmen', 'Diana', 'Karla', 'Noemí', 'Rocío', 'Julia']


def nombre(usados):
    while True:
        n = f"{random.choice(AP)} {random.choice(AP)}, {random.choice(NOM_M + NOM_F)}"
        if n not in usados and n.split()[0] != n.split()[1].rstrip(','):
            usados.add(n)
            return n


def q(v):
    if v is None:
        return 'NULL'
    if isinstance(v, int):
        return str(v)
    return "'" + str(v).replace("'", "''") + "'"


def hm(t):
    return t.strftime('%H:%M')


usados = set()
# ---- catálogos nuevos
personal = [(5, 'Valdivia Polar, Noemí'), (6, 'Cárdenas Linares, Iván')]
pac_existentes = ['79210345', '70981236', '77345120', '74480127', '75610982', '71928723', '70833192',
                  '76129034', '72015448', '73012457', '71102938', '72893014', '70456721', '73374581', '78450216']
pacientes = []
dnis = set()
for _ in range(85):
    while True:
        d = str(random.randint(40000000, 79999999))
        if d not in dnis:
            dnis.add(d)
            break
    r = random.random()
    cond = 'Adulto' if r < 0.74 else ('Niño' if r < 0.94 else 'Prenatal')
    pacientes.append((d, nombre(usados), cond))
alumnos = []
for i in range(30):
    cod = f"2022{100001 + i * 37:06d}"
    qr = f"QR{random.randint(10000000, 99999999)}"
    alumnos.append((cod, qr, nombre(usados)))
alumnos_codigos = ['2021248861', '2021248902', '2021249013', '2021249145', '2022110236',
                   '2022110378', '2022110419', '2022110582', '2022110647', '2022110793']
todos_alumnos = alumnos_codigos + [a[0] for a in alumnos]
todos_pacientes = [p[0] for p in pacientes] + pac_existentes

PROC_SALA = [('Exodoncia', 1, [1, 2, 5]), ('Cirugía de terceros molares', 1, [1, 5]),
             ('Radiografía panorámica', 2, [3, 4, 6]), ('Radiografía periapical', 2, [3, 4])]
MOTIVOS = ['Compra de material', 'Recoger radiografía', 'Consulta con docente', 'Laboratorio dental',
           'Trámite en caja', 'Recoger instrumental']

citas, ingresos, permisos, ester = [], [], [], []
cod_cita, cod_ing = 10001025, 50001020
pendientes_ocupados = {('Sábado', '16:00-18:00', 'E1')}       # cita 10001024 del script 02
dia = date(2026, 10, 26)
while dia <= date(2026, 11, 21):
    if dia.weekday() == 6:
        dia += timedelta(days=1)
        continue
    nombre_dia = DIAS[dia.weekday()]
    n_sillon = 6 if nombre_dia == 'Sábado' else 10
    slots = random.sample([(b, s) for b in BLOQUES for s in SILLONES], n_sillon)
    filas = [(b, s, None) for b, s in slots]
    if nombre_dia != 'Sábado':
        filas.append((random.choice(['08:00-10:00', '14:00-16:00']), None, random.choice(PROC_SALA)))
    for bloque, sillon, proc in sorted(filas, key=lambda f: f[0]):
        if dia >= HOY and sillon and (nombre_dia, bloque, sillon) in pendientes_ocupados:
            continue
        dni = random.choice(todos_pacientes)
        c = str(cod_cita); cod_cita += 1
        if dia >= HOY:
            citas.append((c, nombre_dia, bloque, None, dni, sillon))
            if sillon:
                pendientes_ocupados.add((nombre_dia, bloque, sillon))
            continue
        asistio = random.random() < 0.88
        citas.append((c, nombre_dia, bloque, 'Asistió' if asistio else 'No asistió', dni, sillon))
        if not asistio:
            continue
        ini = datetime.combine(dia, time(int(bloque[:2]), 0)) + timedelta(minutes=random.randint(0, 14))
        manana = ini.hour < 13
        per = random.choice([1, 2, 5] if manana else [3, 4, 6])
        ic = str(cod_ing); cod_ing += 1
        if proc:
            tipo, sala, docs = proc
            ingresos.append((ic, dia.isoformat(), hm(ini), 'Mañana' if manana else 'Tarde', tipo, c,
                             random.choice(todos_alumnos), per, sala, random.choice(docs)))
        else:
            ingresos.append((ic, dia.isoformat(), hm(ini), 'Mañana' if manana else 'Tarde', None, c,
                             random.choice(todos_alumnos), per, None, None))
        # permiso en ~30 % de las atenciones
        if random.random() < 0.30:
            sal = ini + timedelta(minutes=random.randint(25, 55))
            dur = random.randint(40, 70) if random.random() < 0.15 else random.randint(8, 30)
            permisos.append((ic, hm(sal), hm(sal + timedelta(minutes=dur)), random.choice(MOTIVOS)))
        # esterilización al terminar
        st = ini + timedelta(minutes=random.randint(95, 112))
        if random.random() < 0.06:
            ester.append((ic, hm(st), None, 'No asistió'))
        else:
            ester.append((ic, hm(st), hm(st + timedelta(minutes=random.randint(18, 35))), 'Asistió'))
    dia += timedelta(days=1)


def bloque_insert(tabla, cols, filas):
    out = [f"INSERT INTO {tabla} ({', '.join(cols)}) VALUES"]
    out.append(",\n".join("    (" + ", ".join(q(v) for v in f) + ")" for f in filas) + ";")
    return "\n".join(out)


sql = [f"""-- =====================================================================
--  Script 14 - Datos ampliados para pruebas del aplicativo
--  Base de datos: bd_ingreso_odontologico (MySQL 8.0)
--  Ejecutar después de 01, 11 y 02, y ANTES de los triggers (script 13).
--  Agrega cuatro semanas de operación (26/10/2026 al 21/11/2026):
--  hasta el 17/11 las citas ya ocurrieron; desde el 18/11 quedan pendientes.
--    personal: {len(personal)}   pacientes: {len(pacientes)}   alumnos: {len(alumnos)}
--    citas: {len(citas)}   ingresos: {len(ingresos)}   permisos: {len(permisos)}   esterilizaciones: {len(ester)}
--  Generado con gen_datos.py (semilla fija, siempre produce los mismos datos).
-- =====================================================================
SET NAMES utf8mb4;
USE bd_ingreso_odontologico;
START TRANSACTION;
""",
       bloque_insert('personal', ['codigo_personal', 'nombre'], personal),
       bloque_insert('paciente', ['dni', 'nombre', 'condicion'], pacientes),
       bloque_insert('alumno', ['codigo_alumno', 'codigo_qr', 'nombre'], alumnos),
       bloque_insert('programacion', ['codigo_programacion', 'dia_semana', 'bloque_horario', 'asistencia', 'dni', 'codigo_sillon'], citas),
       bloque_insert('ingreso', ['codigo_ingreso', 'fecha', 'hora_ingreso', 'turno', 'tipo_procedimiento', 'codigo_programacion',
                                 'codigo_alumno', 'codigo_personal', 'codigo_sala', 'codigo_doctor'], ingresos),
       bloque_insert('permiso', ['codigo_ingreso', 'hora_salida', 'hora_retorno', 'motivo'], permisos),
       bloque_insert('esterilizacion', ['codigo_ingreso', 'hora_inicio', 'hora_fin', 'asistencia'], ester),
       """COMMIT;

-- Conteo final por tabla
SELECT 'paciente' AS tabla, COUNT(*) AS filas FROM paciente
UNION ALL SELECT 'alumno', COUNT(*) FROM alumno
UNION ALL SELECT 'personal', COUNT(*) FROM personal
UNION ALL SELECT 'programacion', COUNT(*) FROM programacion
UNION ALL SELECT 'ingreso', COUNT(*) FROM ingreso
UNION ALL SELECT 'permiso', COUNT(*) FROM permiso
UNION ALL SELECT 'esterilizacion', COUNT(*) FROM esterilizacion;
"""]
open(__import__('os').path.join(__import__('os').path.dirname(__file__), '..', 'sql', '14_datos_ampliados.sql'), 'w', encoding='utf-8').write("\n\n".join(sql))
print(len(personal), len(pacientes), len(alumnos), len(citas), len(ingresos), len(permisos), len(ester))

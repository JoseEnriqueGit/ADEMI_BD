# Body actual QA02 para tracking del job

## Proposito

Usar esta carpeta como zona de trabajo para el `body` actual de
`PR.PR_PKG_REPRESTAMOS` tomado directamente desde QA02.

## Archivo esperado

El body actual fue colocado con este nombre:

- `body_actual_QA02.sql`

Sobre ese archivo ya se aplico el tracking persistente de
`P_Carga_Precalifica_Cancelado`.

El respaldo previo al tracking quedo en:

- `body_actual_QA02_BEFORE_TRACKING.sql`

## Donde se veran los resultados

Los resultados no dependen de `DBMS_OUTPUT`. El job dejara filas en:

- `PR.PR_JOB_PRECALIFICA_TRACK`

La tabla se crea con:

- `../06_CREATE_TRACKING_TABLE_JOB_PRECALIFICA_RD.sql`

Y se consulta con:

- `../08_CONSULTAR_TRACKING_JOB_PRECALIFICA_RD.sql`

Cada corrida tendra un `ID_EJECUCION`; cada proceso interno queda como un
`ID_PASO` con inicio, fin, duracion en segundos/minutos, estado y error si
aplica.

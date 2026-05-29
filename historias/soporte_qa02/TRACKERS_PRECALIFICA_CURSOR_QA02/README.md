# Trackers read-only de PR_PKG_REPRESTAMOS (Precalifica) en QA02

## Objetivo

Documentar la sesion en la que se construyeron trackers SQL read-only para
medir, en QA02, el embudo de descartes de los cursores de
`PR.PR_PKG_REPRESTAMOS` ligados a la cadena de precalificacion. El alcance es
diagnostico: contar candidatos antes / despues de cada filtro del cursor, sin
modificar logica de negocio, sin tocar la spec y sin recompilar el package.

Estos scripts son auxiliares de Toad. No se ejecutan desde el job ni desde
APEX, no escriben en tablas y no estan referenciados por
`PR.JOB_CARGA_PRECALIFICA_RD`.

## Archivos tocados o creados

Modificados:

- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/TRACKER_PRECALIFICA_REPRESTAMO_QA02.sql`
  Tracker pesado de `Precalifica_Represtamo` (cursor `CREDITOS_PROCESAR` + filtros posteriores del SP).
- `QA 02 REPRE.sql`
  Borrador local de Toad del usuario. No se reverte en esta sesion.

Nuevos (untracked):

- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/TRACKER_PRECALIFICA_VARIANTES_CURSOR_QA02.sql`
  Tracker liviano combinado para los cuatro cursores de variantes (un solo archivo, 4 bloques).
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/TRACKER_PRECALIFICA_REPRE_CANCELADO_CURSOR_QA02.sql`
  Tracker liviano aislado de `Precalifica_Repre_Cancelado`.
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/TRACKER_PRECALIFICA_REPRE_CANCELADO_HI_CURSOR_QA02.sql`
  Tracker liviano aislado de `Precalifica_Repre_Cancelado_hi`.
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/TRACKER_PRECALIFICA_REPRESTAMO_FIADORES_CURSOR_QA02.sql`
  Tracker liviano aislado de `Precalifica_Represtamo_fiadores`.
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/TRACKER_PRECALIFICA_REPRESTAMO_FIADORES_HI_CURSOR_QA02.sql`
  Tracker liviano aislado de `Precalifica_Represtamo_fiadores_hi`.

Otros archivos (`QA 02 REPRE Actual.sql`, `QA 02 REPRE BEFORE MEDICION TELEFONOS.sql`,
`QA 02 REPRE TEL BENCH.sql`) son del usuario y se preservan tal como estan.

## Explicacion de cada tracker

Todos los trackers siguen el mismo patron:

1. CTE `params` con los parametros via `PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO`.
2. CTEs `s00..sNN` que aplican cada predicado del cursor del SP en orden.
3. CTE `conteos` que cuenta filas por paso.
4. CTE `pasos` con la descripcion textual de cada filtro.
5. SELECT final que muestra `candidatos_antes`, `candidatos_pasan`, `candidatos_descartados`,
   y agrega una fila `99` con el corte por `LOTE_DE_CARAGA_REPRESTAMO`.

### TRACKER_PRECALIFICA_REPRESTAMO_QA02.sql (pesado)

- Cubre `Precalifica_Represtamo`, cursor `CREDITOS_PROCESAR` (sobre `PR_CREDITOS` + `PA_DETALLADO_DE08`).
- Reproduce los filtros del cursor + filtros posteriores del SP (mora, capital, estados).
- Valida que la fecha de corte usada sea la misma que toma el cursor:
  `MAX(PA.PA_DETALLADO_DE08.FECHA_CORTE) WHERE FUENTE = 'PR'`.
  Permite forzar una fecha historica (probada con `31/07/2025`) cambiando
  `CAST(NULL AS DATE)` por `DATE 'YYYY-MM-DD'` en `params`.
- Resulto lento en Toad por el cruce con `PA_DETALLADO_DE08`, por eso se
  construyo la version liviana para los demas procedimientos.

### TRACKER_PRECALIFICA_VARIANTES_CURSOR_QA02.sql (liviano, agrupado)

- Cuatro bloques `WITH` independientes para los cursores de:
  - `Precalifica_Repre_Cancelado`
  - `Precalifica_Repre_Cancelado_hi`
  - `Precalifica_Represtamo_fiadores`
  - `Precalifica_Represtamo_fiadores_hi`
- Solo aplica los predicados del cursor del SP. No simula UPDATE/DELETE
  posteriores ni el orden no deterministico que impone `ROWNUM <= LOTE`.

### TRACKER_PRECALIFICA_REPRE_CANCELADO_CURSOR_QA02.sql

- Base: `PR.PR_CREDITOS`.
- Filtros relevantes:
  - `PR_TIPO_CREDITO_REPRESTAMO.CARGA = 'S'`.
  - `PERIODOS_CUOTA` permitido o lista vacia.
  - `F_CANCELACION` dentro de `DIAS_CANCELACION` y estado `'C'`.
  - `CODIGO_EMPRESA = F_OBT_EMPRESA_REPRESTAMO`.
  - Sin otro prestamo desembolsado reciente.
  - Sin otro credito en estado `'E'`.
  - Persona fisica, nacionalidad y tipo de documento validos.
  - Sin represtamo en estados no reproceso.
  - `F_TIENE_GARANTIA` = 0.
  - No PEP, no lista negra.
  - Cliente con exactamente dos creditos cancelados.

### TRACKER_PRECALIFICA_REPRE_CANCELADO_HI_CURSOR_QA02.sql

- Base: `PR.PR_CREDITOS_HI` (variante historica).
- Diferencias frente a `Cancelado`:
  - Usa `F_TIENE_GARANTIA_HISTORICO` en lugar de `F_TIENE_GARANTIA`.
  - Cuenta dos creditos cancelados historicos, no actuales.
  - Mantiene el resto de los filtros del cursor.

### TRACKER_PRECALIFICA_REPRESTAMO_FIADORES_CURSOR_QA02.sql

- Base: `PR.PR_CREDITOS` + `PA.PA_DETALLADO_DE08` (mora / clasificacion SIB / capital pagado).
- Filtros relevantes adicionales sobre el cursor:
  - Mora dentro del limite `PRECAL_MORA_MAYOR_PR`.
  - Clasificacion SIB.
  - Capital pagado segun `CAPITAL_PAGADO`.
  - Exige fiador / aval distinto del cliente sobre `PR_AVAL_REPRE_X_CREDITO`.
  - Cliente con exactamente dos creditos cancelados.
- Para evitar `ORA-00918`, las columnas que provienen de `PA_DETALLADO_DE08`
  fueron aliasadas como:
  - `de08_dias_atraso`
  - `de08_califica_cliente`
  - `de08_mto_balance_capital`
  - `de08_monto_desembolsado`
  - `de08_monto_credito`

### TRACKER_PRECALIFICA_REPRESTAMO_FIADORES_HI_CURSOR_QA02.sql

- Base: `PR.PR_CREDITOS_HI` (variante historica de fiadores).
- Filtros propios:
  - `F_CANCELACION` dentro de `DIAS_CANCELACION` y estado `'C'`.
  - Fiador / aval historico distinto del cliente sobre `PR_AVAL_REPRE_X_CREDITO`.
  - `F_TIENE_GARANTIA_HISTORICO = 0`.
  - Cliente con exactamente dos creditos cancelados historicos.
- No usa `PA_DETALLADO_DE08`, por eso es el mas liviano.

## Resultados observados en QA02 (Toad)

Reportados por el usuario tras ejecutar cada tracker liviano:

| Proceso                              | Candidatos finales tracker | Filtro decisivo                                                  |
|--------------------------------------|----------------------------|------------------------------------------------------------------|
| Precalifica_Repre_Cancelado          | 2303                       | embudo completo del cursor                                       |
| Precalifica_Repre_Cancelado_hi       | 6                          | embudo completo del cursor                                       |
| Precalifica_Represtamo_fiadores      | 207                        | embudo completo del cursor                                       |
| Precalifica_Represtamo_fiadores_hi   | 0                          | "Tiene fiador/aval diferente al cliente historico" mata los 6 restantes |

Notas:

- El tracker pesado de `Precalifica_Represtamo` se ejecuto con dos fechas de
  corte: la historica forzada `31/07/2025` y la que toma el proceso por
  defecto (`MAX(FECHA_CORTE) WHERE FUENTE = 'PR'`). Se confirmo que el tracker
  y el cursor leen la misma `FECHA_CORTE` cuando no se fuerza.
- El conteo final no aplica `ROWNUM <= LOTE_DE_CARAGA_REPRESTAMO`. La fila 99
  reporta cuanto recortaria el lote, pero el orden de descarte por lote es no
  deterministico (los cursores del SP no tienen `ORDER BY`).

## Errores corregidos durante la sesion

- `ORA-00918: column ambiguously defined` en el tracker de
  `Precalifica_Represtamo_fiadores`. Causa: columnas con el mismo nombre en
  `PR_CREDITOS` y `PA_DETALLADO_DE08`. Solucion: alias `de08_*` para todas las
  columnas provenientes de `PA_DETALLADO_DE08`.

## Como validar en Toad

1. Conectarse al esquema con permisos sobre `PR`, `PA` en QA02
   (`ADMQA2` segun mapeo de conexiones).
2. Ejecutar cada archivo de tracker como `SELECT` independiente. Cada archivo
   esta autocontenido y termina con un `ORDER BY orden`.
3. Validar que:
   - La primera fila (`orden = 0`) sea el conteo base de
     `PR_CREDITOS` / `PR_CREDITOS_HI` (segun el tracker).
   - Las filas siguientes muestren un embudo monotonicamente decreciente
     (`candidatos_antes >= candidatos_pasan`).
   - La fila `99` muestre la estimacion de corte por `LOTE_DE_CARAGA_REPRESTAMO`.
4. Para el tracker pesado, ajustar la fecha de corte en el CTE `params`
   cuando se quiera reproducir un periodo historico.
5. No ejecutar dentro del job ni en una transaccion donde haya operaciones
   DML en curso; los trackers son solo `SELECT` pero hacen escaneo amplio.

## Pendientes y recomendaciones

- No promover a PROD. Son scripts de diagnostico QA02.
- Si se valida que el ramal `fiadores_hi` queda en 0 candidatos en cada
  corrida, revisar si el filtro "fiador / aval diferente al cliente historico"
  esta funcionando como esperado o si es un cuello que justifica abrir una OPT.
- Si en el futuro se quiere medir el efecto del `ROWNUM <= LOTE`, agregar al
  tracker pesado un `ORDER BY` que reproduzca el ordenamiento que se quiera
  evaluar; documentar explicitamente que se aparta del cursor original.
- Considerar agregar al tracker pesado de `Precalifica_Represtamo` un bloque
  similar de variantes (por fecha de corte forzada) si vuelve a hacer falta
  reproducir un corte historico puntual.
- Reusar el patron `s00..sNN + conteos + pasos` si se necesitan trackers para
  otros procedimientos del package.

## Trazabilidad

- Sesion de cierre: 2026-05-27.
- Sin cambios en `PR.PR_PKG_REPRESTAMOS` (spec o body) en esta sesion.
- Sin commit ejecutado en esta sesion.

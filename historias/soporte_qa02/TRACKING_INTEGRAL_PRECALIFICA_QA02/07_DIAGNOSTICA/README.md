# Capa DIAGNOSTICA - desglose por filtro interno del cursor

Ultima capa del tracking integral (tras los Incrementos A, B y C). Inserta en
`PR.PR_JOB_PRECALIFICA_FILTRO_TRACK`, con `TIPO_MEDICION='DIAGNOSTICA'`, el
desglose filtro a filtro de los cursores de los 5 flujos (lo que las metricas
`REAL` no pueden ver: cuantos quedaron fuera por cada condicion interna).

## Que es y que NO es

- **Es** la reconstruccion secuencial de los filtros del cursor (18 pasos),
  el limite del lote y los descartes post-cursor (X3/X1/X2/mancomunado/edad),
  asociada al `ID_EJECUCION` de una corrida.
- **NO es** evidencia historica inmutable: los wrappers consultan datos y
  parametros VIGENTES al momento de ejecutarlos. Si se corren horas despues
  del job, el paso `Sin represtamo en estados no reproceso` (DIAG_CUR_13) se
  ve afectado por los candidatos que la propia corrida creo. Por eso cada fila
  lleva la advertencia en `PARAMETROS` y debe correrse **inmediatamente
  despues del job, sin cargas paralelas**.

## Archivos

| Archivo | Que hace |
|---|---|
| `00_PRECHECK_DIAGNOSTICA_QA02.sql` | Unico SELECT para F9/Data Grid: conexion, gate, lote, ultima ejecucion y estado del package. |
| `01..05_DIAG_*.sql` | Un wrapper por flujo, dividido en INSERT, verificacion y COMMIT para ejecutar con F9. |
| `06_VALIDAR_DIAGNOSTICA_QA02.sql` | Validacion F9: cobertura, funnel por flujo y cruce DIAG_LOTE vs bruto real (Incremento C) vs neto (Capa B). |
| `07_ROLLBACK_DIAGNOSTICA_QA02.sql` | Reversa con SELECT, DELETE, verificacion y COMMIT separados para F9. |
| `08_DIAG_TODO_EN_UNO_QA02.sql` | WIP F5 descartado. No ejecutar. |

## Orden de ejecucion en Toad (`AJEREZ@QADEMI02_19C`)

1. En `00_PRECHECK_DIAGNOSTICA_QA02.sql`, colocar el cursor dentro del unico
   `SELECT` y ejecutar con F9. Revisar en `Data Grid`: base QA02, gate `S`,
   lote `1300`, ultima ejecucion no nula y package body `VALID`.
2. Correr el job `PR.JOB_CARGA_PRECALIFICA_RD` (los wrappers se asocian a la
   ULTIMA ejecucion registrada en `PR_JOB_PRECALIFICA_TRACK`).
3. Inmediatamente despues, abrir cada wrapper `01..05` y ejecutar con F9:
   primero el `INSERT`, luego el `SELECT COUNT(*)` de verificacion y por
   ultimo el `COMMIT`. Colocar el cursor dentro de la sentencia exacta antes
   de presionar F9. Si el conteo no es correcto, ejecutar `ROLLBACK` en vez
   de `COMMIT`.
4. Ejecutar `06_VALIDAR_DIAGNOSTICA_QA02.sql` con F9 por query.
5. Si la corrida diagnostica no sirve (p. ej. se corrio muy tarde):
   ejecutar `07_ROLLBACK_DIAGNOSTICA_QA02.sql` sentencia por sentencia con F9.

## Reglas y notas

- Gating: los wrappers solo insertan si `TRACK_PRECALIFICA_DETALLE_CURSOR='S'`
  (ya esta en `'S'` en QA02). Con `'N'` no insertan nada.
- Solo INSERT a la tabla de tracking; no tocan tablas funcionales ni el
  package. El COMMIT es manual y separado para permitir verificar primero.
- `ORDEN_FILTRO` DIAGNOSTICA: cursor `100-117`, lote `299`, post-cursor
  `300-305`, cleanup `498` (no choca con los `1..31` de las metricas REAL).
- Correcciones de la seccion 7 de la propuesta aplicadas a los trackers
  canonicos: 7.1 `POST_CLEANUP` corregido (tracker 01), 7.2 desviacion del
  denominador documentada (trackers 01 y 04), 7.3 el tracker 02 (Cancelado)
  no tiene cleanup porque el `DELETE X%` esta comentado en el package,
  7.4 la pertenencia real al lote ya la captura el Incremento C en el FETCH
  (el lote diagnostico es aproximacion no deterministica).

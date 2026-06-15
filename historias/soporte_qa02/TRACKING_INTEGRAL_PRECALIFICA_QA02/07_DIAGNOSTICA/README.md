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
| `00_PRECHECK_DIAGNOSTICA_QA02.sql` | Precheck rapido de conexion, gate, lote y ultima ejecucion. No inserta datos. |
| `01..05_DIAG_*.sql` | Un wrapper INSERT por flujo. **Generados** desde los trackers canonicos de `ENTORNOS_ORACLE/.../trackers_precalifica_post_cursor_fast/`; no editar el SQL interno aqui. |
| `06_VALIDAR_DIAGNOSTICA_QA02.sql` | Validacion F9: cobertura, funnel por flujo y cruce DIAG_LOTE vs bruto real (Incremento C) vs neto (Capa B). |
| `07_ROLLBACK_DIAGNOSTICA_QA02.sql` | Borra SOLO las filas DIAGNOSTICA de la ultima ejecucion. |

## Orden de ejecucion en Toad (`AJEREZ@QADEMI02_19C`)

1. Ejecutar con F5 `00_PRECHECK_DIAGNOSTICA_QA02.sql`. Debe terminar en
   segundos y mostrar conexion, gate, lote y ultima ejecucion. Si no imprime
   nada, el problema esta en la ejecucion o visualizacion de `Script Output`
   de Toad, antes de entrar al SQL diagnostico.
2. Correr el job `PR.JOB_CARGA_PRECALIFICA_RD` (los wrappers se asocian a la
   ULTIMA ejecucion registrada en `PR_JOB_PRECALIFICA_TRACK`).
3. Inmediatamente despues, ejecutar como script (F5) los wrappers `01..05`
   (cada uno termina con su propio COMMIT y un conteo de verificacion).
   Pueden tardar varios minutos cada uno (evaluan PEP/lista negra/garantia
   por candidato).
   El wrapper 01 ahora imprime un aviso antes de iniciar su `INSERT`; si el
   aviso aparece y no hay salida posterior, Oracle sigue ejecutando el
   conteo pesado.
4. Ejecutar `06_VALIDAR_DIAGNOSTICA_QA02.sql` con F9 por query.
5. Si la corrida diagnostica no sirve (p. ej. se corrio muy tarde):
   `07_ROLLBACK_DIAGNOSTICA_QA02.sql` y repetir.

## Reglas y notas

- Gating: los wrappers solo insertan si `TRACK_PRECALIFICA_DETALLE_CURSOR='S'`
  (ya esta en `'S'` en QA02). Con `'N'` no insertan nada.
- Solo INSERT a la tabla de tracking + COMMIT propio; no tocan tablas
  funcionales ni el package.
- `ORDEN_FILTRO` DIAGNOSTICA: cursor `100-117`, lote `299`, post-cursor
  `300-305`, cleanup `498` (no choca con los `1..31` de las metricas REAL).
- Correcciones de la seccion 7 de la propuesta aplicadas a los trackers
  canonicos: 7.1 `POST_CLEANUP` corregido (tracker 01), 7.2 desviacion del
  denominador documentada (trackers 01 y 04), 7.3 el tracker 02 (Cancelado)
  no tiene cleanup porque el `DELETE X%` esta comentado en el package,
  7.4 la pertenencia real al lote ya la captura el Incremento C en el FETCH
  (el lote diagnostico es aproximacion no deterministica).

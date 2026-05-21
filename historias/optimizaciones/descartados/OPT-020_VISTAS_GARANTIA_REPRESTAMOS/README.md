# OPT-020 - Vistas de garantia para PR_PKG_REPRESTAMOS

## Resumen

OPT-020 propone centralizar como vistas SQL la logica de `F_TIENE_GARANTIA` y
`F_TIENE_GARANTIA_HISTORICO` para migrar los cursores masivos de
`PR.PR_PKG_REPRESTAMOS` sin duplicar el `JOIN` en cada cursor.

Entorno objetivo: `QA02`.

## Diagnostico

En QA02, `F_TIENE_GARANTIA` y `F_TIENE_GARANTIA_HISTORICO` son contrato publico
del paquete porque estan declaradas en `spec.sql`.

Evidencia:

- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/spec.sql:424-428`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql:9989-10032`

Los cursores de cancelado todavia llaman las funciones dentro del `WHERE`:

- `body.sql:478-479` usa `F_TIENE_GARANTIA(a.no_credito) = 0`
- `body.sql:860-861` usa `F_TIENE_GARANTIA_HISTORICO(a.no_credito) = 0`

Ese patron obliga a Oracle a llamar PL/SQL por cada fila candidata y oculta la
logica de garantia al optimizador.

## Propuesta

Crear dos vistas:

- `PR.V_REPRE_CREDITOS_GAR`
- `PR.V_REPRE_CREDITOS_HI_GAR`

Cada vista devuelve una fila por `CODIGO_EMPRESA, NO_CREDITO` con
`CANTIDAD_GARANTIAS`. La columna conserva la semantica de `COUNT(1)` de las
funciones actuales.

Los cursores masivos deben usar `NOT EXISTS` contra estas vistas. Las funciones
se mantienen por compatibilidad y pueden reimplementarse opcionalmente para leer
desde las vistas.

## Archivos

| Archivo | Uso |
|---------|-----|
| `00_DIAGNOSTICO_EJECUCION.sql` | Diagnostica usuario, schema, privilegios y vistas existentes antes del DDL |
| `01_CREATE_VIEWS.sql` | Crea las vistas y valida columnas requeridas |
| `01A_CREATE_VIEW_CREDITOS_GAR.sql` | Crea solo la vista de creditos actuales para aislar errores de DDL |
| `01B_CREATE_VIEW_CREDITOS_HI_GAR.sql` | Crea solo la vista de creditos historicos para aislar errores de DDL |
| `02_VALIDAR_EQUIVALENCIA.sql` | Compara funcion vs vista; debe retornar 0 diferencias |
| `03_PATCH_PAQUETE_SNIPPETS.sql` | Reemplazos manuales para el body del paquete |
| `04_ROLLBACK.sql` | Elimina las vistas si hay que revertir |
| `05_VALIDAR_INDICES.sql` | Muestra indices existentes sobre tablas base |
| `06_CREATE_TRACKING_TABLE_JOB_PRECALIFICA_RD.sql` | Crea tabla persistente para tiempos por proceso del job |
| `07_PATCH_TRACKING_PAQUETE_SNIPPETS.sql` | Snippets para instrumentar `P_Carga_Precalifica_Cancelado` sin cambiar la spec |
| `08_CONSULTAR_TRACKING_JOB_PRECALIFICA_RD.sql` | Consulta ultimas ejecuciones, ranking por duracion, historico por proceso y detalle de medicion de telefonos |
| `09_ROLLBACK_TRACKING_PERSISTENTE_QA02.sql` | Elimina la tabla de tracking si se retira la instrumentacion |
| `15_CREATE_TEL_BENCH_TRACK_QA02.sql` | Crea tabla persistente para medir la llamada compilada a `obt_telefono_persona` durante el job |
| `16_ROLLBACK_TEL_BENCH_TRACK_QA02.sql` | Elimina la tabla de medicion de telefonos si se retira la instrumentacion |
| `17_RECREATE_PR_V_ENVIO_REPRESTAMOS_QA02.sql` | Recrea `PR.PR_V_ENVIO_REPRESTAMOS` para llamar la sobrecarga de `F_OBT_BODY_MENSAJE` con nombre, fecha y canal, y expone `CANAL_DESC` para APEX |
| `18_ROLLBACK_PR_V_ENVIO_REPRESTAMOS_QA02.sql` | Restaura el DDL actual de QA02 con llamada vieja por `ID_REPRESTAMO` y canal |
| `19_VALIDAR_PR_V_ENVIO_REPRESTAMOS_QA02.sql` | Valida conteo, muestreo sin mensaje, muestreo con mensaje, estado y DDL de la vista |
| `11_DIAGNOSTICO_LOTE_FECHA_CORTE.sql` | Diagnostica candidatos por fecha de corte para aumentar volumen procesado |
| `12_HANDOFF_LOTE_FECHA_CORTE.md` | Contexto y prompt para continuar la investigacion del lote |
| `HANDOFF_TRACKING_QA02.md` | Resumen de cierre, ubicaciones y contexto para continuar |
| `RESULTADOS_QA.md` | Evidencia de creacion de vistas y validaciones en QA |
| `RESULTADOS_QA02.md` | Evidencia de creacion de vistas, equivalencia y cambio local en QA02 |

## Dependencias faltantes en repo

En `ENTORNOS_ORACLE/QA02/schemas/PR/tables` existen `PR_CREDITOS.sql` y
`PR_CREDITOS_HI.sql`, pero no se encontraron DDL completos para:

- `PR.PR_GARANTIAS`
- `PR.PR_GARANTIAS_X_CREDITO`

Por eso `01_CREATE_VIEWS.sql` inicia con una verificacion de `ALL_TAB_COLUMNS`.
Si faltan columnas en QA02, detener el pase y agregar los DDL reales al repo.

## Riesgo

- Bajo si `02_VALIDAR_EQUIVALENCIA.sql` retorna 0 diferencias.
- Medio si se reimplementan las funciones sin validar consumidores que comparen
  exactamente `= 1`; por eso la vista conserva `CANTIDAD_GARANTIAS` y no solo un
  indicador booleano.
- No se modifica `spec.sql`.

## Validacion en Toad

1. Ejecutar `01_CREATE_VIEWS.sql`.
2. Confirmar que las vistas quedan `VALID`.
3. Ejecutar `02_VALIDAR_EQUIVALENCIA.sql`.
4. Confirmar 0 diferencias en Q01 y Q02.
5. Ejecutar `05_VALIDAR_INDICES.sql` para confirmar soporte de indices.
6. Aplicar snippets de `03_PATCH_PAQUETE_SNIPPETS.sql` en una copia controlada
   del body del paquete.
7. Compilar `PR.PR_PKG_REPRESTAMOS`.
8. Ejecutar regresion de `P_Carga_Precalifica_Cancelado`.
9. Comparar conteos finales de estados `RE`, `NP`, `RXT`, `CP`, `AN`.
10. Para dejar tracking al ejecutar el job normal en QA02, ejecutar una sola vez
    `06_CREATE_TRACKING_TABLE_JOB_PRECALIFICA_RD.sql`.
11. Para medir telefonos PA o PR durante el job, ejecutar una sola vez
    `15_CREATE_TEL_BENCH_TRACK_QA02.sql`.
12. En `F_QA02_Medir_Telefono`, dejar compilada la llamada que se quiere medir:
    `PA.obt_telefono_persona` para la primera corrida o `PR.obt_telefono_persona`
    para la segunda corrida.
13. Aplicar los snippets de `07_PATCH_TRACKING_PAQUETE_SNIPPETS.sql` en el body
    del paquete y compilar `PR.PR_PKG_REPRESTAMOS`.
14. Ejecutar `PR.JOB_CARGA_PRECALIFICA_RD` normalmente desde Scheduler/Toad.
15. Consultar tiempos por proceso y telefonos con `08_CONSULTAR_TRACKING_JOB_PRECALIFICA_RD.sql`.

## Tracking QA02

El 2026-05-18 se preparo `body_actual_QA02_tracking/body_actual_QA02.sql`
con tracking persistente para `P_Carga_Precalifica_Cancelado`. El respaldo del
body recibido antes del cambio quedo como
`body_actual_QA02_tracking/body_actual_QA02_BEFORE_TRACKING.sql`.

El contexto de cierre y siguiente trabajo quedo documentado en
`HANDOFF_TRACKING_QA02.md`. El prompt listo para continuar esta en
`docs/prompts_codex/continuar_opt020_cache_variables_represtamos.md`.

## PR_V_ENVIO_REPRESTAMOS QA02

El 2026-05-20 se confirmo en QA02 que `PR.PR_PKG_REPRESTAMOS` ya tenia la
sobrecarga nueva de `F_OBT_BODY_MENSAJE(pNombres, pFecha, pCanal)`, pero el DDL
vivo de `PR.PR_V_ENVIO_REPRESTAMOS` seguia llamando la firma vieja
`F_OBT_BODY_MENSAJE(R.ID_REPRESTAMO, CR.CANAL)`.

Medicion observada en Toad sobre QA02:

- `COUNT(*)` de la vista: 3,991 filas en 0.18s.
- Muestreo de 20 filas sin `TEXTO_MENSAJE`: 0.08s.
- Muestreo de 20 filas con `SUBSTR(TEXTO_MENSAJE, 1, 120)`: 21.92s.

Conclusion: el costo esta concentrado en la columna `TEXTO_MENSAJE`, porque la
vista todavia ejecuta la funcion vieja por fila. El script
`17_RECREATE_PR_V_ENVIO_REPRESTAMOS_QA02.sql` conserva la estructura actual de
la vista y cambia solo la fuente de `TEXTO_MENSAJE` para usar la sobrecarga
nueva. Se pasa `PF.PRIMER_NOMBRE` para preservar el texto generado por la firma
vieja, que usaba el primer nombre aunque la vista exponga `C.NOMBRES`.

Al probar APEX, el reporte interactivo fallo con `ORA-00904: "D"."CANAL_DESC"`.
La causa es que la metadata del reporte referencia `CANAL_DESC`, pero el DDL
vivo de QA02 no exponia esa columna. El script `17_RECREATE...` agrega
`CANAL_DESC` por `CASE` directo sobre `CR.CANAL` para mantener compatible el
reporte sin reintroducir la llamada lenta de `TEXTO_MENSAJE`.

## Resultado QA02

El 2026-05-18 el usuario ejecuto la creacion de vistas y la validacion de
equivalencia en QA02. Las vistas quedaron `VALID`, Q01/Q02 retornaron 0
diferencias y los conteos booleanos fueron equivalentes:

- actual: 12,293 vs 12,293
- historico: 0 vs 0

Detalle en `RESULTADOS_QA02.md`.

## Nota QA

Si al ejecutar `02_VALIDAR_EQUIVALENCIA.sql` aparece `ORA-00942` en Q01, revisar
primero `Q00` y `Q00B` del mismo script. La causa esperada es una de estas:

- `01_CREATE_VIEWS.sql` no termino de crear `PR.V_REPRE_CREDITOS_GAR` y
  `PR.V_REPRE_CREDITOS_HI_GAR`.
- El script se ejecuto con un usuario que no puede crear objetos en `PR`.
- Las vistas existen, pero el usuario actual no tiene `SELECT` sobre ellas.

La validacion debe correr despues de que ambas vistas existan en `PR` y esten
`VALID`.

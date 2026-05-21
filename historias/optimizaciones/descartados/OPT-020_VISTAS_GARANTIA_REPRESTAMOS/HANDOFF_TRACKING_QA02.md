# HANDOFF - OPT-020 tracking QA02 y siguiente optimizacion

## Estado al cierre

Fecha de cierre: 2026-05-18.

Entorno trabajado: `QA02`.

Objeto principal:

- `PR.PR_PKG_REPRESTAMOS`
- Procedimiento objetivo: `P_Carga_Precalifica_Cancelado`

No se cambio la `spec`. La interfaz publica sigue igual.

## Archivos clave

| Archivo | Proposito |
|---------|-----------|
| `body_actual_QA02_tracking/body_actual_QA02.sql` | Body actual de QA02 con tracking persistente aplicado |
| `body_actual_QA02_tracking/body_actual_QA02_BEFORE_TRACKING.sql` | Respaldo del body recibido antes del tracking |
| `06_CREATE_TRACKING_TABLE_JOB_PRECALIFICA_RD.sql` | Crea/valida `PR.PR_JOB_PRECALIFICA_TRACK`, indices de tracking e indice MVP |
| `08_CONSULTAR_TRACKING_JOB_PRECALIFICA_RD.sql` | Consulta ultimas ejecuciones, ranking por proceso, historico y medicion de telefonos |
| `07_PATCH_TRACKING_PAQUETE_SNIPPETS.sql` | Resumen del patch aplicado y mapa de pasos |
| `15_CREATE_TEL_BENCH_TRACK_QA02.sql` | Crea/valida `PR.PR_TEL_PERSONA_BENCH_TRACK` para detalle de telefonos |
| `16_ROLLBACK_TEL_BENCH_TRACK_QA02.sql` | Elimina `PR.PR_TEL_PERSONA_BENCH_TRACK` si se retira la medicion |
| `RESULTADOS_QA02.md` | Evidencia de vistas/equivalencia en QA02 |

## Tracking aplicado

La tabla de salida del tracking es:

- `PR.PR_JOB_PRECALIFICA_TRACK`
- `PR.PR_TEL_PERSONA_BENCH_TRACK` para detalle por llamada durante `P_REGISTRO_SOLICITUD`

El script `06_CREATE_TRACKING_TABLE_JOB_PRECALIFICA_RD.sql` crea la tabla con
PK por `ID_EJECUCION, ID_PASO` y los indices:

- `PK_PR_JOB_PRECALIFICA_TRACK`
- `IX_PRECAL_TRACK_FECHA`
- `IX_PRECAL_TRACK_PROCESO`

Tambien agrega el indice de apoyo para `PA.PA_PARAMETROS_MVP`:

- `PA.IDX_PARAM_MVP_COD_PARAM (CODIGO_MVP, CODIGO_PARAMETRO)`

## Lineas importantes en el body con tracking

En `body_actual_QA02_tracking/body_actual_QA02.sql`:

- Declaracion de variables/rutinas de tracking: lineas `8012-8176` aprox.
- Inicio de `TOTAL_JOB`: linea `8179` aprox.
- Pasos instrumentados del orquestador: lineas `8181-8265` aprox.
- Registro de error antes de relanzar al logger: lineas `8268-8269` aprox.
- `PVALIDA_XCORE` permanece comentado en el orquestador: lineas `8228-8229` aprox.

## Mapa de pasos del tracking

| ID_PASO | PROCESO |
|---------|---------|
| 0 | `TOTAL_JOB` |
| 1 | `P_Actualizar_Anular_Represtamo` |
| 2 | `Precalifica_Represtamo` |
| 3 | `Precalifica_Represtamo_fiadores` |
| 4 | `Precalifica_Represtamo_fiadores_hi` |
| 5 | `Precalifica_Repre_Cancelado` |
| 6 | `Precalifica_Repre_Cancelado_hi` |
| 7 | `COUNT_RE` |
| 8 | `Actualiza_Precalificacion` |
| 9 | `Actualiza_XCORE_CUSTOM` |
| 10 | `P_REGISTRO_SOLICITUD` |
| 11 | `PVALIDA_WORLD_COMPLIANCE` |
| 12 | `LOOP_FINAL_VALIDACIONES_BITACORA` |
| 13 | `ACTUALIZA_PARAMETRO_EJECUCIONES` |

## Validacion pendiente en QA02

1. Ejecutar `06_CREATE_TRACKING_TABLE_JOB_PRECALIFICA_RD.sql` si la tabla de pasos no existe.
2. Ejecutar `15_CREATE_TEL_BENCH_TRACK_QA02.sql` si la tabla de telefonos no existe.
3. En `F_QA02_Medir_Telefono`, dejar compilada la llamada a `PA.obt_telefono_persona`.
4. Compilar el body instrumentado en QA02.
5. Ejecutar `PR.JOB_CARGA_PRECALIFICA_RD` normalmente y guardar el `ID_EJECUCION`.
6. En `F_QA02_Medir_Telefono`, cambiar manualmente a `PR.obt_telefono_persona` y recompilar.
7. Ejecutar `PR.JOB_CARGA_PRECALIFICA_RD` nuevamente y guardar el `ID_EJECUCION`.
8. Consultar `08_CONSULTAR_TRACKING_JOB_PRECALIFICA_RD.sql`; usar Q06/Q10 para comparar las dos corridas.
9. Si falla compilacion, usar el respaldo previo como base para comparar.

## Proxima optimizacion

Objetivo: reducir llamadas repetidas a consultas/funciones que devuelven valores
estables durante una misma corrida del job.

En la nueva sesion se debe analizar el body completo y proponer primero. No
cambiar logica de negocio ni `spec`.

Buscar candidatos como:

- Parametros de `PA.PA_PARAMETROS_MVP` consultados repetidamente.
- Valores de `F_OBT_PARAMETRO_REPRESTAMO`.
- Valores de `F_Obt_Empresa_Represtamo`.
- Listas obtenidas por `F_Obt_Valor_Parametros`.
- Cualquier consulta constante por corrida dentro de loops masivos.

Prioridad: empezar por `P_Carga_Precalifica_Cancelado` y los procesos que el
tracking muestre como mas costosos.

# Pase 8 indices a PROD - 2026-04-23

Pase consolidado de 8 indices de apoyo al paquete `PR.PR_PKG_REPRESTAMOS`. Confirmado en [ENTORNOS_ORACLE/Produccion/CHANGELOG.md:10-41](../../../../ENTORNOS_ORACLE/Produccion/CHANGELOG.md).

## Estado

| Campo | Valor |
|---|---|
| Estado actual | PRODUCCION |
| Fecha de pase | 2026-04-23 |
| Tablespaces | `PA_IDX` / `PR_IDX` |
| Riesgo monitoreado | Indices cuyo codigo asociado NO esta en PROD (OPT-004, OPT-010, OPT-015, OPT-016) penalizan DML sin entregar beneficio pleno. |
| Tracking | Memoria `project_prod_indexes_20260423.md` y baseline `project_prod_job_precalifica_baseline.md` |

## Indices en este pase

| # | OPT origen | Indice | Tabla | DDL en repo | Codigo asociado |
|---|---|---|---|---|---|
| 1 | OPT-002 | `IDX_DE08_SIB_FECHA_DEUDOR` | `PA.PA_DE08_SIB` (FECHA_CORTE, ID_DEUDOR, CLASIFICACION) | [ENTORNOS_ORACLE/Produccion/schemas/PA/tables/PA_DE08_SIB/indexes.sql](../../../../ENTORNOS_ORACLE/Produccion/schemas/PA/tables/PA_DE08_SIB/indexes.sql) | Codigo: [optimizaciones/probados_no_promovidos/OPT-002_OBT_IDENTIFICACION_CURSORES_SIB/](../../probados_no_promovidos/OPT-002_OBT_IDENTIFICACION_CURSORES_SIB/) (no en PROD) |
| 2 | OPT-004 | `IDX_DE08_NOCRED_CALIF_FECHA` | `PA.PA_DETALLADO_DE08` (NO_CREDITO, FECHA_CORTE, CALIFICA_CLIENTE) | [ENTORNOS_ORACLE/Produccion/schemas/PA/tables/PA_DETALLADO_DE08/indexes.sql](../../../../ENTORNOS_ORACLE/Produccion/schemas/PA/tables/PA_DETALLADO_DE08/indexes.sql) | Codigo: [optimizaciones/probados_no_promovidos/OPT-004_SETBASED_ACTUALIZAR_MTO_CREDITO/](../../probados_no_promovidos/OPT-004_SETBASED_ACTUALIZAR_MTO_CREDITO/) (no en PROD) |
| 3 | OPT-009 | `IDX_CREDITOS_HI_NOCREDITO` | `PR.PR_CREDITOS_HI` (NO_CREDITO) | [ENTORNOS_ORACLE/Produccion/schemas/PR/tables/PR_CREDITOS_HI/indexes.sql](../../../../ENTORNOS_ORACLE/Produccion/schemas/PR/tables/PR_CREDITOS_HI/indexes.sql) | Codigo: [optimizaciones/probados_no_promovidos/OPT-009_SUBQUERIES_F_OBTENER_NUEVO_CREDITO/](../../probados_no_promovidos/OPT-009_SUBQUERIES_F_OBTENER_NUEVO_CREDITO/) (no en PROD) |
| 4 | OPT-010 | `IDX_GARANTIAS_TIPO_SB` | `PR.PR_GARANTIAS` (CODIGO_EMPRESA, NUMERO_GARANTIA, CODIGO_TIPO_GARANTIA_SB) | [ENTORNOS_ORACLE/Produccion/schemas/PR/tables/PR_GARANTIAS/indexes.sql](../../../../ENTORNOS_ORACLE/Produccion/schemas/PR/tables/PR_GARANTIAS/indexes.sql) | Codigo: [optimizaciones/probados_no_promovidos/OPT-010_INLINE_F_TIENE_GARANTIA/](../../probados_no_promovidos/OPT-010_INLINE_F_TIENE_GARANTIA/) (no en PROD) |
| 5 | OPT-011 | `IDX_REPRESTAMOS_EMP_EST_NOCRED` | `PR.PR_REPRESTAMOS` (CODIGO_EMPRESA, ESTADO, NO_CREDITO, ID_REPRESTAMO) | [ENTORNOS_ORACLE/Produccion/schemas/PR/tables/PR_REPRESTAMOS/indexes.sql](../../../../ENTORNOS_ORACLE/Produccion/schemas/PR/tables/PR_REPRESTAMOS/indexes.sql) | Codigo: [optimizaciones/probados_no_promovidos/OPT-011_SQL371_ANULAR_CREDITOS_CANCELADOS/](../../probados_no_promovidos/OPT-011_SQL371_ANULAR_CREDITOS_CANCELADOS/) (no en PROD) |
| 6 | OPT-013 | `IDX_DE05_SIB_CASTIGO_CEDULA` | `PA.PA_DE05_SIB` (FECHA_CASTIGO, CEDULA, ENTIDAD) | [ENTORNOS_ORACLE/Produccion/schemas/PA/tables/PA_DE05_SIB/indexes.sql](../../../../ENTORNOS_ORACLE/Produccion/schemas/PA/tables/PA_DE05_SIB/indexes.sql) | Detalle: [OPT-013_INDICE_PA_DE05_SIB/](./OPT-013_INDICE_PA_DE05_SIB/) (solo indice, no requiere cambio de codigo) |
| 7 | OPT-016 | `IDX_REPRESTAMOS_ESTADO_COV` | `PR.PR_REPRESTAMOS` (ESTADO, ID_REPRESTAMO, XCORE_GLOBAL) | [ENTORNOS_ORACLE/Produccion/schemas/PR/tables/PR_REPRESTAMOS/indexes.sql](../../../../ENTORNOS_ORACLE/Produccion/schemas/PR/tables/PR_REPRESTAMOS/indexes.sql) | Codigo asociado: cambios bulk collect en `P_REGISTRO_SOLICITUD` (OPT-017) en [optimizaciones/probados_no_promovidos/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/](../../probados_no_promovidos/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/) (no en PROD) |
| 8 | OPT-016 | `IDX_SOLREPRE_IDREPRE_TIPCRED` | `PR.PR_SOLICITUD_REPRESTAMO` (ID_REPRESTAMO, TIPO_CREDITO) | [ENTORNOS_ORACLE/Produccion/schemas/PR/tables/PR_SOLICITUD_REPRESTAMO/indexes.sql](../../../../ENTORNOS_ORACLE/Produccion/schemas/PR/tables/PR_SOLICITUD_REPRESTAMO/indexes.sql) | Subquery `F_Obtener_Nuevo_Credito` (parte de OPT-009) en [optimizaciones/probados_no_promovidos/OPT-009_SUBQUERIES_F_OBTENER_NUEVO_CREDITO/](../../probados_no_promovidos/OPT-009_SUBQUERIES_F_OBTENER_NUEVO_CREDITO/) (no en PROD) |

## Evidencia de respaldo previo al pase

- 4 indices con medicion real del job completo en DESARROLLO ([optimizaciones/diagnosticos/OPT-014_INDICES_MEDICION_REAL/](../../diagnosticos/OPT-014_INDICES_MEDICION_REAL/), reduccion -41% tiempo total, -99% PIO):
  - `IDX_DE08_SIB_FECHA_DEUDOR` (OPT-002)
  - `IDX_CREDITOS_HI_NOCREDITO` (OPT-009)
  - `IDX_REPRESTAMOS_EMP_EST_NOCRED` (OPT-011)
  - `IDX_DE05_SIB_CASTIGO_CEDULA` (OPT-013)
- 4 indices con evidencia aislada (Explain Plan o medicion por query individual):
  - `IDX_DE08_NOCRED_CALIF_FECHA` (OPT-004)
  - `IDX_GARANTIAS_TIPO_SB` (OPT-010)
  - `IDX_REPRESTAMOS_ESTADO_COV` (OPT-016)
  - `IDX_SOLREPRE_IDREPRE_TIPCRED` (OPT-016)

## Resultado medido en PROD

| Mes | Job_Precalifica_Represtamo | Delta vs baseline |
|---|---|---|
| Abril 2026 (baseline) | 213 min | - |
| Mayo 2026 | 183 min | -13.8% |

Fuente: memoria `project_prod_job_precalifica_baseline.md`.

## Pendientes en PROD

1. Confirmar `STATUS=VALID` en `ALL_INDEXES` para los 8 indices.
2. Confirmar tablespace efectivo `PA_IDX`/`PR_IDX` (no DATA). Si el DBA los creo en otro tablespace, actualizar los `indexes.sql` para reflejar la realidad.
3. Confirmar refresh de estadisticas (`DBMS_STATS.GATHER_TABLE_STATS(..., cascade=>TRUE)`) tras la creacion.
4. Monitoreo 1-2 semanas de regresiones en queries OLTP sobre `PR_REPRESTAMOS` (`ESTADO` es columna lider baja cardinalidad).

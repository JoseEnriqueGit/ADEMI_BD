# 2026-04-23 - Pase 8 indices PR_PKG_REPRESTAMOS a PROD

| Campo | Valor |
|---|---|
| Fecha | 2026-04-23 |
| Origen | QA / DESARROLLO |
| Destino | PROD |
| Tipo | Indices (DDL) |
| Tablespaces | PA_IDX / PR_IDX |
| OPT origen | OPT-002, OPT-004, OPT-009, OPT-010, OPT-011, OPT-013, OPT-016 |
| Historia consolidada | [optimizaciones/produccion/INDICES_2026-04-23/](../optimizaciones/produccion/INDICES_2026-04-23/) |
| Confirmacion en CHANGELOG | [ENTORNOS_ORACLE/Produccion/CHANGELOG.md](../../ENTORNOS_ORACLE/Produccion/CHANGELOG.md) |

## Indices promovidos

| # | OPT | Indice | Tabla |
|---|---|---|---|
| 1 | OPT-002 | `IDX_DE08_SIB_FECHA_DEUDOR` | PA.PA_DE08_SIB (FECHA_CORTE, ID_DEUDOR, CLASIFICACION) |
| 2 | OPT-004 | `IDX_DE08_NOCRED_CALIF_FECHA` | PA.PA_DETALLADO_DE08 (NO_CREDITO, FECHA_CORTE, CALIFICA_CLIENTE) |
| 3 | OPT-009 | `IDX_CREDITOS_HI_NOCREDITO` | PR.PR_CREDITOS_HI (NO_CREDITO) |
| 4 | OPT-010 | `IDX_GARANTIAS_TIPO_SB` | PR.PR_GARANTIAS (CODIGO_EMPRESA, NUMERO_GARANTIA, CODIGO_TIPO_GARANTIA_SB) |
| 5 | OPT-011 | `IDX_REPRESTAMOS_EMP_EST_NOCRED` | PR.PR_REPRESTAMOS (CODIGO_EMPRESA, ESTADO, NO_CREDITO, ID_REPRESTAMO) |
| 6 | OPT-013 | `IDX_DE05_SIB_CASTIGO_CEDULA` | PA.PA_DE05_SIB (FECHA_CASTIGO, CEDULA, ENTIDAD) |
| 7 | OPT-016 | `IDX_REPRESTAMOS_ESTADO_COV` | PR.PR_REPRESTAMOS (ESTADO, ID_REPRESTAMO, XCORE_GLOBAL) |
| 8 | OPT-016 | `IDX_SOLREPRE_IDREPRE_TIPCRED` | PR.PR_SOLICITUD_REPRESTAMO (ID_REPRESTAMO, TIPO_CREDITO) |

## Evidencia previa al pase

- **Medicion real DESARROLLO**: 4 indices con reduccion -41% tiempo total del job y -99% PIO. Ver [optimizaciones/diagnosticos/OPT-014_INDICES_MEDICION_REAL/](../optimizaciones/diagnosticos/OPT-014_INDICES_MEDICION_REAL/).
- **Evidencia aislada**: 4 indices restantes con Explain Plan o medicion por query individual.

## Resultado posterior al pase

| Mes | Job_Precalifica_Represtamo | Delta vs baseline |
|---|---|---|
| Abril 2026 (baseline) | 213 min | - |
| Mayo 2026 | 183 min | -13.8% |

## Codigo asociado pendiente

4 de los 8 indices dependen de cambios de codigo aun no desplegados (OPT-004, OPT-010, OPT-015, OPT-016). Hasta que ese codigo este en PROD, esos indices penalizan DML sin entregar el beneficio pleno. Ver carpetas en [optimizaciones/probados_no_promovidos/](../optimizaciones/probados_no_promovidos/).

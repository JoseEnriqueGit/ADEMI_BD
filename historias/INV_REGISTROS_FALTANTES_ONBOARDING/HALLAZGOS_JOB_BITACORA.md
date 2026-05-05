# Hallazgos Job Bitacora Reportes Automaticos

## Contexto

Resultado revisado desde `ALL_SCHEDULER_JOBS` en `QADEMI02_19C` para identificar jobs relacionados con `PA.BITACORA_REP_AUTOMATICOS`, `PA.PA_REPORTES_AUTOMATICOS` y `PA.PKG_MANT_TBL_HELADO`.

## Job Principal Identificado

| Owner | Job | Estado | Accion | Frecuencia | Run count | Failure count | Lectura |
|---|---|---|---|---|---:|---:|---|
| `PA` | `JOB_PA_MANT_TBL_HELADO` | `DISABLED` | `BEGIN PA.PKG_MANT_TBL_HELADO.MIGRA_HISTORICO; END;` | `FREQ=DAILY; BYHOUR=23; BYMINUTE=0; BYSECOND=0` | 155 | 0 | Candidato principal para migrar/archivar reportes automaticos y bitacora a historico. |

## Otros Jobs Retornados Por El Filtro

| Owner | Job | Estado | Accion | Lectura |
|---|---|---|---|---|
| `MADVASQUEZ` | `JOB_PA_REPORTE_DG01` | `SCHEDULED` | `BEGIN PA.PKG_REPORTE_DG01_UTIL.CARGA_DATOS_DG01(sysdate-1); END;` | Falso positivo por nombre `REPORTE`; no apunta a `PKG_MANT_TBL_HELADO`. |
| `PA` | `JOB_PA_REPORTE_DG01` | `SCHEDULED` | `BEGIN PA.PKG_REPORTE_DG01_UTIL.CARGA_DATOS_DG01(sysdate-1); END;` | Falso positivo por nombre `REPORTE`; no apunta a `PKG_MANT_TBL_HELADO`. |
| `PA` | `MARK_ERROR_STATUS_AUTOMATIC` | `DISABLED` | `pa.mark_error_status_automatico(p_doc_type => 'SIB')` | Job de ajuste de estados; no migra a historico. |
| `PR` | `REPORTE_HELADO` | `DISABLED` | `begin PR.GENERAR_REPORTES_PENDIENTES(null); end;` | Job generador/procesador de reportes pendientes; no es el archivador de bitacora. |
| `TC` | `JOB_REPORTES_CONSUMOS` | `DISABLED` | `BEGIN TC.TC_ARCHIVO_CONSUMOS.LEE_ARCHIVO (NULL,sysdate); END;` | Falso positivo por nombre `REPORTES`; pertenece a tarjetas. |
| `TC` | `JOB_REPORTES_RETIROS` | `SCHEDULED` | `BEGIN TC.TC_ARCHIVO_RETIROS.LEE_ARCHIVO (NULL,sysdate); END;` | Falso positivo por nombre `REPORTES`; pertenece a tarjetas. |

## Conclusion Operativa

- `PA.BITACORA_REP_AUTOMATICOS` se alimenta por `PA.TRG_REP_AUTOMATICOS`, que llama `PA.Bitacora_Reportes_Automaticos` en cada `INSERT/UPDATE` de `PA.PA_REPORTES_AUTOMATICOS`.
- `PA.JOB_PA_MANT_TBL_HELADO` ejecuta `PA.PKG_MANT_TBL_HELADO.MIGRA_HISTORICO`, que es el flujo candidato para mover datos desde las tablas activas hacia historicos.
- En el ambiente revisado, `PA.JOB_PA_MANT_TBL_HELADO` aparece `DISABLED`; por tanto, no estaria ejecutandose actualmente en ese ambiente, aunque su historial indica ejecuciones previas.

## Evidencia DDL

- `DBMS_METADATA.GET_DDL('PROCOBJ', 'JOB_PA_MANT_TBL_HELADO', 'PA')` retorno el DDL del scheduler job.
- El DDL confirma `job_type => 'PLSQL_BLOCK'`, `job_action => 'BEGIN PA.PKG_MANT_TBL_HELADO.MIGRA_HISTORICO; END;'`, `enabled => FALSE`, `auto_drop => TRUE` y comentario `Migra data de las tablas del HELADO a sus tablas de historico`.
- La consulta directa a `ALL_SCHEDULER_JOBS` confirmo un solo registro para `PA.JOB_PA_MANT_TBL_HELADO`, con frecuencia `FREQ=DAILY; BYHOUR=23; BYMINUTE=0; BYSECOND=0`, `RUN_COUNT = 155` y `FAILURE_COUNT = 0`.

## Pendientes

- Exportar/incorporar el DDL del job `PA.JOB_PA_MANT_TBL_HELADO`.
- Confirmar si el mismo job esta habilitado en Produccion.
- Ejecutar historial de job (`ALL_SCHEDULER_JOB_RUN_DETAILS`) filtrando por `JOB_PA_MANT_TBL_HELADO`.

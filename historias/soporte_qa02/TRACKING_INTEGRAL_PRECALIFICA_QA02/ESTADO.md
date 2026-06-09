# ESTADO - TRACKING_INTEGRAL_PRECALIFICA_QA02

| Campo | Valor |
|---|---|
| Estado actual | QA02_EN_PRUEBAS |
| Entorno donde se probo | QA02 / Oracle 19c (`AJEREZ@QADEMI02_19C`) |
| Fecha del ultimo cambio de estado | 2026-06-09 |
| Fecha de pase a PROD | N/A |
| Objetos tocados | `PR.PR_PKG_REPRESTAMOS` body (A y B aplicados y probados; **C codificado en el repo, SIN aplicar en la base**: helper package-private + captura en las 5 procedures de flujo); DDL aux CREADOS en QA02: `PR_JOB_PRECALIFICA_FILTRO_TRACK`, `PR_JOB_PRECALIFICA_CANDIDATO_TRACK` (+secuencia/indices, +columnas `NO_CREDITO`/`CODIGO_CLIENTE`) y parametros `TRACK_PRECALIFICA_*` |
| Tipo de cambio | Codigo / DDL / Instrumentacion / Soporte QA02 |
| Scripts aplicados | DDL aux `01`, `02`, `03` (2026-06-08). Body A + job (2026-06-09 AM). ALTER `01_DDL/04` + body B + job (2026-06-09 PM). **Pendiente de aplicar:** body con Incremento C (sin DDL nuevo). |
| Scripts rollback | Body C->B: `04_ROLLBACK/ROLLBACK_INCREMENTO_C_BODY_QA02.sql`. Body B->A: `ROLLBACK_INCREMENTO_B_BODY_QA02.sql`. Body->baseline: `ROLLBACK_PR_PKG_REPRESTAMOS_BODY_QA02.sql`. DDL: `01..04_ROLLBACK_*` |
| Resultado de validacion | A PROBADO: `53D427AF4F597DB0E063140311AC14C5`, 31/31 metricas. B PROBADO: `53D8BBE0BA0E44D9E063140311AC6BC6`, Capa C 1302/1302 == FINAL_*, costo MERGE ~0.2 ms/candidato. C: PENDIENTE de prueba (pasos en `05_RESULTADOS/RESULTADOS_QA02.md`). |
| Decision final | A y B aceptados en QA02. C preparado, pendiente de ejecucion y conciliacion. Pendiente capa DIAGNOSTICA. `LOTE_DE_CARAGA_REPRESTAMO` queda en `1300` en QA02 por decision (corridas cortas). No promover sin nueva aprobacion. |
| Tracking / historia Jira | N/A |
| Cambios relacionados | `historias/soporte_qa02/TRACKERS_PRECALIFICA_CURSOR_QA02/` |
| Ultima actualizacion | 2026-06-09, Claude Code (Incremento C implementado en el repo: variante procedures; pendiente probar en QA02) |

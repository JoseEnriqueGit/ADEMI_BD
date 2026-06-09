# ESTADO - TRACKING_INTEGRAL_PRECALIFICA_QA02

| Campo | Valor |
|---|---|
| Estado actual | QA02_EN_PRUEBAS |
| Entorno donde se probo | QA02 / Oracle 19c (`AJEREZ@QADEMI02_19C`) |
| Fecha del ultimo cambio de estado | 2026-06-09 |
| Fecha de pase a PROD | N/A |
| Objetos tocados | `PR.PR_PKG_REPRESTAMOS` body (Incremento A aplicado y probado); DDL aux CREADOS en QA02: `PR_JOB_PRECALIFICA_FILTRO_TRACK`, `PR_JOB_PRECALIFICA_CANDIDATO_TRACK` (+secuencia/indices) y parametros `TRACK_PRECALIFICA_*` |
| Tipo de cambio | Codigo / DDL / Instrumentacion / Soporte QA02 |
| Scripts aplicados | DDL aux `01`, `02`, `03` ejecutados el 2026-06-08. Body Incremento A compilado y job ejecutado el 2026-06-09. |
| Scripts rollback | Body: `04_ROLLBACK/ROLLBACK_PR_PKG_REPRESTAMOS_BODY_QA02.sql`. DDL: `04_ROLLBACK/01..03_ROLLBACK_*` |
| Resultado de validacion | Incremento A PROBADO: ejecucion `53D427AF4F597DB0E063140311AC14C5`, 31/31 metricas, orden 1..31 sin duplicados, precalificacion y cierre conciliados. |
| Decision final | Incremento A aceptado en QA02. Tracking integral completo sigue pendiente de Incrementos B/C y capa DIAGNOSTICA. No promover sin nueva aprobacion. |
| Tracking / historia Jira | N/A |
| Cambios relacionados | `historias/soporte_qa02/TRACKERS_PRECALIFICA_CURSOR_QA02/` |
| Ultima actualizacion | 2026-06-09, Codex (Incremento A aplicado, ejecutado y conciliado en QA02) |

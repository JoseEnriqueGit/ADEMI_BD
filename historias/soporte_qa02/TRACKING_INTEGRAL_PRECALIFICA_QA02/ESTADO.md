# ESTADO - TRACKING_INTEGRAL_PRECALIFICA_QA02

| Campo | Valor |
|---|---|
| Estado actual | QA02_EN_PRUEBAS |
| Entorno donde se probo | QA02 / Oracle 19c (`AJEREZ@QADEMI02_19C`) |
| Fecha del ultimo cambio de estado | 2026-06-09 |
| Fecha de pase a PROD | N/A |
| Objetos tocados | `PR.PR_PKG_REPRESTAMOS` body (Incrementos A y B aplicados y probados); DDL aux CREADOS en QA02: `PR_JOB_PRECALIFICA_FILTRO_TRACK`, `PR_JOB_PRECALIFICA_CANDIDATO_TRACK` (+secuencia/indices, +columnas `NO_CREDITO`/`CODIGO_CLIENTE` del B) y parametros `TRACK_PRECALIFICA_*` |
| Tipo de cambio | Codigo / DDL / Instrumentacion / Soporte QA02 |
| Scripts aplicados | DDL aux `01`, `02`, `03` (2026-06-08). Body Incremento A + job (2026-06-09 AM). ALTER `01_DDL/04` + body Incremento B + job (2026-06-09 PM). |
| Scripts rollback | Body B->A: `04_ROLLBACK/ROLLBACK_INCREMENTO_B_BODY_QA02.sql`. Body->baseline: `04_ROLLBACK/ROLLBACK_PR_PKG_REPRESTAMOS_BODY_QA02.sql`. DDL: `04_ROLLBACK/01..04_ROLLBACK_*` |
| Resultado de validacion | A PROBADO: `53D427AF4F597DB0E063140311AC14C5`, 31/31 metricas conciliadas. B PROBADO: `53D8BBE0BA0E44D9E063140311AC6BC6`, Capa C 1302/1302 == FINAL_* (949 NP + 201 CP + 152 RXT), 0 nulos/duplicados, costo del MERGE ~0.2 ms/candidato. |
| Decision final | Incrementos A y B aceptados en QA02. Pendientes Incremento C y capa DIAGNOSTICA. `LOTE_DE_CARAGA_REPRESTAMO` queda en `1300` en QA02 por decision (corridas cortas; subir a 130000 solo para corridas representativas). No promover sin nueva aprobacion. |
| Tracking / historia Jira | N/A |
| Cambios relacionados | `historias/soporte_qa02/TRACKERS_PRECALIFICA_CURSOR_QA02/` |
| Ultima actualizacion | 2026-06-09, Claude Code (Incremento B aplicado, ejecutado y conciliado en QA02) |

# ESTADO - TRACKING_INTEGRAL_PRECALIFICA_QA02

| Campo | Valor |
|---|---|
| Estado actual | QA02_PROBADO_COMPLETO (A+B+C+DIAGNOSTICA) |
| Entorno donde se probo | QA02 / Oracle 19c (`AJEREZ@QADEMI02_19C`) |
| Fecha del ultimo cambio de estado | 2026-06-15 |
| Fecha de pase a PROD | N/A |
| Objetos tocados | `PR.PR_PKG_REPRESTAMOS` body (Incrementos A, B y C aplicados y probados); DDL aux CREADOS en QA02: `PR_JOB_PRECALIFICA_FILTRO_TRACK`, `PR_JOB_PRECALIFICA_CANDIDATO_TRACK` (+secuencia/indices, +columnas `NO_CREDITO`/`CODIGO_CLIENTE`) y parametros `TRACK_PRECALIFICA_*` |
| Tipo de cambio | Codigo / DDL / Instrumentacion / Soporte QA02 |
| Scripts aplicados | DDL aux `01`, `02`, `03` (2026-06-08). Body A + job (2026-06-09 AM). ALTER `01_DDL/04` + body B + job (2026-06-09 PM). Body C + job (2026-06-09, sin DDL nuevo). |
| Scripts rollback | Body C->B: `04_ROLLBACK/ROLLBACK_INCREMENTO_C_BODY_QA02.sql`. Body B->A: `ROLLBACK_INCREMENTO_B_BODY_QA02.sql`. Body->baseline: `ROLLBACK_PR_PKG_REPRESTAMOS_BODY_QA02.sql`. DDL: `01..04_ROLLBACK_*` |
| Resultado de validacion | A PROBADO: `53D427AF4F597DB0E063140311AC14C5`, 31/31 metricas. B PROBADO: `53D8BBE0BA0E44D9E063140311AC6BC6`, Capa C 1302/1302 == FINAL_*, costo MERGE ~0.2 ms/candidato. C PROBADO: `53DAC2820BDC0E55E063140311AC3EBA`, 1834 filas de pertenencia (4 flujos), 0 huerfanos en el cierre (1166), 317 descartados intra-flujo visibles. DIAGNOSTICA PROBADA: `5414C315EE2373B7E063140311ACD22C`, cobertura 26/22/23/27/24 + TOTAL, REAL intactas (30), cruce DIAG_LOTE vs bruto C con derivas esperadas por secuenciacion (Represtamo topa el lote 1300, deriva 0). |
| Decision final | Tracking integral COMPLETO (A+B+C+DIAGNOSTICA) probado en QA02. `LOTE_DE_CARAGA_REPRESTAMO` queda en `1300` en QA02 por decision (corridas cortas). No promover a PROD sin propuesta y aprobacion separada. |
| Tracking / historia Jira | N/A |
| Cambios relacionados | `historias/soporte_qa02/TRACKERS_PRECALIFICA_CURSOR_QA02/` |
| Ultima actualizacion | 2026-06-15, Claude Code (capa DIAGNOSTICA ejecutada y conciliada en QA02; tracking integral completo) |

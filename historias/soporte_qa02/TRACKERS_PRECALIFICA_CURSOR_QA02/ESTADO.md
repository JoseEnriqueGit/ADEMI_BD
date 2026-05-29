# ESTADO - TRACKERS_PRECALIFICA_CURSOR_QA02

| Campo | Valor |
|---|---|
| Estado actual | SOPORTE |
| Entorno donde se probo | QA02 |
| Fecha del ultimo cambio de estado | 2026-05-27 |
| Fecha de pase a PROD | N/A |
| Objetos tocados | Ninguno productivo. Solo trackers SQL read-only sobre `PR.PR_PKG_REPRESTAMOS` (sin modificar spec ni body). |
| Tipo de cambio | Diagnostico / Soporte QA02 / Instrumentacion read-only |
| Scripts aplicados | `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/TRACKER_PRECALIFICA_REPRESTAMO_QA02.sql`, `TRACKER_PRECALIFICA_VARIANTES_CURSOR_QA02.sql`, `TRACKER_PRECALIFICA_REPRE_CANCELADO_CURSOR_QA02.sql`, `TRACKER_PRECALIFICA_REPRE_CANCELADO_HI_CURSOR_QA02.sql`, `TRACKER_PRECALIFICA_REPRESTAMO_FIADORES_CURSOR_QA02.sql`, `TRACKER_PRECALIFICA_REPRESTAMO_FIADORES_HI_CURSOR_QA02.sql` |
| Scripts rollback | N/A (solo SELECT, no requieren reversa) |
| Resultado de validacion | Toad/QA02: Repre_Cancelado=2303, Repre_Cancelado_hi=6, Fiadores=207, Fiadores_hi=0. Filtro decisivo en fiadores_hi: "fiador/aval diferente al cliente historico". |
| Decision final | Conservar como soporte QA02 reusable. No promover a PROD. |
| Tracking / historia Jira | N/A |
| Cambios relacionados | `historias/soporte_qa02/JOB_CARGA_PRECALIFICA_RD_COMPLETA_QA02/`, `historias/optimizaciones/descartados/OPT-020_VISTAS_GARANTIA_REPRESTAMOS/` |
| Ultima actualizacion | 2026-05-27, Claude Code |

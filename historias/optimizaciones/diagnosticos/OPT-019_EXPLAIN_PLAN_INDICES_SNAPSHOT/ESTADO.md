# ESTADO - OPT-019_EXPLAIN_PLAN_INDICES_SNAPSHOT

| Campo | Valor |
|---|---|
| Estado actual | DIAGNOSTICO |
| Entorno donde se probo | DESARROLLO |
| Fecha del ultimo cambio de estado | 2026-05 |
| Fecha de pase a PROD | N/A |
| Objetos tocados | PA.PA_PARAMETROS_MVP (indice candidato), PR.PR_REPRESTAMOS, PR.PR_BITACORA_REPRESTAMO |
| Tipo de cambio | Diagnostico + Propuesta |
| Decision final | Indice IDX_PARAM_MVP_EMP_MVP_PARAM (renombrado desde IDX_PA_PARAM_MVP_01) validado en DESARROLLO y aprobado para PROD con TABLESPACE PA_IDX. No se recomienda IDX_REPRE_ESTADO_ID_01 porque IDX_REPRESTAMOS_ESTADO_COV ya cubre. |
| Tracking / historia Jira | INC SNAPSHOT TOO OLD |
| Ultima actualizacion | 2026-05-19, reorganizacion automatizada |

Detalle tecnico: ver README.md de esta carpeta.

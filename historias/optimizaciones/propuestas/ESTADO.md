# ESTADO - propuestas/

| Campo | Valor |
|---|---|
| Estado actual | PROPUESTA |
| Entorno donde se probo | No aplicado |
| Fecha del ultimo cambio de estado | 2026-03-19 |
| Fecha de pase a PROD | N/A |
| Objetos involucrados | PR.PR_PKG_REPRESTAMOS - CUR_Anular_creditos_cancelados y otros 2 cursores del job mensual |
| Tipo de cambio | Codigo (hardcodeo de estados) |
| Decision final | Pendiente aprobacion del jefe por trade-off: hardcodeo vs parametros dinamicos. Cost total 11,698 -> 62 (~99.5%). |
| Tracking / historia Jira | Quest SQL 371 + cursores asociados |
| Ultima actualizacion | 2026-05-19, reorganizacion |

Contenido:
- `README.md` - Indice de propuestas.
- `SQL371_HARDCODEO_ESTADOS.md` - Propuesta principal.
- `CURSORES_ANULAR_HARDCODEO_ESTADOS.md` - Propuesta complementaria para los otros 2 cursores.

Si se aprueba la propuesta, mover la carpeta resultante a `optimizaciones/probados_no_promovidos/` cuando exista el codigo probado en QA/DESARROLLO, o directo a `produccion/` cuando se pase a PROD.

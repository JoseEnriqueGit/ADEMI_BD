# Optimizaciones Pendientes

> SQLs problematicos identificados por Quest SQL Optimizer que aun no se han optimizado.

## Pendientes del orquestador P_CARGA_PRECALIFICA_CANCELADO

> Todas las optimizaciones del orquestador han sido implementadas (OPT-001 a OPT-010).

## Pendientes fuera de la cadena del orquestador

| SQL Quest    | Cost    | Descripcion                                    | Ubicacion probable                 |
|-------------|---------|------------------------------------------------|------------------------------------|
| SQL 371     | 10,656  | Query anulacion creditos cancelados            | P_Actualizar_Anular_Represtamo     |
| SQL 364     | 8,332   | UPDATE PROMOCION_PERSONA con INDEX RANGE SCAN  | P_Registrar_Rechazo                |
| SQL 396/397 | ~17,230 | SELECT MAX(PLAZO) con subquery tipo credito    | P_Calcula_Plazo o similar          |
| SQL 149/171/188 | 129,413 | No identificados en PDF (reporte incompleto) | Requieren export del Quest       |

## Notas
- Los SQL 149/171/188 con cost 129,413 son los mas criticos pero no aparecen en el PDF de 220 paginas
- Solicitar al companero que exporte esos SQLs del Quest Optimizer para analisis
- Fecha de identificacion: 2026-03-19

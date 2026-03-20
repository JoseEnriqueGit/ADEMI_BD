# Indice de Optimizaciones

> Registro de todas las optimizaciones de rendimiento realizadas a objetos Oracle.
> Cada optimizacion tiene su propia carpeta con documentacion, diff y rollback.

---

| ID      | Objeto                 | Procedure/SQL              | Cost Antes | Cost Despues | Entorno | Fecha      |
|---------|------------------------|----------------------------|------------|--------------|---------|------------|
| OPT-001 | PR_PKG_REPRESTAMOS     | PVALIDA_WORLD_COMPLIANCE   | 18,293     | 15           | QA      | 2026-03-18 |
| OPT-002 | PR_PKG_REPRESTAMOS     | CUR_DE08_SIB, CUR_DE05_SIB | ~16,963    | <100         | QA      | 2026-03-19 |
| OPT-003 | PR_PKG_REPRESTAMOS     | Actualiza_Precalificacion   | N/A (redo) | -99% flushes | QA      | 2026-03-19 |
| OPT-005 | PR_PKG_REPRESTAMOS     | Actualiza_XCORE_CUSTOM      | N*M iters  | 1 UPDATE     | QA      | 2026-03-19 |
| OPT-006 | PR_PKG_REPRESTAMOS     | P_REGISTRO_SOLICITUD        | N/A (redo) | -99% flushes | QA      | 2026-03-19 |
| OPT-007 | PR_PKG_REPRESTAMOS     | PVALIDA_XCORE               | N/A (redo) | -99% flushes | QA      | 2026-03-19 |
| OPT-008 | PR_PKG_REPRESTAMOS     | P_Carga_Precalifica_Cancel  | 3-9 SELECTs| 3 SELECTs    | QA      | 2026-03-19 |
| OPT-009 | PR_PKG_REPRESTAMOS     | F_Obtener_Nuevo_Credito     | ~17,235    | <500         | QA      | 2026-03-19 |
| OPT-004 | PR_PKG_REPRESTAMOS     | Actualiza_Precalificacion   | N iters    | 2 UPDATEs    | QA      | 2026-03-19 |
| OPT-010 | PR_PKG_REPRESTAMOS     | CREDITOS_PROCESAR (x3)      | N ctx sw   | ANTI JOIN    | QA      | 2026-03-19 |

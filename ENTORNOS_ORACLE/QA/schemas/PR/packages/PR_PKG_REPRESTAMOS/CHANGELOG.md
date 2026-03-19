# CHANGELOG - PR_PKG_REPRESTAMOS (QA)

> Historial de cambios del paquete principal de représtamos en QA.

---

<!-- Agregar nuevas entradas al inicio -->

## 2026-03-18 | OPT-001 - Optimizacion SQL 227 WORLD_COMPLIANCE
- **Cambio**: Correccion de JOINs ineficientes y COMMIT dentro de loop en cursor CARGAR_WORLD_COMPLIANCE
- **Procedimientos afectados**: PVALIDA_WORLD_COMPLIANCE
- **Motivo**: Eliminacion de 2 TABLE ACCESS FULL (PERSONAS_FISICAS 1.2M filas, PR_SOLICITUD_REPRESTAMO). Cost 18,293 -> 15
- **Detalle**: Ver `historias/optimizaciones/OPT-001_SQL227_WORLD_COMPLIANCE/`

---

## YYYY-MM-DD | Historia #XXX
- **Cambio**: descripcion del cambio
- **Procedimientos afectados**: P_Nombre1, P_Nombre2
- **Motivo**: razon del cambio

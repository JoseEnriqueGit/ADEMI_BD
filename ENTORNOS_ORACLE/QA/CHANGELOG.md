# CHANGELOG - QA

> Registro cronológico de cambios desplegados en el entorno de QA.
> Formato: Fecha | Historia/Ticket | Objetos afectados

---

<!-- Agregar nuevas entradas al inicio -->

## 2026-03-18 | OPT-001 - Optimizacion SQL 227 WORLD_COMPLIANCE
- **Modificado**: PR.PR_PKG_REPRESTAMOS (body)
- **Procedure afectado**: PVALIDA_WORLD_COMPLIANCE
- **Notas**: Correccion de conversion implicita en JOIN a PERSONAS_FISICAS, adicion de CODIGO_EMPRESA en JOIN a PR_SOLICITUD_REPRESTAMO, y COMMIT fuera del loop. Cost de 18,293 a 15. Ver `historias/optimizaciones/OPT-001_SQL227_WORLD_COMPLIANCE/`

---

## YYYY-MM-DD | Historia #XXX - Descripcion
- **Modificado**: SCHEMA.OBJETO (spec/body)
- **Agregado**: SCHEMA.OBJETO
- **Tablas afectadas**: TABLA1, TABLA2
- **Notas**: contexto relevante del cambio

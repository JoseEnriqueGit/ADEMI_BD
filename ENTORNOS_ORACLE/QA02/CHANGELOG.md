# CHANGELOG - QA02

> Registro cronológico de cambios desplegados en el entorno de QA02.
> QA02 es **independiente** de QA: no asumir que comparten código o datos.
> Formato: Fecha | Historia/Ticket | Objetos afectados

---

<!-- Agregar nuevas entradas al inicio -->

## 2026-06-02 | Anti-regresión - Consolidación de copias sombra
- **Movido**: `PA.PKG_TIPO_DOCUMENTO_PKM` `body BACKUP 30-04-2026.SQL` y las variantes
  `CHECK_ESTADO_REPORTE_TEST.sql` / `check_estado_reporte_v1.sql` → `backups/sombras_consolidadas/QA02/`.
- **Notas**: Quedan los canónicos `body.sql`/`spec.sql` y `check_estado_reporte.sql`. Sin cambios en base de datos.

---

## YYYY-MM-DD | Historia #XXX - Descripcion
- **Modificado**: SCHEMA.OBJETO (spec/body)
- **Agregado**: SCHEMA.OBJETO
- **Tablas afectadas**: TABLA1, TABLA2
- **Notas**: contexto relevante del cambio

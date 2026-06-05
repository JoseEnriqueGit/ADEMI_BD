# Historia #419 - Canales Habilitado

## Descripción
Implementación de lógica de canales habilitados para campañas de représtamos.

## Estado
<!-- completado | en progreso -->

## Entorno desplegado
<!-- DESARROLLO | QA | PRODUCCION -->

## Objetos afectados
- **PR.PR_V_ENVIO_REPRESTAMOS** (VISTA) — aquí vive la lógica de canales habilitados:
  ramas `CANAL_CARGA_DIRIGIDA` / `CANAL_CAMPANA_ESPECIAL` y el filtro `CANALES_HABILITADOS`.
  > Corregido el 2026-06-02: esta vista NO estaba listada originalmente aunque la lógica vive en ella.
  > Esa desconexión (la trazabilidad apuntaba al package/job, no a la vista) es la causa raíz #4 del
  > incidente de regresión. Ver `historias/419_CANALES_HABILITADO/promocion/03_INVENTARIO_SEMANTICO.md`.
- PR_PKG_REPRESTAMOS
- JOB_CAMPANA_ESPECIALES
- Tablas de campañas

## Archivos
- `scripts/` - Scripts SQL del cambio
- `evidencia/` - Capturas y prompts de referencia
- `promocion/` - Inventario semántico del objeto (anti-regresión)

# IRD-525 - Gestion Estados Trazabilidad

- Estado: validado_en_qa_pendiente_confirmacion
- Entorno: QA
- Aplicacion APEX: 106
- Pagina APEX: 112
- Fecha: 2026-05-22
- Decision: agregar columnas de trazabilidad al reporte de Gestion de Estados.
- Validacion: SQL validado en Toad y APEX validado luego de remover el sort guardado de Fecha Modificacion.
- Rollback: restaurar el SQL anterior del reporte desde `scripts/00_QUERY_APEX_ANTES_PEGAR_AQUI.sql`.

## Observacion

El query anterior del reporte APEX fue respaldado en `scripts/00_QUERY_APEX_ANTES_PEGAR_AQUI.sql` con el SQL compartido por el usuario.

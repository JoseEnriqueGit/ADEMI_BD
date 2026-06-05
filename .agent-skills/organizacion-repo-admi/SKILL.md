---
name: organizacion-repo-admi
description: Usar para proponer o aplicar organizacion del repo ADEMI_BD, separar produccion, QA02, descartados, diagnosticos y pendientes sin borrar evidencia ni mover historias sin aprobacion.
---

# Organizacion Repo ADEMI_BD

## Objetivo
Ordenar el repo sin perder trazabilidad. La organizacion debe reflejar estado real, no aspiraciones.

## Reglas obligatorias
- Proponer estructura antes de mover carpetas grandes.
- No borrar historias, scripts, handoffs ni evidencia.
- Separar produccion, QA02, descartados, diagnosticos, pendientes y soporte.
- Preservar nombres de OPT, incidentes y casos de negocio.
- No mezclar cambios de organizacion con cambios Oracle.
- Usar `git status --short` antes y despues.
- Si hay cambios ajenos, trabajar alrededor de ellos.
- Mantener la higiene de contexto: `backups/`, `_cuarentena/`, `diff/` y volcados grandes
  (`docs/notas/NOTAS_HISTORICO.md`) son zona fria; localizar por indice, no cargar en bloque.
- Los archivos dudosos o huerfanos van a `_cuarentena/` con su fila en `_cuarentena/INDICE.md`
  (sin borrar ni renombrar hasta confirmar destino con el usuario).

## Estructura recomendada
```text
historias/
  optimizaciones/
    produccion/
    qa02_en_pruebas/
    probados_no_promovidos/
    descartados/
    diagnosticos/
    pendientes_confirmar/
    soporte/
  incidentes/
    abiertos/
    cerrados/
    diagnosticos/
  soporte_qa02/
  _plantillas/
```

## Flujo
1. Inventariar estado actual.
2. Detectar inconsistencias.
3. Proponer mapa destino.
4. Esperar aprobacion para movimientos grandes.
5. Mover preservando archivos.
6. Actualizar README o inventario.
7. Validar con `git status --short`.

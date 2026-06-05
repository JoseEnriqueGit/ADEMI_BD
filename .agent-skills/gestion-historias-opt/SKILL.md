---
name: gestion-historias-opt
description: Usar para clasificar, reorganizar, documentar o consultar historias y optimizaciones OPT del repo ADEMI_BD, incluyendo estados de produccion, QA02, descartados, diagnosticos y pendientes.
---

# Gestion de Historias OPT

## Objetivo
Mantener las historias ordenadas por estado real sin perder evidencia, handoffs ni scripts de validacion.

## Estados canonicos
- `PRODUCCION`
- `QA02_EN_PRUEBAS`
- `PROBADO_NO_PROMOVIDO`
- `DESCARTADO`
- `DIAGNOSTICO`
- `PENDIENTE_CONFIRMAR`

## Reglas obligatorias
- No asumir que una OPT paso a produccion.
- Hasta confirmacion contraria, recordar que solo los 8 indices pasaron a produccion.
- No borrar historias descartadas; moverlas o marcarlas preservando evidencia.
- Proponer estructura antes de mover carpetas grandes.
- Mantener README, handoffs, resultados QA, rollback y scripts juntos con su historia.
- No mezclar incidentes con optimizaciones salvo que la historia lo documente.
- `OPT-020_VISTAS_GARANTIA_REPRESTAMOS` puede marcarse como `DESCARTADO` solo con aprobacion explicita del usuario.

## Higiene de contexto
- Partir de `historias/INVENTARIO.md`; abrir solo la carpeta del caso concreto (su `README.md` y
  `ESTADO.md`), no el arbol completo de `historias/`.
- Tratar `backups/`, `_cuarentena/` y `diff/` como zona fria (no leer salvo orden explicita).
- Arrancar la sesion con `docs/memoria/CONTEXTO_ACTUAL.md` (ver skill `memoria-engram`).

## Flujo
1. Revisar `git status --short`.
2. Identificar historia, estado actual y evidencia.
3. Proponer destino y razon.
4. Mover o marcar solo si el usuario aprobo.
5. Actualizar inventario o README de historias cuando exista.
6. Validar con `git status --short` que no se perdio nada.

## Ejemplos de destinos
- `historias/optimizaciones/produccion/`
- `historias/optimizaciones/qa02_en_pruebas/`
- `historias/optimizaciones/probados_no_promovidos/`
- `historias/optimizaciones/descartados/`
- `historias/optimizaciones/diagnosticos/`
- `historias/optimizaciones/pendientes_confirmar/`

---
name: memoria-engram
description: Usar al iniciar o cerrar una sesion de trabajo en ADEMI_BD para reconstruir contexto y dejar memoria persistente en el repo. Cubre la lectura de CONTEXTO_ACTUAL, la actualizacion de la BITACORA y las reglas de higiene de contexto (que cargar y que NO cargar) para Codex y Claude Code.
---

# Memoria / Engram ADEMI_BD

## Objetivo
La memoria del proyecto vive en el repo (texto plano + git), no en herramientas externas. Esto
permite reconstruir el contexto en cualquier maquina, incluida la PC del trabajo que no puede
instalar software. Esta skill define como arrancar con contexto y como dejar rastro.

## Arranque de sesion (siempre)
1. Leer `docs/memoria/CONTEXTO_ACTUAL.md` (punto de entrada unico).
2. Si la tarea lo pide, abrir `historias/INVENTARIO.md` y SOLO la carpeta del caso concreto.
3. Revisar `git log --oneline -20` y las ultimas entradas de `docs/memoria/BITACORA.md`.

## Cierre de trabajo relevante
- Agregar una entrada al inicio de `docs/memoria/BITACORA.md` usando
  `docs/memoria/_plantillas/ENTRADA_BITACORA.md` (corta: objetivo, hecho, decisiones, pendientes).
- Si cambio el panorama "abierto / vivo en PROD", actualizar `docs/memoria/CONTEXTO_ACTUAL.md`.
- Si cambio el estado de un caso, actualizar `historias/INVENTARIO.md` y el `ESTADO.md` del caso.
- Si se promovio algo a PROD, registrar en `ENTORNOS_ORACLE/Produccion/CHANGELOG.md`.

## Higiene de contexto (carga progresiva)
Cargar poco y relevante. Capas:
- **Caliente (cargar siempre):** `docs/memoria/CONTEXTO_ACTUAL.md`.
- **Tibio (solo el item puntual):** un objeto Oracle, un `README.md`/`ESTADO.md` de UN caso.
- **Frio (NO leer salvo orden explicita):** `backups/`, `_cuarentena/`, `diff/`,
  `ENTORNOS_ORACLE/**` en bloque, y `docs/notas/NOTAS_HISTORICO.md` completo.

Reglas:
- No hacer glob de un schema entero ni abrir volcados de cientos de KB "por las dudas".
- Para `NOTAS_HISTORICO.md`, usar `docs/notas/INDICE_NOTAS_HISTORICO.md` y saltar a la linea exacta.
- Localizar por indice/grep y leer lo puntual; preferir resumir a volcar.

## Reglas obligatorias
- No editar ni borrar entradas pasadas de la BITACORA; solo agregar arriba.
- No duplicar el detalle tecnico del caso en la bitacora; alli va el resumen + punteros.
- Mantener `CONTEXTO_ACTUAL.md` como snapshot (se sobrescribe), no como historial.

## Flujo
1. Arrancar leyendo CONTEXTO_ACTUAL (+ INVENTARIO si aplica).
2. Trabajar cargando solo lo tibio necesario; tratar lo frio como zona vedada.
3. Al cerrar, actualizar CONTEXTO_ACTUAL si cambio el panorama y agregar entrada en BITACORA.
4. Commit por cambio logico (ver skill `git-trazabilidad-proyecto`).

---
name: git-trazabilidad-proyecto
description: Usar cuando una tarea en ADEMI_BD implique cambios de archivos, commits, mensajes de commit, documentacion de cambios, rollback, revision de git status o trazabilidad historica para Codex o Claude Code.
---

# Git Trazabilidad Proyecto

## Objetivo
Mantener cada cambio logico identificable, validado y recuperable. Esta skill protege la memoria del proyecto: que se sepa que cambio, por que, como se valido y como revertirlo.

## Reglas obligatorias
- Ejecutar `git status --short` antes de tocar archivos.
- Identificar cambios ajenos y no revertirlos.
- No usar `git add .`.
- No mezclar historias, incidentes u OPT distintos en el mismo commit.
- Hacer commit por cambio logico cuando el usuario haya pedido registrar cambios o cuando el flujo del proyecto lo requiera.
- Si el worktree ya trae cambios ajenos, stagear solo rutas propias con `git add -- <ruta>`.
- No usar `git reset --hard`, `git checkout --` ni comandos destructivos sin pedido explicito.

## Mensaje de commit
Usar formato:

```text
tipo(alcance): resumen corto
```

Tipos sugeridos:
- `docs`
- `feat`
- `fix`
- `refactor`
- `test`
- `chore`
- `rollback`

Cuando aplique, incluir cuerpo:

```text
Motivo:
- ...

Cambios:
- ...

Validacion:
- ...

Rollback:
- ...

Estado:
- ...

Referencias:
- ...
```

## Flujo
1. Revisar `git status --short`.
2. Delimitar el cambio logico y sus archivos.
3. Aplicar cambios solo en rutas necesarias.
4. Validar con comandos locales o dejar pasos de validacion si dependen de Oracle/Toad.
5. Revisar `git diff -- <rutas>`.
6. Stagear rutas explicitas.
7. Crear commit atomico si corresponde.

## Ejemplos
- Para una nueva skill: `docs(skills): agregar skill de trazabilidad git`.
- Para descartar una OPT: `docs(opt-020): marcar vistas de garantia como descartadas`.
- Para rollback Oracle: `rollback(pr_pkg_represtamos): documentar reversa de cambio QA02`.

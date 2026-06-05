# Plantilla de entrada de BITÁCORA

> Copiar el bloque de abajo al **inicio** de `docs/memoria/BITACORA.md` (más reciente arriba).
> Mantenerlo corto: 5–10 líneas. El detalle técnico va en la historia del caso, no aquí.

```markdown
## YYYY-MM-DD · <Agente: Claude Code / Codex> · <título corto de la sesión>

- **Objetivo:** qué se pidió / qué se buscaba lograr.
- **Hecho:** acciones concretas (1 viñeta por bloque de trabajo).
- **Decisiones:** decisiones tomadas y su razón (lo que un futuro agente necesita saber).
- **Pendientes:** qué quedó abierto / próximos pasos.
- **Archivos tocados:** rutas clave o referencia a `git log`/sha de los commits.
```

## Recordatorios

- Si el trabajo cambió el estado de un caso, actualizar también `historias/INVENTARIO.md` y el
  `ESTADO.md` del caso, y `docs/memoria/CONTEXTO_ACTUAL.md` si cambió el panorama "abierto / vivo".
- Si se promovió algo a PROD, registrar en `ENTORNOS_ORACLE/Produccion/CHANGELOG.md`.
- No editar entradas pasadas de la bitácora; solo agregar.

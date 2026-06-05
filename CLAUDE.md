# CLAUDE.md

Usa `docs/instrucciones_ai/BASE_OPERATIVA.md` como fuente de verdad del proyecto.

## Skills operativas
- La fuente canonica de skills del repo vive en `.agent-skills/`.
- Claude Code puede usar copias sincronizadas en `.claude/skills/` y comandos puente en `.claude/commands/`.
- Cuando una tarea coincida con una skill, leer su `SKILL.md` antes de actuar y aplicar sus reglas.
- Para refrescar los adaptadores, usar `scripts/sync_agent_skills.ps1 -Target Claude -Overwrite`.

## Memoria del proyecto (leer primero)
- Al iniciar la sesión, leer `docs/memoria/CONTEXTO_ACTUAL.md` (estado vivo, casos abiertos, reglas).
- Al cerrar trabajo relevante, agregar una entrada en `docs/memoria/BITACORA.md`.
- Higiene de contexto: no cargar `backups/`, `_cuarentena/`, `diff/`, ni `docs/notas/NOTAS_HISTORICO.md`
  completo salvo orden explícita. Ver skill `memoria-engram`.

## Notas específicas para Claude
- Mantener respuestas en español.
- Si no se especifica entorno, preguntar antes de leer cualquier objeto Oracle.
- Los comandos principales son:
  - `/explicar`
  - `/optimizar`
  - `/comparar_entornos`
  - `/incorporar_objeto`
  - `/contexto` (reconstruir memoria) y `/bitacora` (registrar sesión)
- Los aliases en inglés se conservan por compatibilidad:
  - `/oracle-explain`
  - `/oracle-optimize`
  - `/oracle-compare-environments`
  - `/oracle-incorporate-object`
- Los comandos deben mantenerse mínimos y alineados a la base común.

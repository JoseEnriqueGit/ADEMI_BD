# CLAUDE.md

Usa `docs/instrucciones_ai/BASE_OPERATIVA.md` como fuente de verdad del proyecto.

## Skills operativas
- La fuente canonica de skills del repo vive en `.agent-skills/`.
- Claude Code puede usar copias sincronizadas en `.claude/skills/` y comandos puente en `.claude/commands/`.
- Cuando una tarea coincida con una skill, leer su `SKILL.md` antes de actuar y aplicar sus reglas.
- Para refrescar los adaptadores, usar `scripts/sync_agent_skills.ps1 -Target Claude -Overwrite`.

## Notas específicas para Claude
- Mantener respuestas en español.
- Si no se especifica entorno, preguntar antes de leer cualquier objeto Oracle.
- Los comandos principales son:
  - `/explicar`
  - `/optimizar`
  - `/comparar_entornos`
  - `/incorporar_objeto`
- Los aliases en inglés se conservan por compatibilidad:
  - `/oracle-explain`
  - `/oracle-optimize`
  - `/oracle-compare-environments`
  - `/oracle-incorporate-object`
- Los comandos deben mantenerse mínimos y alineados a la base común.

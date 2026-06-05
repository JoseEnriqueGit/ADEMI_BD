#!/bin/bash
# SessionStart hook — ADEMI_BD
# Inyecta la "memoria del proyecto" al iniciar la sesion para que el agente arranque con contexto.
# Este repo es SQL + Markdown: no instala dependencias, solo apunta a la memoria viva del repo.
set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
CONTEXTO="$ROOT/docs/memoria/CONTEXTO_ACTUAL.md"

if [ -f "$CONTEXTO" ]; then
  MSG="MEMORIA DEL PROYECTO ADEMI_BD: antes de actuar, lee docs/memoria/CONTEXTO_ACTUAL.md (estado vivo en PROD, casos abiertos, pendientes, reglas duras e higiene de contexto). El diario de sesiones esta en docs/memoria/BITACORA.md; al cerrar trabajo relevante, agrega una entrada. Respeta las zonas frias: no cargues backups/, _cuarentena/, diff/ ni docs/notas/NOTAS_HISTORICO.md completo salvo orden explicita."
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$MSG"
fi

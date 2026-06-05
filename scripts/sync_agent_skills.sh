#!/bin/bash
# Sincroniza las skills canonicas de .agent-skills/ hacia los adaptadores de Claude Code y Codex.
# Equivalente portable (Bash) de sync_agent_skills.ps1, para maquinas Linux/web sin PowerShell.
#
# Uso:
#   scripts/sync_agent_skills.sh [--target all|claude|codex] [--overwrite]
# Por defecto: --target all, sin sobrescribir si el destino difiere (aborta y avisa).
set -euo pipefail

TARGET="all"
OVERWRITE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --target=*) TARGET="${1#*=}"; shift ;;
    --overwrite) OVERWRITE=1; shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
  esac
done

case "$TARGET" in
  all|claude|codex) ;;
  *) echo "Target invalido: $TARGET (use all|claude|codex)" >&2; exit 2 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CANONICAL_ROOT="$REPO_ROOT/.agent-skills"

if [ ! -d "$CANONICAL_ROOT" ]; then
  echo "No existe la carpeta canonica de skills: $CANONICAL_ROOT" >&2
  exit 1
fi

sync_skill_set() {
  local dest_root="$1" label="$2"
  mkdir -p "$dest_root"
  local src_skill dest_skill skill_name
  for skill_dir in "$CANONICAL_ROOT"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    src_skill="$skill_dir/SKILL.md"
    dest_skill="$dest_root/$skill_name/SKILL.md"
    if [ ! -f "$src_skill" ]; then
      echo "La skill $skill_name no tiene SKILL.md" >&2
      exit 1
    fi
    mkdir -p "$dest_root/$skill_name"
    if [ -f "$dest_skill" ] && [ "$OVERWRITE" -ne 1 ]; then
      if ! cmp -s "$src_skill" "$dest_skill"; then
        echo "La skill $skill_name ya existe en $label y difiere. Reejecuta con --overwrite." >&2
        exit 1
      fi
    fi
    cp -f "$src_skill" "$dest_skill"
    echo "Sincronizada $skill_name -> $label"
  done
}

if [ "$TARGET" = "all" ] || [ "$TARGET" = "claude" ]; then
  sync_skill_set "$REPO_ROOT/.claude/skills" "Claude Code"
fi

if [ "$TARGET" = "all" ] || [ "$TARGET" = "codex" ]; then
  sync_skill_set "${HOME}/.codex/skills" "Codex"
fi

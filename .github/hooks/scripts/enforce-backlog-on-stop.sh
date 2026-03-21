#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
backlog_rel="docs/agent-backlog.md"
backlog_path="$repo_root/$backlog_rel"

if [[ ! -f "$backlog_path" ]]; then
  cat <<'JSON'
{
  "continue": false,
  "stopReason": "No existe docs/agent-backlog.md",
  "systemMessage": "No se puede cerrar: falta la bitacora requerida en docs/agent-backlog.md."
}
JSON
  exit 2
fi

unstaged_changed=1
staged_changed=1

if git -C "$repo_root" diff --quiet -- "$backlog_rel"; then
  unstaged_changed=0
fi

if git -C "$repo_root" diff --cached --quiet -- "$backlog_rel"; then
  staged_changed=0
fi

if [[ "$unstaged_changed" -eq 0 && "$staged_changed" -eq 0 ]]; then
  cat <<'JSON'
{
  "continue": false,
  "stopReason": "Backlog sin actualizacion",
  "systemMessage": "No se puede cerrar: actualiza docs/agent-backlog.md con entrada postmortem del trabajo, incluyendo comandos ejecutados y resultados de tests."
}
JSON
  exit 2
fi

cat <<'JSON'
{
  "continue": true,
  "systemMessage": "Backlog detectado con cambios. Cierre permitido."
}
JSON

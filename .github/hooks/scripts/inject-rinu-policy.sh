#!/usr/bin/env bash
set -euo pipefail

cat <<'JSON'
{
  "continue": true,
  "systemMessage": "Rinu policy activa: 1) Disenar el flujo antes de implementar. 2) Si hay ambiguedad, preguntar antes de continuar. 3) No cerrar tarea sin flujo completo end-to-end. 4) Registrar backlog postmortem por cada hito importante en docs/agent-backlog.md, incluyendo comandos y tests."
}
JSON

#!/usr/bin/env bash
set -euo pipefail

active=false

for daemon in backend frontend; do
  status="$(pitchfork status --json "$daemon" 2>/dev/null || true)"

  if printf '%s\n' "$status" | grep -Eq '"status"[[:space:]]*:[[:space:]]*"(waiting|starting|running|stopping|errored)"'; then
    active=true
  fi
done

if $active; then
  pitchfork stop backend frontend
fi

docker compose -f docker-compose.db.yml down

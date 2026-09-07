#!/usr/bin/env bash
# Compatibility wrapper for the root mise task surface.
# Usage: ./dev.sh [setup|start|serve|stop|reset|logs|db-logs|status|check|test]

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if ! command -v mise >/dev/null 2>&1; then
  printf '%s\n' "mise is required. Install it from https://mise.jdx.dev, then run: mise install" >&2
  exit 1
fi

case "${1:-help}" in
  setup)
    exec mise run setup
    ;;
  start)
    exec mise run db:up
    ;;
  serve|dev)
    exec mise run dev
    ;;
  stop)
    exec mise run stop
    ;;
  reset)
    exec mise run reset
    ;;
  logs)
    exec mise run dev:logs
    ;;
  db-logs)
    exec mise run db:logs
    ;;
  status)
    exec mise run status
    ;;
  check)
    exec mise run check
    ;;
  test)
    exec mise run test
    ;;
  help)
    cat <<'EOF'
Development tasks

Usage: ./dev.sh [command]

Commands:
  setup     Install dependencies, initialize the database, and install hooks
  start     Start PostgreSQL and wait until it is healthy
  serve     Start PostgreSQL, Phoenix, and Vite through Pitchfork
  stop      Stop application services and PostgreSQL
  reset     Drop, recreate, migrate, and seed the local database
  logs      Follow Phoenix and Vite logs
  db-logs   Follow PostgreSQL logs
  status    Show database and application service status
  check     Run backend and frontend quality checks
  test      Run backend, frontend, and browser tests
  help      Show this help message

The canonical equivalent commands are `mise run <task>`. Use
`mise tasks` to see the complete task list.
EOF
    ;;
  *)
    printf 'Unknown command: %s\n\n' "$1" >&2
    mise tasks
    exit 2
    ;;
esac

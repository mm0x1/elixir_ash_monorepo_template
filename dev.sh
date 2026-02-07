#!/bin/bash
# Development helper script
# Usage: ./dev.sh [command]

set -e

DB_COMPOSE="docker-compose.db.yml"

case "${1:-help}" in
  start)
    echo "🚀 Starting development environment..."
    echo ""
    echo "1️⃣  Starting database..."
    docker compose -f "$DB_COMPOSE" up -d

    echo ""
    echo "✅ Database started!"
    echo ""
    echo "Next steps:"
    echo "  Terminal 1: cd backend && mix phx.server"
    echo "  Terminal 2: cd frontend && npm run dev"
    echo ""
    echo "Or run: ./dev.sh serve"
    ;;

  serve)
    echo "🚀 Starting backend and frontend..."
    echo ""

    # Ensure database is running
    docker compose -f "$DB_COMPOSE" up -d

    # Start backend in background
    echo "Starting backend..."
    cd backend
    mix phx.server &
    BACKEND_PID=$!
    cd ..

    # Wait a moment for backend to start
    sleep 2

    # Start frontend in background
    echo "Starting frontend..."
    cd frontend
    npm run dev &
    FRONTEND_PID=$!
    cd ..

    echo ""
    echo "✅ Services started!"
    echo "   Backend:  http://localhost:4000"
    echo "   Frontend: http://localhost:5173"
    echo ""
    echo "Press Ctrl+C to stop all services"

    # Trap Ctrl+C to kill both processes
    trap "kill $BACKEND_PID $FRONTEND_PID; docker compose -f $DB_COMPOSE stop; exit" INT

    # Wait for both processes
    wait
    ;;

  stop)
    echo "🛑 Stopping development environment..."
    docker compose -f "$DB_COMPOSE" down
    echo "✅ Database stopped!"
    ;;

  reset)
    echo "♻️  Resetting database..."
    cd backend
    mix ecto.reset
    cd ..
    echo "✅ Database reset complete!"
    ;;

  logs)
    docker compose -f "$DB_COMPOSE" logs -f
    ;;

  status)
    echo "📊 Service status:"
    echo ""
    docker compose -f "$DB_COMPOSE" ps
    echo ""
    if lsof -ti:4000 > /dev/null 2>&1; then
      echo "✅ Backend running on port 4000"
    else
      echo "❌ Backend not running"
    fi

    if lsof -ti:5173 > /dev/null 2>&1; then
      echo "✅ Frontend running on port 5173"
    else
      echo "❌ Frontend not running"
    fi
    ;;

  help|*)
    cat << EOF
Development Helper Script

Usage: ./dev.sh [command]

Commands:
  start     Start database only (you start backend/frontend manually)
  serve     Start database + backend + frontend (all in background)
  stop      Stop database
  reset     Reset database (drop, create, migrate, seed)
  logs      Show database logs
  status    Check status of all services
  help      Show this help message

Examples:
  # Option 1: Start DB, run services manually
  ./dev.sh start
  cd backend && mix phx.server       # Terminal 1
  cd frontend && npm run dev         # Terminal 2

  # Option 2: Start everything at once
  ./dev.sh serve

  # Reset database
  ./dev.sh reset

  # Stop database
  ./dev.sh stop
EOF
    ;;
esac

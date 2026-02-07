# Elixir Ash Monorepo Template

A modern full-stack monorepo template with Phoenix/Ash backend and SvelteKit frontend.

## Stack

- **Backend**: Phoenix 1.8 + Ash 3.0 + PostgreSQL
- **Frontend**: SvelteKit 2 + Svelte 5 + TypeScript + Tailwind CSS 4
- **Data Layer**: ash_typescript (generates TypeScript client from Ash resources)
- **Auth**: Hybrid token (JWT access tokens + DB-backed refresh tokens)

## Quick Start

### 1. Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit .env and update secrets:
# - SECRET_KEY_BASE (run: cd backend && mix phx.gen.secret)
# - TOKEN_SIGNING_SECRET (run: cd backend && mix phx.gen.secret 32)
```

### 2. Start Database

```bash
# Start PostgreSQL in Docker
docker compose -f docker-compose.db.yml up -d

# Check it's running
docker ps
```

### 3. Setup Backend

```bash
cd backend

# Install dependencies and setup database
mix setup

# Start Phoenix server
mix phx.server
# OR with IEx shell for debugging:
iex -S mix phx.server
```

Backend will be running at http://localhost:4000

### 4. Setup Frontend

```bash
# In a new terminal
cd frontend

# Install dependencies
npm install

# Start Vite dev server
npm run dev
```

Frontend will be running at http://localhost:5173

## Development Workflow

### Code Generation

```bash
# After changing Ash resources, regenerate migrations
cd backend
mix ash.codegen

# Regenerate TypeScript client for frontend
mix ash_typescript.generate
```

### Database Commands

```bash
cd backend

# Reset database (drop, create, migrate, seed)
mix ecto.reset

# Run migrations
mix ecto.migrate

# Drop database
mix ecto.drop
```

### Code Quality

```bash
# Backend
cd backend
mix quality           # Run all checks
mix quality.fix       # Auto-fix issues
mix test              # Run tests

# Frontend
cd frontend
npm run lint          # Lint code
npm run lint:fix      # Auto-fix linting
npm run check         # Type checking
```

## Architecture

This is a **monorepo** with **API-only backend** and **SPA frontend**:

- Backend exposes RPC endpoints via `ash_typescript`
- Frontend consumes generated TypeScript client
- No server-side rendering (pure SPA)
- Auth via hybrid tokens (access + refresh)

### Key Patterns

1. **Generated types are PRIVATE** - Only `$lib/api/` imports from `$lib/generated/`
2. **API boundary** - Components use UI types from `$lib/types/`, not DTOs
3. **Svelte 5 runes** - Use `$state`, `$derived`, `$effect` (not legacy stores)
4. **Actor-based policies** - All Ash actions require `actor: current_user`

See [CLAUDE.md](./CLAUDE.md) for detailed documentation.

## Docker Options

### Option 1: Database Only (Recommended)

Fast iteration with native dev servers:

```bash
docker compose -f docker-compose.db.yml up -d
cd backend && mix phx.server
cd frontend && npm run dev
```

### Option 2: Full Docker Stack

Closer to production, slower rebuilds:

```bash
docker compose up
```

## Project Structure

```
/
├── backend/              # Phoenix/Ash API
│   ├── lib/
│   │   ├── template_app/
│   │   │   └── domains/  # Ash domains (DDD)
│   │   └── template_app_web/
│   │       └── controllers/
│   └── config/
├── frontend/             # SvelteKit SPA
│   └── src/
│       ├── lib/
│       │   ├── generated/  # ash_typescript output (PRIVATE)
│       │   ├── api/        # API wrappers (DTO → UI)
│       │   ├── types/      # UI types
│       │   └── components/
│       └── routes/
└── docker-compose.db.yml  # Database only
```

## Troubleshooting

### Database Connection Failed

```bash
# Check database is running
docker ps

# Restart database
docker compose -f docker-compose.db.yml restart

# Check logs
docker compose -f docker-compose.db.yml logs
```

### Port Already in Use

```bash
# Backend (4000)
lsof -ti:4000 | xargs kill -9

# Frontend (5173)
lsof -ti:5173 | xargs kill -9

# Database (5432)
docker compose -f docker-compose.db.yml down
```

### TypeScript Types Out of Sync

```bash
# Regenerate TypeScript client
cd backend
mix ash_typescript.generate
```

## Documentation

- [CLAUDE.md](./CLAUDE.md) - Complete development guide
- [MIGRATION_PLAN.md](./MIGRATION_PLAN.md) - Architecture decisions

## License

MIT

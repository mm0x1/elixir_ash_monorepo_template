# Elixir Ash Monorepo Template

Phoenix/Ash backend + SvelteKit frontend with a generated TypeScript data layer.

## Stack

- **Backend**: Phoenix 1.8, Ash 3.0, PostgreSQL
- **Frontend**: SvelteKit 2, Svelte 5, TypeScript, Tailwind CSS 4
- **Data layer**: ash_typescript — generates TypeScript client, types, and Zod schemas from Ash resources
- **Auth**: JWT access tokens (15 min) + DB-backed refresh tokens (7 days, HttpOnly cookie)

## Quick start

```bash
# 1. Copy and configure secrets
cp .env.example .env

# 2. Start database
docker compose -f docker-compose.db.yml up -d

# 3. Backend
cd backend && mix setup && mix phx.server   # localhost:4000

# 4. Frontend (new terminal)
cd frontend && npm install && npm run dev   # localhost:5173
```

## Common commands

```bash
# Backend
mix ash.codegen              # Generate migrations after changing Ash resources
mix ash_typescript.codegen   # Regenerate TypeScript client (run after backend changes)
mix test                     # Run tests
mix quality                  # Format + Credo + compile check
mix quality.fix              # Auto-fix formatting

# Frontend
npm run check   # Type checking (svelte-check)
npm run lint    # ESLint
```

## Architecture

```
backend/
  lib/template_app/domains/    # Ash domains (DDD)
  lib/template_app_web/        # Phoenix controllers, plugs, router

frontend/src/lib/
  generated/   # ash_typescript output — PRIVATE, only api/ imports this
  api/         # Public API boundary: DTO → UI type transforms, auth headers
  auth/        # Token store, refresh coordination, auth state
  types/       # UI types consumed by components
```

Key rules:
- Components never import from `$lib/generated/` (ESLint enforced)
- All Ash actions must resolve the actor — `ValidateAccessToken` calls `Ash.PlugHelpers.set_actor/2`
- Svelte 5 runes only: `$state`, `$derived`, `$effect`, `$props`

See [CLAUDE.md](./CLAUDE.md) for patterns, gotchas, and detailed conventions.

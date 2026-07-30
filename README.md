# Elixir Ash Monorepo Template

Phoenix/Ash REST API backend + SvelteKit SPA frontend.

## Stack

- **Backend**: Phoenix 1.8, Ash 3.x, PostgreSQL — plain REST/JSON endpoints
- **Frontend**: SvelteKit 2, Svelte 5, TypeScript, Tailwind CSS 4
- **Auth**: username/password (Argon2) with hybrid tokens — JWT access tokens (15 min) + DB-backed refresh tokens (7 days, HttpOnly cookie); password reset via single-use, expiring recovery codes (no email)

## Quick start

```bash
# 0. Install tool versions (Elixir, Erlang, Node) — requires mise (https://mise.jdx.dev)
mise install

# 1. Copy and configure secrets
cp .env.example .env

# 2. Start database
docker compose -f docker-compose.db.yml up -d

# 3. Backend
cd backend && mix setup && mix phx.server   # localhost:4000

# 4. Frontend (new terminal)
cd frontend && npm install && npm run dev   # localhost:5173
```

## TypeScript setup

The project uses two TypeScript packages:
- `typescript` (6.x) — the compiler used by Vite/SvelteKit
- `@typescript/native` (7.x, aka `tsgo`) — used only for type-checking via `svelte-check --tsgo` for speed

To revert to standard TS type-checking: change the `"check"` script in `frontend/package.json` to remove `--tsgo`, then uninstall `@typescript/native`.

## Architecture

```
backend/
  lib/template_app/accounts/   # Accounts domain — Ash resources, actions, changes, validations
  lib/template_app_web/        # Phoenix controllers, plugs, router (API-only)

frontend/src/lib/
  features/     # Domain code (e.g. accounts: API wrappers, auth store, UI types)
  shared/       # Cross-cutting infra: HTTP client, token store, components
tests/          # Vitest unit/integration  ·  e2e/  Playwright specs
```

Key rules:

- One-way dependency: `features → shared` (ESLint enforced)
- All Ash actions must resolve the actor — `ValidateAccessToken` calls `Ash.PlugHelpers.set_actor/2`
- Svelte 5 runes only: `$state`, `$derived`, `$effect`, `$props`

See [AGENTS.md](./AGENTS.md) (agent guide; `CLAUDE.md` is a symlink to it) for patterns, gotchas,
and detailed conventions. Backend package usage rules live in
[backend/AGENTS.md](./backend/AGENTS.md). Agent tooling: Tidewave + HexDocs MCP servers (`.mcp.json`)
and `usage_rules` (`backend/mix.exs`).

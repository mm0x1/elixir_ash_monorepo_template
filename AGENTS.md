# Agent Guide

Guidance for Claude Code and other coding agents working in this repository.
`CLAUDE.md` is a symlink to this file — edit `AGENTS.md`, not the symlink.

**Read `.claude/conventions.md` before writing code.**

## Agent tooling

This template is set up for AI-assisted development:

- **Backend usage rules** — `backend/AGENTS.md` (symlinked as `backend/CLAUDE.md`) holds
  package rules synced from deps via `mix usage_rules.sync` (config in `backend/mix.exs`). Consult it
  before Ash/Phoenix/Elixir work. Re-sync after changing deps.
- **Tidewave MCP** (dev) — runtime tools against the running app (IEx eval, SQL, Ecto schema
  introspection, version-accurate docs). Mounted in `endpoint.ex` at `/tidewave/mcp`; configured in
  `.mcp.json`. Start `mix phx.server` first.
- **HexDocs MCP** — semantic search over versioned HexDocs for deps in `mix.lock` (`.mcp.json`).

## Stack

- **Backend** (`backend/`): Phoenix 1.8, Ash 3.x, PostgreSQL — plain REST/JSON, no RPC layer
- **Frontend** (`frontend/`): SvelteKit 2, Svelte 5, TypeScript, Vite, Tailwind CSS 4 — SPA.
  Type-checking uses TypeScript 7 (`tsgo`) via svelte-check `--tsgo`; `typescript` (6.x) stays the
  primary compiler and `@typescript/native` provides TS7 (see `frontend/package.json`).
- **Auth**: username/password (Argon2) with hybrid tokens; single-use, expiring recovery codes for
  password reset (no email)

## Commands

```bash
docker compose -f docker-compose.db.yml up -d   # Start DB (required for backend)

# Backend (in backend/)
mix setup            # Install deps, create + migrate + seed DB
mix phx.server       # Run API on localhost:4000  (iex -S mix phx.server for a shell)
mix ash.codegen      # Generate migrations after changing Ash resources
mix test             # Tests (DB must be up)
mix quality          # Format + Credo --strict + compile check (quality.fix to auto-fix)

# Frontend (in frontend/)
npm install
npm run dev          # Vite dev server on localhost:5173
npm run check        # svelte-check (types, via tsgo/TS7)
npm run lint         # ESLint
npm run test:unit    # Vitest unit + integration (jsdom, MSW)
npm run test:e2e     # Playwright E2E (network mocked, never a live backend)
```

Tool versions are pinned in `mise.toml` (`mise install` to provision).

## Structure

```
backend/lib/template_app/
  accounts/                    # Accounts domain
    resources/                 #   user.ex, token.ex, refresh_token.ex
    changes/ validations/      #   custom Ash changes + validations
    accounts.ex               #   domain module + code interfaces
  application.ex config.ex repo.ex secrets.ex
backend/lib/template_app_web/
  controllers/                 # auth_controller, account_controller, health_controller
  plugs/                       # validate_access_token, ensure_authenticated, ensure_admin
  helpers/                     # user_serializer, api_response (shared JSON shaping)
  router/router.ex             # API routes (+ /admin, /dev in dev only)

frontend/src/lib/
  features/accounts/           # api/ (REST wrappers), auth/ (store + refresh), types/
  shared/                      # api/ (HTTP client), auth/ (token store), components/, stores/
frontend/src/routes/           # SvelteKit pages (auth/, profile/, dev/)
frontend/tests/  frontend/e2e/ # Vitest unit/integration  ·  Playwright specs
```

## Auth & API

REST endpoints (see `router.ex`): public `POST /auth/{login,register,refresh,request-reset,reset-password}`; token-gated `POST /auth/{logout,logout_all}`, `GET /auth/me`, and `/account/{username,recovery-codes,convert}`.

| Token | Lifetime | Storage | Validation |
|-------|----------|---------|------------|
| Access | 15 min | Svelte store (memory) | stateless JWT, every request |
| Refresh | 7 days | HttpOnly cookie | DB-backed, only `/auth/refresh` |

The frontend's `features/accounts/api/*` wrappers use `authenticatedFetch` (from `auth/refresh.ts`) which injects auth headers and retries once on 401 after refreshing the access token. Backend DTOs (snake_case) are transformed into UI types via a shared `toUser()` in `types/transforms.ts`.

## Critical rules

1. **Resolve the actor for Ash** — `ValidateAccessToken` must call `Ash.PlugHelpers.set_actor(conn, user)` (not just `assign`). Without it, update/create/destroy actions return Forbidden (reads pass via `authorize_if always()`).
2. **Policies are deny-by-default** — explicitly allow each action. `action(:read)` matches only the default `:read`; use `action_type(:read)` to cover named read actions.
3. **`features → shared` is one-way** — shared code never imports from `features/` (ESLint enforced).
4. **API wrappers use `authenticatedFetch`** — components consume UI types, never raw backend shapes. Authenticated requests go through `authenticatedFetch` (auto-injects auth headers, retries on 401). Public endpoints (login, register, refresh) use raw `fetch`.
5. **Svelte 5 runes in components** — `$state`, `$derived`, `$effect`, `$props` (not legacy stores).

## Patterns

```elixir
# Ash resource (backend/lib/template_app/<domain>/resources/thing.ex)
defmodule TemplateApp.Accounts.Resources.Thing do
  use Ash.Resource, domain: TemplateApp.Accounts, data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do; table "things"; repo TemplateApp.Repo; end
  attributes do; uuid_primary_key :id; attribute :name, :string, allow_nil?: false; timestamps(); end
  actions do; defaults [:read, :destroy]; create :create do; accept [:name]; end; end
  policies do; policy action_type(:read), authorize_if: always(); end
end
```

```typescript
// REST API wrapper (frontend/src/lib/features/accounts/api/accounts.ts)
import { API_URL, ApiError } from '$lib/shared/api/client';
import { authenticatedFetch } from '$lib/features/accounts/auth/refresh';
import { toUser } from '$lib/features/accounts/types';

export async function updateUsername(_userId: string, username: string): Promise<User> {
  const res = await authenticatedFetch(`${API_URL}/account/username`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username })
  });
  if (!res.ok) throw new ApiError(/* mapped errors */, res.status);
  return toUser((await res.json()).user);
}
```

## Testing

- **Backend**: real Ash actions / real controllers against the Ecto sandbox — never mock the code under test. Controller tests that drive update/destroy actions (`Ash.bulk_update`) or `manage_relationship` must be `async: false` (shared sandbox). Reuse `test/support/user_fixtures.ex`.
- **Frontend**: assert on user-visible output, never internals. Network is the only thing mocked — MSW (`tests/support/`) for integration, `page.route` for Playwright. Shared fixtures in `tests/support/fixtures.ts`.

## Docs

| File | Purpose |
|------|---------|
| `AGENTS.md` (this file, `CLAUDE.md` → symlink) | Monorepo overview for agents |
| `backend/AGENTS.md` (`backend/CLAUDE.md` → symlink) | Backend guide + synced package usage rules |
| `.claude/conventions.md` | Coding style rules (read before writing) |
| `README.md` | Human-facing quick start |

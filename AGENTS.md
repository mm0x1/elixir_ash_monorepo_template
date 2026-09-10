# Agent Guide

Guidance for Claude Code and other coding agents working in this repository.
`CLAUDE.md` is a symlink to this file. Edit `AGENTS.md`, not the symlink.

## Scope and Loading

- This file defines shared monorepo rules and applies to both projects.
- `backend/AGENTS.md` applies to backend work and contains generated package references.
- `frontend/AGENTS.md` applies to frontend work.
- When working from the repository root, explicitly read the nested guide for the project being changed. OpenCode does not recursively follow file references in prose.
- Keep shared rules here and project-specific rules in the nearest scoped guide. Do not create a second conventions file.

## Stack

- **Backend** (`backend/`): Phoenix 1.8, Ash 3.x, PostgreSQL, REST/JSON API, and a development-only browser/admin surface.
- **Frontend** (`frontend/`): SvelteKit 2, Svelte 5, TypeScript, Vite, Tailwind CSS 4, and a static SPA build.
- **Authentication**: username/password with Argon2, short-lived bearer access tokens, database-backed refresh tokens, and one-time recovery codes. There is no email flow.
- **Tooling**: Elixir, Erlang, Node.js, and Lefthook versions are pinned in `mise.toml`; frontend npm and Node requirements are also declared in `frontend/package.json`.

## Canonical Workflows

Run these from the repository root:

```bash
mise install
mise run setup       # local dependencies, database setup, seeds, and hooks
mise run tilt        # PostgreSQL, Phoenix, Vite, and the Tilt UI
mise run check       # backend quality, codegen, frontend check/lint/format
mise run test        # backend, frontend unit, and browser tests
mise run build       # backend compile and frontend build
```

Database tasks:

```bash
mise run db:up
mise run db:logs
mise run db:down
mise run reset        # destructive: drops, recreates, migrates, and reseeds local data
```

The reset task is local-development-only. Verify the database configuration before running it. Never run setup, reset, seeds, or Tidewave against production or a shared database.

Backend commands run from `backend/`:

```bash
mix setup                         # local deps, database setup, and development seeds
mix quality                       # format check, Credo, and warnings-as-errors compilation
mix test                          # database-backed tests; PostgreSQL must be running
mix codegen.dev                   # iterate on Ash changes with development migrations
mix ash.codegen add_descriptive_name
mix codegen.check                 # verify resources, migrations, and snapshots are synchronized
mix ash.migrate                   # apply reviewed migrations
mix sobelow --skip                # security scan; review findings rather than ignoring them
```

After changing Ash resources, use `mix codegen.dev` during iteration or a named `mix ash.codegen` command for a final migration. Review both `backend/priv/repo/migrations/` and `backend/priv/resource_snapshots/` before applying or committing generated changes.

Frontend commands run from `frontend/`:

```bash
npm ci
npm run check
npm run lint
npm run format:check
npm run build
npm run test:unit
npm run test:e2e
npm run test
```

Install the Playwright browser when setting up a new machine:

```bash
npx playwright install chromium
```

Do not run watch or UI-mode test commands as agent verification. They are interactive commands for a human developer.

## Agent Tooling and Safety

- OpenCode MCP servers are configured in the project `opencode.json`. The legacy `.mcp.json` is retained only for clients that use that schema.
- Tidewave connects to the development Phoenix endpoint at `/tidewave/mcp`. Start Phoenix first. It provides privileged IEx and SQL access and must remain local-development-only. The project OpenCode URL targets the default `PORT=4000`; update `opencode.json` when using a custom backend port.
- HexDocs MCP is configured for the backend dependency context. Use it for version-accurate dependency documentation rather than guessing APIs.
- `mix setup` and the repository seed scripts create predictable development credentials. Never reuse them in production.
- Never expose `VITE_*` variables as secrets. Vite bundles them into browser code at build time. Signing keys, passwords, database credentials, and private API keys do not belong in frontend environment variables.
- Never use `authorize?: false` to repair a policy failure or based on request input. Use the actor and explicit policies; reserve bypasses for documented internal operations, seeds, or tests.
- Never commit `.env`, generated secrets, credentials, or local database data.

## Repository Structure

```text
backend/lib/template_app/accounts/       # Ash domain, resources, changes, validations
backend/lib/template_app_web/             # REST controllers, plugs, serializers, router
backend/test/                             # ExUnit, Ecto sandbox, controller tests
backend/priv/repo/migrations/             # reviewed database migrations
backend/priv/resource_snapshots/          # Ash resource snapshots
frontend/src/lib/features/<name>/         # feature API, auth, DTO/UI types
frontend/src/lib/shared/                  # HTTP client, auth primitives, shared components
frontend/src/routes/                      # client-side Svelte routes
frontend/tests/                           # Vitest unit/integration tests
frontend/e2e/                             # Playwright browser tests
```

## Authentication and API Contract

The access token is a 15-minute bearer JWT held in the frontend memory store. It contains the user id and token version; authenticated requests also load the user and compare the token version with current database state.

Refresh tokens are seven-day, database-backed tokens stored in an HttpOnly cookie. Refresh rotates the old token, logout removes the current refresh token, and logout-all increments the user token version to invalidate existing sessions.

Public REST routes:

| Method | Path |
|--------|------|
| `POST` | `/auth/login`, `/auth/register`, `/auth/refresh`, `/auth/reset-password` |
| `GET` | `/health` |

Authenticated REST routes:

| Method | Path |
|--------|------|
| `POST` | `/auth/logout`, `/auth/logout_all` |
| `GET` | `/auth/me` |
| `PATCH` | `/account/username` |
| `POST` | `/account/recovery-codes`, `/account/convert` |

The development-only browser routes under `/dev` and `/admin` use a separate AshAuthentication browser session. Do not treat them as bearer-token REST endpoints.

Backend REST controller responses should use `TemplateAppWeb.Helpers.ApiResponse` for ordinary success and domain-error responses. Health checks, authentication/rate-limit plugs, browser routes, and development/admin routes are explicit exceptions where direct framework responses are intentional.

Frontend feature API wrappers use `api.get/post/patch/put/delete` from `frontend/src/lib/shared/api/client.ts`. Authenticated feature calls pass `authenticatedFetch`. The refresh, logout, and retry coordinator use raw `fetch` intentionally because they implement the authentication transport boundary.

Backend DTOs are transformed into frontend UI types at the feature API boundary. Components should not consume raw backend shapes. Keep the dependency direction one-way: `features -> shared`; shared code must not import from features.
Password recovery uses codes generated by an authenticated user at `/account/recovery-codes`. There is no username-only reset request, email delivery, or self-service recovery path after all stored codes are lost.

## Cross-Stack Rules

- Every Ash operation must have the correct actor. `ValidateAccessToken` must call `Ash.PlugHelpers.set_actor(conn, user)`, not merely assign the user to the connection.
- Ash policies are deny-by-default. Allow each action explicitly; use `action_type(:read)` when named read actions must be covered.
- Prefer named Ash actions and domain code interfaces over generic CRUD calls from web modules.
- Pattern match on function heads when that makes the code clearer; use `with` for chained `{:ok, _}` / `{:error, _}` operations.
- Prefer `type` over `interface`, `readonly` type properties, named exports, and `??` for nullable defaults.
- Use Svelte 5 runes in components: `$state`, `$derived`, `$effect`, and `$props`.
- Keep serializers pure and shape responses explicitly. Do not return raw Ash structs from JSON endpoints.
- Do not add runtime response schemas without a concrete requirement; the monorepo DTO boundary is the current contract.

## Testing Rules

- Backend tests exercise real Ash actions and controllers against the Ecto sandbox. Do not mock the code under test.
- Controller tests involving Ash processes, `Ash.bulk_update`, or relationship management use `async: false` when required by the shared sandbox setup.
- Frontend unit tests use Vitest, jsdom, and MSW. Prefer user-visible assertions; narrow assertions on navigation, auth cleanup, downloads, and browser APIs are acceptable when those outcomes are not directly visible.
- Playwright builds the SPA and serves it through `frontend/scripts/serve-spa.mjs`, a `sirv` single-page fallback server on port 4173. E2E tests mock network calls with `page.route()` and never use a live backend.
- Do not edit or commit `.svelte-kit/`, `build/`, Playwright reports, test results, or other generated frontend output.

## Documentation Files

| File | Purpose |
|------|---------|
| `AGENTS.md` (`CLAUDE.md -> AGENTS.md`) | Shared monorepo rules and cross-stack contract |
| `backend/AGENTS.md` (`backend/CLAUDE.md -> AGENTS.md`) | Backend-specific rules and generated package references |
| `frontend/AGENTS.md` (`frontend/CLAUDE.md -> AGENTS.md`) | Frontend-specific rules and workflows |
| `README.md` | Human-facing setup and product documentation |

# Elixir Ash Monorepo Template

Phoenix/Ash REST API backend + SvelteKit SPA frontend.

## Stack

- **Backend**: Phoenix 1.8, Ash 3.x, PostgreSQL — plain REST/JSON endpoints
- **Frontend**: SvelteKit 2, Svelte 5, TypeScript, Tailwind CSS 4
- **Auth**: username/password (Argon2) with hybrid tokens — JWT access tokens (15 min) + DB-backed refresh tokens (7 days, HttpOnly cookie); password reset via single-use, expiring recovery codes (no email)

## Quick start

```bash
# Install the shared development tools (requires mise: https://mise.jdx.dev)
mise install

# Optional: create a root env file for local overrides.
# The defaults work without this file.
cp .env.example .env

# Start PostgreSQL, install dependencies, prepare the database and hooks, and
# launch Phoenix and Vite in the Tilt UI. The task installs the pinned local
# Tilt binary when needed.
mise run tilt
```

The app is available at http://127.0.0.1:5173 and the API at
http://127.0.0.1:4000. Vite proxies local `/auth`, `/account`, and `/health`
requests to Phoenix, so `VITE_API_URL` is not needed for local development.

Tilt runs setup as each dependent resource starts: it waits for PostgreSQL,
prepares the backend before Phoenix, and installs frontend dependencies before
Vite. Open the Tilt UI to follow filtered application and database logs,
inspect readiness, and open the application endpoints. Press `Ctrl+C` once;
the lifecycle wrapper stops the native services and runs `tilt down` for the
PostgreSQL container while retaining its named volume. If the wrapper is
  forcibly terminated, recover with `mise exec tilt@0.37.7 -- tilt down`.

`mise run setup` remains available for one-shot dependency, migration, seed,
and hook preparation without starting application servers. Use `mise run
db:up`, `mise run db:down`, and `mise run db:logs` for database-only work.

Useful development tasks:

```bash
mise tasks                         # List all tasks
mise run tilt                      # Start the recommended Tilt workflow
mise run setup                     # One-shot dependency/database preparation
mise run db:logs                   # Follow PostgreSQL logs without the app
mise run reset                     # Reset and reseed the local database
mise run check                     # Backend and frontend quality checks
mise run test:unit                 # Backend and frontend unit tests
mise run test                      # Full tests, including Playwright
mise run backend:test:stale        # Fast affected backend tests
mise run frontend:test:unit:watch  # Fast frontend test feedback
mise run frontend:test:e2e:ui      # Playwright UI mode
```

The seeded accounts are `user/password123`, `admin/password123`, and
`superadmin/password123`. The backend dashboard is available at
http://127.0.0.1:4000/dev/dashboard. The development-only Ash Admin login is at
http://127.0.0.1:4000/dev/admin/sign-in.

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
and shared conventions. Backend package usage rules live in
[backend/AGENTS.md](./backend/AGENTS.md). OpenCode uses the project
[opencode.json](./opencode.json) for Tidewave and HexDocs MCP; `.mcp.json` is retained for clients
that use the legacy MCP configuration shape. Backend package rules are configured in
`backend/mix.exs`.

## Security notes

This template is designed for side projects and prototyping. Be aware of these trade-offs:

- **Password reset privacy** — `/auth/request-reset` returns the same recovery-code response shape
  for unknown usernames by returning fake codes. Rate limiting mitigates abuse, but review timing and
  other side channels before treating this as full enumeration protection.
- **Refresh-token rotation** — refresh destroys the old database token and creates a replacement.
  Token reuse detection beyond old-token invalidation is not implemented; a stolen current token
  remains usable until it is rotated, invalidated, or expires after 7 days.
- **Rate limiting** — auth endpoints are rate-limited per IP via Hammer (login: 5/min, register:
  3/min, request reset: 3/hr, reset password: 5/hr). Adjust limits in
  `TemplateAppWeb.Plugs.RateLimitPlug`.
- **HTTPS** — set `FORCE_SSL=true` in production to enable redirect-to-HTTPS and HSTS. The
  endpoint's CSP and HSTS headers activate automatically when this is set.
- **Signing secrets** — the app uses two separate secrets: `TOKEN_SIGNING_SECRET` (Joken JWTs) and
  `ASH_AUTH_SIGNING_SECRET` (AshAuthentication). Generate unique values with `mix phx.gen.secret 32`.

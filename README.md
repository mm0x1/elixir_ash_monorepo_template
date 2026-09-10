# Elixir Ash Monorepo Template

Phoenix/Ash REST API backend + SvelteKit SPA frontend.

## Stack

- **Backend**: Phoenix 1.8, Ash 3.x, PostgreSQL — plain REST/JSON endpoints
- **Frontend**: SvelteKit 2, Svelte 5, TypeScript, Tailwind CSS 4
- **Auth**: username/password (Argon2) with hybrid tokens — JWT access tokens (15 min) + DB-backed refresh tokens (7 days, HttpOnly cookie); password reset via pre-generated, single-use, expiring recovery codes (no email)

## Local development

Requires Docker and mise.

```bash
# Install the shared development tools (requires mise: https://mise.jdx.dev)
mise install

# Optional: create a root env file for local overrides.
# The defaults work without this file.
cp .env.example .env

# Start PostgreSQL, prepare the app, and run Phoenix and Vite under Tilt.
# The task installs the pinned local Tilt binary when needed.
mise run tilt
```

The default app URL is http://127.0.0.1:5173 and the API URL is
http://127.0.0.1:4000. Vite proxies local `/auth`, `/account`, and `/health`
requests to Phoenix, so `VITE_API_URL` is not needed locally. Override `PORT`
or other local settings in `.env` when needed.

The REST API accepts JSON for credential-bearing login, registration, reset, and
account mutations. The endpoint rejects form-encoded credential requests and
limits request bodies to 16 KiB. Browser preflights are handled before Phoenix
route matching. Local development allows only `http://localhost:5173` and
`http://127.0.0.1:5173`.

Separately hosted frontend and backend deployments require `VITE_API_URL` and
`FRONTEND_URL` to be configured as matching exact origins. `FRONTEND_URL` must
not contain a path, wildcard, or trailing slash. Credentialed requests are not
supported with a wildcard origin.

Tilt waits for PostgreSQL, runs backend setup and seeds before Phoenix, installs
frontend dependencies and hooks, and exposes readiness, logs, and links in its
UI. Source edits continue to use Phoenix reload and Vite HMR; dependency,
configuration, migration, and seed changes rerun only the relevant setup.
Press `Ctrl+C` once to stop the native services and PostgreSQL while retaining
the named database volume. If the wrapper is forcibly terminated, recover with
`mise exec tilt@0.37.7 -- tilt down`.

`mise run setup` remains available for one-shot dependency, migration, seed, and
hook preparation without starting application servers. Use `mise run db:up`,
`mise run db:down`, and `mise run db:logs` for database-only work.

Useful development tasks:

```bash
mise tasks                         # List all tasks
mise run tilt                      # Start the recommended Tilt workflow
mise run setup                     # One-shot dependency/database preparation
mise run db:up                     # Start PostgreSQL only
mise run db:down                   # Stop PostgreSQL
mise run db:logs                   # Follow PostgreSQL logs without the app
mise run reset                     # Reset and reseed the local database
mise run check                     # Backend and frontend quality checks
mise run build                     # Backend compile and frontend build
mise run test:unit                 # Backend and frontend unit tests
mise run test                      # Full tests, including Playwright
mise run backend:test:stale        # Fast affected backend tests
mise run frontend:test:unit:watch  # Fast frontend test feedback
mise run frontend:test:e2e:ui      # Playwright UI mode
```

`mise run reset` is destructive and intended for the local database only.

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

- **Password recovery** — signed-in users generate recovery codes from their account page and must
  store them. A logged-out reset consumes one previously generated code. There is no email delivery,
  username-only code request, or self-service recovery path after all codes are lost.
- **Refresh-token rotation** — refresh destroys the old database token and creates a replacement.
  Token reuse detection beyond old-token invalidation is not implemented; a stolen current token
  remains usable until it is rotated, invalidated, or expires after 7 days.
- **Rate limiting** — auth endpoints are rate-limited per IP via Hammer (login: 5/min, register:
  3/min, reset password: 5/hr). Adjust limits in
  `TemplateAppWeb.Plugs.RateLimitPlug`.
- **HTTPS** — set `FORCE_SSL=true` in production to enable redirect-to-HTTPS and HSTS. The
  endpoint's CSP and HSTS headers activate automatically when this is set.
- **Signing secrets** — the app uses two separate secrets: `TOKEN_SIGNING_SECRET` (Joken JWTs) and
  `ASH_AUTH_SIGNING_SECRET` (AshAuthentication). Generate unique values with `mix phx.gen.secret 32`.

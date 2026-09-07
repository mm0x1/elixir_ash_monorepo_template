# Elixir Ash Monorepo Template

Phoenix/Ash REST API backend + SvelteKit SPA frontend.

## Stack

- **Backend**: Phoenix 1.8, Ash 3.x, PostgreSQL — plain REST/JSON endpoints
- **Frontend**: SvelteKit 2, Svelte 5, TypeScript, Tailwind CSS 4
- **Auth**: username/password (Argon2) with hybrid tokens — JWT access tokens (15 min) + DB-backed refresh tokens (7 days, HttpOnly cookie); password reset via single-use, expiring recovery codes (no email)

## Quick start

```bash
# Install the pinned development tools (requires mise: https://mise.jdx.dev)
mise install

# Optional: create a root env file for local overrides.
# The defaults work without this file.
cp .env.example .env

# Prepare PostgreSQL, backend/frontend dependencies, schema, seeds, and hooks.
mise run setup

# Start PostgreSQL, Phoenix, and Vite.
mise run dev
```

The app is available at http://127.0.0.1:5173 and the API at
http://127.0.0.1:4000. Vite proxies local `/auth`, `/account`, and `/health`
requests to Phoenix, so `VITE_API_URL` is not needed for local development.

Application services run under Pitchfork. Use `mise run dev:logs` to follow
Phoenix and Vite logs, `mise run status` to inspect services, and `mise run stop`
to stop the application and database. `./dev.sh` remains available as a
compatibility wrapper around these tasks.

Useful development tasks:

```bash
mise tasks                         # List all tasks
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
and detailed conventions. Backend package usage rules live in
[backend/AGENTS.md](./backend/AGENTS.md). Agent tooling: Tidewave + HexDocs MCP servers (`.mcp.json`)
and `usage_rules` (`backend/mix.exs`).

## Security notes

This template is designed for side projects and prototyping. Be aware of these trade-offs:

- **Account enumeration** — the password reset flow uses recovery codes (no email), so the
  `/auth/request-reset` endpoint reveals whether a username exists. This is inherent to the
  no-email design; rate limiting mitigates abuse.
- **Refresh tokens are not rotated** — a stolen refresh token is valid until it expires (7 days).
  This is simpler than rotation and acceptable for low-stakes apps; for higher security, add
  rotation in `AuthController.refresh/2`.
- **Rate limiting** — auth endpoints are rate-limited per IP via Hammer (login: 5/min, register:
  3/min, reset: 3/hr). Adjust limits in `TemplateAppWeb.Plugs.RateLimitPlug`.
- **HTTPS** — set `FORCE_SSL=true` in production to enable redirect-to-HTTPS and HSTS. The
  endpoint's CSP and HSTS headers activate automatically when this is set.
- **Signing secrets** — the app uses two separate secrets: `TOKEN_SIGNING_SECRET` (Joken JWTs) and
  `ASH_AUTH_SIGNING_SECRET` (AshAuthentication). Generate unique values with `mix phx.gen.secret 32`.

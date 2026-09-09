# Frontend Agent Guide

Applies to `frontend/` and its descendants. Shared monorepo rules live in `../AGENTS.md`; read that file before frontend work. This file is symlinked by `CLAUDE.md` in this directory.

## Runtime and Deployment

- This is a SvelteKit 2 SPA using Svelte 5 and `adapter-static`.
- SSR is disabled at runtime. The build produces static output with `index.html` as the client-side fallback.
- Standalone static hosts must rewrite unknown client routes to `index.html`.
- The local preview command uses `scripts/serve-spa.mjs` and `sirv` on `127.0.0.1:4173`; it is not Vite's built-in preview server.
- The combined Docker release copies the static output into Phoenix, whose wildcard route serves the fallback.
- Local Vite development runs on `127.0.0.1:5173` with `strictPort: true` and proxies `/auth`, `/account`, and `/health` to Phoenix using the root `PORT` value.

## Type Checking and Tooling

Use the pinned Node and npm versions from `mise.toml` and `package.json`. Use `npm ci` for a clean install.

`npm run check` runs `svelte-kit sync` and `svelte-check --tsgo`, using the native TypeScript 7 package through `@typescript/native`. `npm run build` runs Vite's transpile and bundle pipeline; it does not replace type checking. Do not substitute bare `tsc --noEmit` for the Svelte-aware project check.

Tailwind CSS 4 uses the `@tailwindcss/vite` plugin. Do not create a `tailwind.config.*` or PostCSS configuration file.

## Commands

Run these from `frontend/`:

```bash
npm ci
npm run check
npm run lint
npm run format:check
npm run build
npm run preview
npm run test:unit
npm run test:e2e
npm run test
npm run test:unit:related -- path/to/source-file.ts
npx playwright install chromium
```

The watch and UI-mode commands are interactive and are for human development, not agent verification.

## Feature Structure and API Boundaries

```text
src/lib/features/<name>/
  api/           # REST wrappers; return UI types
  types/         # DTOs, UI types, and transforms
  auth/          # authentication lifecycle code when needed
  index.ts       # public feature API
```

- Backend DTOs live in feature `types/` modules and are transformed into UI types at the API boundary. Components must not consume raw backend shapes.
- API wrappers use `api.get/post/patch/put/delete` from `$lib/shared/api/client`; failed JSON responses go through `throwApiError`.
- Authenticated feature calls pass `{ fetchFn: authenticatedFetch }`.
- Raw `fetch` remains intentional in refresh, logout, and retry coordination because those functions implement the authentication transport boundary.
- `features -> shared` is one-way. Shared code must not import from `$lib/features/`; this boundary is enforced by ESLint.
- Use Svelte 5 runes in components: `$state`, `$derived`, `$effect`, and `$props`.

## Frontend Security

- `VITE_*` variables are public build-time configuration and are bundled into browser code. Never put secrets, signing keys, passwords, database credentials, or private API keys in them.
- `VITE_API_URL` is for separately hosted frontend deployments. Local development normally uses the relative API URL and Vite proxy.
- Separately hosted frontend and backend deployments require an exact backend CORS/`FRONTEND_URL` configuration and credentialed requests.
- Access tokens remain in memory. Refresh tokens are sent through `credentials: 'include'` in an HttpOnly cookie; do not move them into local storage.

## Error Handling

- In UI and feature API code, handle `ApiError` explicitly and use the generic fallback for unknown errors.
- The shared client maps 5xx responses to `Something went wrong` and uses the backend message for 4xx responses.
- The refresh coordinator may swallow an authentication failure after clearing auth so callers receive the original unauthorized response; do not convert that transport behavior into ordinary feature API behavior.

## Testing

- Unit and integration tests live under `tests/unit/` and run in jsdom through Vitest.
- `tests/support/setup-client.ts` mocks unavoidable SvelteKit seams such as `$app/navigation` and `$app/paths`, and wires MSW for network behavior.
- Prefer user-visible assertions. Narrow seam assertions are appropriate for navigation, auth cleanup, downloads, and browser APIs when those results are not directly visible.
- Shared fixtures live in `tests/support/fixtures.ts`; MSW handlers live in `tests/support/handlers.ts`.
- Playwright tests live under `e2e/`. Playwright builds the SPA and runs `scripts/serve-spa.mjs` on port 4173.
- E2E network calls are mocked with `page.route()`, not MSW, and must never depend on a live backend. Keep mocks limited to endpoints the test reaches.

## Generated Files

Do not edit or commit `.svelte-kit/`, `build/`, `test-results/`, `playwright-report/`, Playwright cache output, or other generated frontend artifacts. `svelte-kit sync`, `npm run check`, and `npm run build` regenerate derived files as needed. Dependency changes must update `package-lock.json` through npm.

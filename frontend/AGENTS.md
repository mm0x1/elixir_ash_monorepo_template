# Frontend — Agent Guide

SvelteKit 2 SPA (Svelte 5, TypeScript, Vite, Tailwind CSS 4).

The monorepo overview is in `../AGENTS.md`; coding conventions in `../.claude/conventions.md`.
Read both before writing code — they cover the auth flow, API contract, TS style, and critical rules.

## SPA — no SSR

This app uses `adapter-static` with `fallback: 'index.html'`. All routing is client-side.
No server load functions, no form actions, no server-only modules. Every route is a
purely client-rendered Svelte component.

## Type checking

`npm run check` runs `svelte-check --tsgo` (TypeScript 7 via `@typescript/native`).
`typescript` 6.x is the build compiler; `tsgo` is the checker. Do not use `tsc --noEmit`.

## Tailwind CSS 4

Uses the `@tailwindcss/vite` plugin — no `tailwind.config.js` or PostCSS config.
Do not create a Tailwind config file.

## Feature module structure

```
src/lib/features/<name>/
  api/           # REST wrappers (use authenticatedFetch, return UI types)
  types/         # UserDto (backend shape), User (UI shape), transforms
  auth/          # (or other domain subfolders)
  index.ts       # barrel — the public API for this feature
```

New features should follow this layout. `features → shared` is one-way (ESLint enforced).

## DTO → UI type boundary

Backend shapes (`UserDto`) live in `types/user.ts`. The `toUser()` transform in
`types/transforms.ts` converts to UI types. API wrappers call `toUser()` — components
never see raw DTOs.

When adding a new backend resource: define `FooDto` and `Foo` in `types/`, add a
`toFoo()` transform, use it in the API wrapper.

## Error handling

All API calls use `throwApiError(response, fallback)` from `$lib/shared/api/client`.
All catch blocks check `ApiError`:

```typescript
catch (e) {
  error = e instanceof ApiError ? e.message : 'Something went wrong';
}
```

`throwApiError` maps 5xx → `"Something went wrong"`, 4xx → backend's `message` field.

## Testing — Vitest (unit/integration)

- Tests in `tests/unit/`, run in jsdom
- `setup-client.ts` mocks `$app/navigation` and `$app/paths`, wires MSW
- Shared fixtures: `tests/support/fixtures.ts`
- MSW handlers: `tests/support/handlers.ts` — override per-test with `server.use(...)`
- Assert on user-visible output, never component internals

## Testing — Playwright (E2E)

- Tests in `e2e/`, run against `vite preview` (built SPA)
- Network mocked with `page.route()` — **not** MSW, never a live backend
- Keep mocks minimal: only the endpoints the test actually hits

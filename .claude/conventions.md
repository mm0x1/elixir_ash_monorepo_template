# Coding Conventions

## Critical Rules (Always Apply)

| Rule | Details |
|------|---------|
| **Serialize Ash structs** | Never put raw Ash structs in a JSON response. Use a serializer. |
| **Pass actor to Ash calls** | All Ash operations need `actor: current_user`; the plug must `set_actor/2` |
| **No `any` in TypeScript** | Use proper types or `unknown` with type guards |
| **`features → shared` is one-way** | Shared code must never import from `features/` |
| **Svelte 5 runes in components** | `$state`, `$derived`, `$effect`, `$props` — not legacy stores |

## Elixir / Ash

- Pattern match on function heads, not `if`/`case` in bodies
- Use `{:ok, result}` / `{:error, reason}` tuples; `with` for chaining
- Prefer code interfaces on domains over raw `Ash.read!/Ash.create!` calls
- `action(:read)` matches only the default `:read` — use `action_type(:read)` for named reads
- After creating/modifying resources, run `mix ash.codegen <name>`
- Put custom logic in change/validation modules, not anonymous functions
- `require_atomic? false` only when truly necessary (hooks that read record state)

## TypeScript / Svelte

- Prefer `type` over `interface`; use `readonly` on all type properties
- Use `??` instead of `||` for null/undefined defaults
- Prefer named exports over default exports
- Derive values during render instead of syncing with `useState`/`useEffect`/`$effect`
- API calls use `api.get/post/patch/put/delete` from `shared/api/client` — pass `{ fetchFn: authenticatedFetch }` for authenticated endpoints. Components consume UI types, never raw backend shapes

## Serialization & Response Shaping (Backend)

- **All responses go through `ApiResponse`** — both success and error. No inline `json(%{...})` in controllers.
- **Every response is JSON** — no `204 No Content`. Even "nothing to return" endpoints return `{ message: "..." }`.
- **Success responses are flat and endpoint-specific** — no `{ data: ..., meta: ... }` envelope.
- **Error messages are self-contained** — bake the field name into the message string (e.g. `"Username has already been taken"`). The frontend never maps field names to form inputs.
- **Serializers are pure functions** — they only shape data (map in, map out). The controller calls `Ash.load` for computed fields before passing the fully-loaded struct to the serializer.
- **One standalone serializer function per resource** (DTO pattern) — e.g. `UserSerializer.serialize_user/1`. No shared behaviour or protocol.
- **Serializer returns all fields** — when a lighter shape is needed (list endpoints), add a second function like `serialize_user_summary/1`.

## API & Error Handling (Frontend)

- **One canonical DTO type per backend resource** — e.g. `UserDto` in `types/dto.ts`, referenced by `AuthResponse`, `toUser()`, etc. No inline re-definitions of the backend shape.
- **Trust the types** — no Zod schemas or runtime response validation. The monorepo structure ensures both sides change together.
- **`ApiError` everywhere** — both public (`store.ts`) and authenticated (`accounts.ts`) endpoints throw `ApiError` with message + status code. One error type across the frontend.
- **4xx: show backend message. 5xx: show "Something went wrong."** — internal error details never reach the user.

## Quick Decision Guide

| Situation | Approach |
|-----------|----------|
| Creating Ash resource | Follow pattern in `accounts/resources/`, use `uuid_primary_key`, add policies |
| Writing API wrapper | Transform backend DTOs to UI types, inject auth via `getAuthHeaders()` |
| Adding an action | Prefer named actions over generic CRUD; add matching policy |
| Handling errors | Return `{:ok, _}`/`{:error, _}` tuples; use `ApiResponse` helpers in controllers |
| Shaping a controller response | Route through `ApiResponse` — never inline `json(%{...})` |
| Adding a new resource serializer | New module with `serialize_<resource>/1`, pure function, all fields |
| Throwing errors in frontend API code | Always throw `ApiError` — never plain `Error` |
| Extracting code | Only extract when 3+ call sites exist or the abstraction has a clear name |

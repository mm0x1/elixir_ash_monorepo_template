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
- API wrappers transform DTOs — components consume UI types, never raw backend shapes

## Quick Decision Guide

| Situation | Approach |
|-----------|----------|
| Creating Ash resource | Follow pattern in `accounts/resources/`, use `uuid_primary_key`, add policies |
| Writing API wrapper | Transform backend DTOs to UI types, inject auth via `getAuthHeaders()` |
| Adding an action | Prefer named actions over generic CRUD; add matching policy |
| Handling errors | Return `{:ok, _}`/`{:error, _}` tuples; use `ApiResponse` helpers in controllers |
| Extracting code | Only extract when 3+ call sites exist or the abstraction has a clear name |

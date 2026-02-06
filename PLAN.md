# Plan: Type-Safe Frontend Data Contracts

## Problem

Three places define the same data shape, manually kept in sync:

1. `user_serializer.ex` → `%{id: user.id, username: user.username, role: to_string(user.role), ...}`
2. `frontend/src/types/auth.ts` → `interface User { id: string; username: string; role: UserRole; ... }`
3. `frontend/src/lib/schemas/user.ts` → `z.object({ id: z.string().uuid(), ... })`

They're already drifting — the Zod schema includes `email` and `inserted_at` which the serializer doesn't expose, and is missing `role`, `has_recovery_codes`, `recovery_codes_count`.

## Two Approaches Evaluated

### Option A: Custom Mix Task (Serializer AST → TypeScript)

Parse serializer source files with Sourceror, extract map structures, infer types, generate TypeScript interfaces.

**Source of truth**: Serializers (you write `serialize/1`, the generator reads it)

**What you build**: ~4 Elixir modules (parser, inferrer, generator, mix task)

**What you get**:
- TypeScript interfaces generated from serializer output shapes
- Works with your existing controller + serializer pattern
- No new dependencies, Sourceror already in deps
- Watch mode + CI check mode

**What you maintain**:
- Serializers (manual — you still write `%{id: user.id, ...}`)
- Controllers (manual — `assign_prop`, `render_inertia`)
- Pagination helpers (manual — already built)
- The generator itself (~200-300 lines of Elixir)
- `@ts_types` annotations for union types and edge cases

**Limitations**:
- Type inference is heuristic-based (field named `is_*` → boolean, `*_count` → number)
- Unknown expressions fall back to `unknown` — need manual annotations
- Nested serializer calls require detection logic
- No nested field loading control — serializers are flat maps
- You're maintaining a custom code generation tool

### Option B: ash_typescript with Typed Queries

Use ash_typescript's typed query feature for fixed server-defined return shapes. The Ash resource becomes the single source of truth.

**Source of truth**: Ash resources + typed query definitions in domain DSL

**What you build**: Configuration only (DSL annotations)

**What you get**:
- TypeScript types generated directly from Ash resource definitions
- Fixed return shapes via typed queries — no client-side field selection
- Nested loading with field-level control (`%{posts: [:id, :inserted_at]}`)
- Field omission via `denied_loads` (e.g., exclude password, biography)
- Pagination types generated (offset + keyset)
- Input types + Zod schemas for action inputs
- camelCase ↔ snake_case handled automatically
- Error types generated

**What you maintain**:
- Ash resources (you're already writing these)
- Typed query definitions in domain DSL (~1-5 lines per query)
- Inertia controllers still call Ash, but use typed query results for page props

**What changes from current architecture**:
- Serializers are replaced by typed queries (server defines the shape declaratively)
- Controllers fetch data through Ash as before, but the "what fields to return" is defined in the domain, not in a serializer function
- A `/rpc/run` endpoint is added for client-side data fetching (alongside Inertia)
- Generated TypeScript client functions for any client-side API calls

## Comparison

| Concern | Option A: Custom Mix Task | Option B: ash_typescript |
|---------|--------------------------|-------------------------|
| Source of truth | Serializer functions | Ash resources |
| Type accuracy | Heuristic (good, not perfect) | Exact (reads Ash type system) |
| Nested loading control | Not supported (flat maps) | Declarative (`%{posts: [:id, :date]}`) |
| Field omission | Implicit (don't include in serializer) | Explicit (`denied_loads: [:password]`) |
| Pagination | Manual helpers (already built) | Generated types + runtime handling |
| New dependencies | None | `ash_typescript` package |
| Custom code to maintain | ~300 lines of generator | ~0 (configuration only) |
| Learning curve | Low (it's your own code) | Medium (new DSL to learn) |
| Scales with resources | Linear maintenance per serializer | Near-zero per resource (just add DSL) |
| Inertia compatibility | Native (generates types for existing flow) | Needs integration pattern (see below) |

## Recommendation: Option B (ash_typescript)

**Why**: Your core requirement is "I define the contract on the server, the client gets a fixed typed shape." That's exactly what typed queries are. Building a custom AST parser to approximate what ash_typescript does natively from the Ash type system is reinventing a wheel that already exists.

The clincher is **nested loading control**:

```elixir
# This is what you described wanting:
typed_query :user_with_details, :read do
  fields [
    :id,
    :username,
    :role,
    %{posts: [:id, :inserted_at]},       # nested, only id + date
    %{organization: [:id]},              # nested, only id
    # password and biography simply aren't listed — they don't exist in the type
  ]
end
```

A serializer-based generator can't express this — serializers return flat maps. You'd need to write nested serializers and wire them together manually, which is what you're trying to avoid.

## Integration with Inertia

ash_typescript and Inertia can coexist. Two patterns:

### Pattern 1: Typed Queries for Inertia Props

Use typed query definitions to fetch data in controllers, pass results as Inertia props:

```elixir
# Controller
def index(conn, _params) do
  user = conn.assigns.current_user

  # Use the same query shape that generates the TypeScript type
  users = Accounts.list_users!(actor: user, page: [offset: 0, limit: 20])

  conn
  |> assign_prop(:users, format_for_client(users))  # ash_typescript's output formatter
  |> render_inertia("Users/Index")
end
```

The TypeScript page receives props typed by the same typed query definition. Single source of truth.

### Pattern 2: RPC for Client-Side Data

For client-initiated requests (pagination, search, filters), use the RPC endpoint:

```typescript
// Client-side — uses generated typed function
const result = await listUsers({ page: { limit: 20, offset: 40 } });
// result is fully typed from the typed query definition
```

This means:
- **Initial page load**: Inertia controller → typed query → page props (SSR)
- **Subsequent interactions**: RPC endpoint → typed query → JSON response (client-side)
- **Same types for both paths** — defined once in the domain DSL

## Next Steps

1. **Add `ash_typescript` to deps** and configure the basics
2. **Add `AshTypescript.Resource` extension** to User resource with type name + field mappings
3. **Add `typescript_rpc` block** to Accounts domain with typed queries
4. **Run code generation** — verify generated types match current manual types
5. **Wire up the RPC endpoint** in the router
6. **Update Inertia controllers** to use ash_typescript's output formatting
7. **Replace manual TypeScript types** with generated imports
8. **Remove serializers** (replaced by typed queries)
9. **Remove manual Zod schemas** for response types (generated)
10. **Verify**: `cd frontend && npm run build` compiles, pages render correctly

## Files to Modify

| File | Change |
|------|--------|
| `mix.exs` | Add `{:ash_typescript, "~> x.x"}` dependency |
| `lib/template_app/domains/accounts/resources/user.ex` | Add `AshTypescript.Resource` extension |
| `lib/template_app/domains/accounts/accounts.ex` | Add `typescript_rpc` block with typed queries |
| `lib/template_app_web/router/router.ex` | Add RPC endpoint route |
| `frontend/src/types/auth.ts` | Replace manual types with generated imports |
| `frontend/src/lib/schemas/user.ts` | Replace manual Zod with generated imports |
| `frontend/src/lib/schemas/common.ts` | Replace with generated pagination types |
| `.gitignore` | Add generated TypeScript output directory |

## Files to Remove (eventually)

| File | Replaced by |
|------|-------------|
| `lib/template_app_web/serializers/user_serializer.ex` | Typed queries in domain DSL |
| `lib/template_app_web/plugs/current_user_prop_plug.ex` | Needs evaluation — may still use serializer for global props, or switch to ash_typescript output formatter |

## Open Questions

1. **How does ash_typescript handle global Inertia props?** The `current_user` plug serializes the user on every request. Need to verify if ash_typescript's output formatter can be used in a plug context without the full RPC pipeline.
2. **What's the exact mix task for code generation?** Need to check ash_typescript's CLI commands.
3. **Version compatibility**: Verify ash_typescript works with Ash 3.13+ and the current stack.
4. **Typed query + Inertia integration**: Need to prototype the controller pattern to confirm it works cleanly before committing to the migration.

## Verification

1. Generated TypeScript types match the current manual `User` interface
2. `cd frontend && npm run build` compiles with generated types
3. Inertia pages render correctly with data from typed queries
4. RPC endpoint returns correctly typed paginated responses
5. Adding a field to the Ash resource + typed query → regenerate → TypeScript type updates
6. `denied_loads` prevents excluded fields from appearing in generated types

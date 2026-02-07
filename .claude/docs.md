# Project Documentation for AI

## Quick Reference

| Area | Tech | Notes |
|------|------|-------|
| Backend | Phoenix 1.8 + Ash 3.0 | Elixir 1.17+ in `backend/` |
| Frontend | SvelteKit 2 + Svelte 5 | TypeScript in `frontend/` |
| Data Layer | ash_typescript RPC | Generates TypeScript client |
| Database | PostgreSQL | AshPostgres |
| Styling | Tailwind CSS 4 | No component library yet |
| Auth | Hybrid JWT tokens | Access (memory) + Refresh (HttpOnly) |

---

## Gotchas & Lessons Learned

### ash_typescript

**Never build custom RPC clients:**
ash_typescript generates complete TypeScript functions per action. Don't reinvent the wheel.

**conn.assigns.current_user must be a full user struct:**
```elixir
# WRONG - ash_typescript needs the full struct for actor resolution
assign(conn, :current_user, user_id)

# CORRECT
assign(conn, :current_user, user_struct)
```

**Monorepo path configuration:**
```elixir
# backend/config/config.exs
config :ash_typescript,
  output_file: "../frontend/src/lib/generated/ash_rpc.ts",
  source_path_prefix: "backend"  # Makes JSDoc links point to backend/lib/...
```

### API Boundary

**Generated types are private:**
```typescript
// WRONG - leaking generated types
import { UserSchema } from "$lib/generated/ash_rpc";

// CORRECT - use api/ wrapper
import { fetchUser } from "$lib/api/accounts";
import type { User } from "$lib/types/user";
```

**No response Zod schemas needed:**
ash_typescript controls both type generation AND backend serialization. They're always in sync.

### Svelte 5 Runes

**Use runes, not legacy reactive statements:**
```svelte
<!-- WRONG - Svelte 4 style -->
<script>
  let count = 0;
  $: doubled = count * 2;
</script>

<!-- CORRECT - Svelte 5 runes -->
<script lang="ts">
  let count = $state(0);
  let doubled = $derived(count * 2);
</script>
```

**Props use $props():**
```svelte
<script lang="ts">
  interface Props {
    userId: string;
    onSave?: () => void;
  }

  let { userId, onSave }: Props = $props();
</script>
```

**Effects for side effects:**
```svelte
<script lang="ts">
  let userId = $props().userId;

  $effect(() => {
    // Runs when userId changes
    fetchUser(userId);
  });
</script>
```

### Hybrid Token Auth

**Access tokens in memory, refresh tokens in HttpOnly cookies:**
```typescript
// Login sets HttpOnly cookie automatically via credentials: "include"
const res = await fetch("/auth/login", {
  method: "POST",
  credentials: "include",  // REQUIRED
  body: JSON.stringify({ username, password }),
});

// Access token stored in Svelte store (memory)
accessToken.set(res.access_token);
```

**Silent refresh on 401:**
```typescript
// Intercept 401s and refresh
if (response.status === 401) {
  await refreshAccessToken();
  // Retry original request
}
```

### Ash Framework

**UUID Generation:**
```elixir
Ash.UUID.generate()    # Standard UUID v4
Ash.UUIDv7.generate()  # UUID v7 (time-sortable)
```

**Complex updates need atomic disabled:**
```elixir
update :complex_update do
  require_atomic? false
end
```

**Always pass actor for authorization:**
```elixir
Ash.create!(changeset, actor: current_user)
```

---

## File Organization

```
backend/lib/template_app/
├── auth/                        # JWT token generation
├── core/                        # App core (repo, mailer)
├── config/                      # Configuration
└── domains/                     # Ash domains (DDD)
    └── accounts/
        ├── resources/           # Ash resources
        ├── changes/             # Custom changes
        ├── validations/         # Custom validations
        └── checks/              # Policy checks

backend/lib/template_app_web/
├── controllers/                 # API controllers
│   ├── rpc_controller.ex        # ash_typescript RPC
│   └── auth_controller.ex       # Login, refresh, logout
├── plugs/                       # Custom plugs
│   └── validate_access_token.ex
└── router/router.ex             # API-only routes

frontend/src/
├── lib/
│   ├── generated/               # ash_typescript output (PRIVATE)
│   ├── api/                     # API boundary (DTO → UI transforms)
│   ├── types/                   # UI type definitions
│   ├── auth/                    # Auth stores + refresh logic
│   ├── stores/                  # Svelte stores
│   └── components/              # Shared components
└── routes/                      # SvelteKit pages
```

---

## Patterns

### Ash Resource with RPC

```elixir
defmodule TemplateApp.Domains.MyDomain do
  use Ash.Domain,
    otp_app: :template_app,
    extensions: [AshTypescript.Rpc]

  typescript_rpc do
    namespace "items"

    resource Item do
      rpc_action :list_items, :read
      rpc_action :get_item, :by_id do
        get? true
      end
      rpc_action :create_item, :create
    end
  end
end
```

### API Wrapper

```typescript
// frontend/src/lib/api/items.ts
import { list_items, create_item } from "$lib/generated/ash_rpc";
import { getAuthHeaders, handleApiError } from "$lib/api/client";
import type { Item } from "$lib/types/item";

function toItem(dto: Record<string, unknown>): Item {
  return {
    id: dto.id as string,
    name: dto.name as string,
    createdAt: new Date(dto.created_at as string),
  };
}

export async function fetchItems(): Promise<Item[]> {
  const result = await list_items({ headers: getAuthHeaders() });
  if (!result.success) throw handleApiError(result.errors);
  return result.data.map(toItem);
}

export async function createItem(name: string): Promise<Item> {
  const result = await create_item({
    input: { name },
    headers: getAuthHeaders(),
  });
  if (!result.success) throw handleApiError(result.errors);
  return toItem(result.data);
}
```

### Svelte Page with Load Function

```typescript
// frontend/src/routes/items/+page.ts
import { fetchItems } from '$lib/api/items';
import type { PageLoad } from './$types';

export const load: PageLoad = async () => {
  const items = await fetchItems();
  return { items };
};
```

```svelte
<!-- frontend/src/routes/items/+page.svelte -->
<script lang="ts">
  import type { PageData } from './$types';

  let { data }: { data: PageData } = $props();
</script>

<h1>Items</h1>
<ul>
  {#each data.items as item}
    <li>{item.name}</li>
  {/each}
</ul>
```

### Form with Validation

```svelte
<script lang="ts">
  import { goto } from '$app/navigation';
  import { createItem } from '$lib/api/items';

  let name = $state('');
  let error = $state<string | null>(null);
  let loading = $state(false);

  async function handleSubmit(e: Event) {
    e.preventDefault();
    loading = true;
    error = null;

    try {
      await createItem(name);
      goto('/items');
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to create item';
    } finally {
      loading = false;
    }
  }
</script>

<form onsubmit={handleSubmit}>
  <input bind:value={name} placeholder="Item name" />
  {#if error}
    <p class="error">{error}</p>
  {/if}
  <button type="submit" disabled={loading}>
    {loading ? 'Creating...' : 'Create'}
  </button>
</form>
```

---

## Checklist Before Implementing

- [ ] Does this need a new Ash action, or do existing actions suffice?
- [ ] Is `rpc_action` defined in the domain's `typescript_rpc` block?
- [ ] Have I run `mix ash_typescript.generate` after adding actions?
- [ ] Is the API wrapper in `$lib/api/`, not importing generated directly in components?
- [ ] Are Ash policies defined? (deny-by-default)
- [ ] Is the actor passed to Ash calls?
- [ ] Am I using Svelte 5 runes (`$state`, `$derived`, `$effect`, `$props`)?

---

## AI Tooling

### Svelte MCP Plugin

The Svelte MCP plugin provides documentation lookup and code analysis for Svelte 5 development.

**svelte-file-editor Subagent**: A specialized subagent for creating, editing, and reviewing Svelte files.

Benefits:
- Has its own context window for fetching docs and iterating with `svelte-autofixer`
- Delegation happens automatically when appropriate
- Can be explicitly requested for Svelte-related tasks

---

_Update this doc when you discover patterns, fix bugs, or learn from mistakes._

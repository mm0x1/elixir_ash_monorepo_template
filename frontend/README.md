# Frontend (SvelteKit)

SvelteKit 2 + Svelte 5 frontend for the monorepo template.

## Development

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Type checking
npm run check

# Linting
npm run lint
npm run lint:fix

# Build for production
npm run build

# Preview production build
npm run preview
```

## Project Structure

```
src/
├── lib/
│   ├── generated/          # ash_typescript output (PRIVATE - don't import directly)
│   │   └── ash_rpc.ts      # Generated types, functions, Zod schemas
│   ├── api/                # API boundary (only folder that imports generated/)
│   │   ├── accounts.ts     # Account API wrappers
│   │   ├── client.ts       # Auth headers, error handling
│   │   └── index.ts
│   ├── types/              # UI types (consumed by components)
│   │   ├── user.ts
│   │   └── index.ts
│   ├── auth/               # Auth stores and refresh logic
│   │   ├── store.ts
│   │   └── index.ts
│   ├── stores/             # Other Svelte stores
│   └── components/         # Shared components
├── routes/                 # SvelteKit pages
│   ├── +layout.svelte
│   ├── +page.svelte
│   ├── auth/
│   │   ├── login/
│   │   └── register/
│   └── profile/
└── app.html
```

## Key Patterns

### API Boundary

Components never import from `$lib/generated/`. The API layer transforms DTOs:

```typescript
// $lib/api/accounts.ts
import { get_user } from "$lib/generated/ash_rpc";
import { getAuthHeaders } from "$lib/api/client";
import type { User } from "$lib/types/user";

export async function fetchUser(userId: string): Promise<User> {
  const result = await get_user({
    input: { id: userId },
    headers: getAuthHeaders(),
  });
  if (!result.success) throw new ApiError(result.errors);
  return toUser(result.data);
}
```

### Svelte 5 Runes

Use runes for reactivity:

```svelte
<script lang="ts">
  import { fetchUser } from '$lib/api/accounts';

  let { userId }: { userId: string } = $props();
  let user = $state<User | null>(null);
  let loading = $state(true);

  $effect(() => {
    fetchUser(userId)
      .then(u => user = u)
      .finally(() => loading = false);
  });
</script>

{#if loading}
  <p>Loading...</p>
{:else if user}
  <h1>{user.displayName}</h1>
{/if}
```

### SvelteKit Load Functions

Prefer load functions for data fetching:

```typescript
// routes/profile/[id]/+page.ts
import { fetchUser } from '$lib/api/accounts';
import type { PageLoad } from './$types';

export const load: PageLoad = async ({ params }) => {
  const user = await fetchUser(params.id);
  return { user };
};
```

```svelte
<!-- routes/profile/[id]/+page.svelte -->
<script lang="ts">
  import type { PageData } from './$types';

  let { data }: { data: PageData } = $props();
</script>

<h1>{data.user.displayName}</h1>
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `VITE_API_URL` | Backend API URL (baked at build time) |

Set in `.env` at project root or pass as build arg for Docker.

## Regenerating TypeScript Client

When backend Ash resources change:

```bash
cd ../backend
mix ash_typescript.generate
```

This updates `src/lib/generated/ash_rpc.ts`.

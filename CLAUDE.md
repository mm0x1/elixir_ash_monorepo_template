# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Read `.claude/conventions/` files before writing code. Start with `conventions/index.md`.**

## Stack

- **Backend**: Phoenix 1.8, Ash 3.0, PostgreSQL (in `backend/`)
- **Frontend**: SvelteKit 2, Svelte 5, TypeScript, Vite, Tailwind CSS 4 (in `frontend/`)
- **Data Layer**: ash_typescript generates TypeScript client, types, Zod input schemas
- **Auth**: Hybrid token (short-lived access tokens + DB-backed refresh tokens)
- **Architecture**: Monorepo with API-only backend + SPA frontend

## Commands

```bash
# === SETUP (RECOMMENDED) ===
# 1. Start database in Docker
docker compose -f docker-compose.db.yml up -d

# 2. Setup backend
cd backend
mix setup                         # Install deps, create DB, migrate, seed

# 3. Setup frontend
cd frontend
npm install

# === DEVELOPMENT (RECOMMENDED) ===
# Run backend and frontend natively for faster iteration
cd backend
mix phx.server                    # Start server (localhost:4000)
# OR with IEx shell:
iex -S mix phx.server

# In another terminal:
cd frontend
npm run dev                       # Start Vite dev server (localhost:5173)

# === ALTERNATIVE: Full Docker Stack ===
# If you prefer running everything in Docker:
docker compose up                 # Start all services (db, backend, frontend)
docker compose up -d              # Start in background

# === DATABASE ===
# Ensure database is running first:
# docker compose -f docker-compose.db.yml up -d

cd backend
mix ecto.reset                    # Drop, create, migrate, seed
mix ecto.migrate                  # Run migrations
mix ecto.create                   # Create database
mix ecto.drop                     # Drop database

# Stop database when done:
docker compose -f docker-compose.db.yml down

# === ASH CODE GENERATION ===
cd backend
mix ash.codegen                   # Generate migrations from Ash resources
mix ash_typescript.generate       # Regenerate TypeScript client (ash_rpc.ts)

# === TESTING ===
cd backend && mix test            # Run Elixir tests
cd frontend && npm run check      # Run svelte-check (type checking)

# === CODE QUALITY ===
cd backend
mix quality                       # Run all quality checks (format, credo, compile)
mix quality.fix                   # Auto-fix formatting issues
mix credo --strict                # Strict Credo analysis
mix format                        # Format Elixir

cd frontend
npm run lint                      # Lint frontend
npm run lint:fix                  # Auto-fix linting issues

# === GIT HOOKS ===
mise exec -- lefthook run pre-commit  # Run hooks manually
LEFTHOOK=0 git commit ...             # Skip hooks (emergency only)
```

## Project Structure

```
/
├── backend/                         # Phoenix/Ash API
│   ├── lib/template_app/
│   │   ├── auth/                    # JWT token generation
│   │   ├── config/                  # App configuration
│   │   ├── core/                    # Repo, mailer, secrets
│   │   ├── logging/                 # Logging infrastructure
│   │   └── domains/
│   │       └── accounts/            # User domain (DDD pattern)
│   │           ├── resources/
│   │           │   ├── user.ex      # User resource
│   │           │   ├── token.ex     # Auth tokens
│   │           │   └── refresh_token.ex
│   │           ├── changes/         # Ash changes
│   │           ├── validations/     # Custom validations
│   │           ├── checks/          # Policy checks
│   │           └── accounts.ex      # Domain with typescript_rpc config
│   ├── lib/template_app_web/
│   │   ├── controllers/
│   │   │   ├── rpc_controller.ex    # ash_typescript RPC (run/validate)
│   │   │   ├── auth_controller.ex   # Login, refresh, logout
│   │   │   └── health_controller.ex
│   │   ├── plugs/
│   │   │   └── validate_access_token.ex
│   │   └── router/router.ex         # API routes only
│   ├── config/
│   ├── priv/
│   └── mix.exs
│
├── frontend/                        # SvelteKit SPA
│   ├── src/
│   │   ├── lib/
│   │   │   ├── generated/           # ash_typescript output (PRIVATE)
│   │   │   │   └── ash_rpc.ts       # Generated types + RPC functions
│   │   │   ├── api/                 # API boundary (DTO → UI transforms)
│   │   │   │   ├── accounts.ts      # Account API wrappers
│   │   │   │   ├── client.ts        # Auth headers, error handling
│   │   │   │   └── index.ts
│   │   │   ├── types/               # UI types (consumed by components)
│   │   │   │   └── user.ts
│   │   │   ├── auth/                # Auth stores + refresh logic
│   │   │   ├── stores/              # Svelte stores
│   │   │   └── components/          # Shared components
│   │   └── routes/                  # SvelteKit pages
│   │       ├── +layout.svelte
│   │       ├── +page.svelte
│   │       ├── auth/
│   │       └── profile/
│   ├── static/
│   ├── svelte.config.js
│   └── package.json
│
├── docker-compose.yml               # Development orchestration
├── docker-compose.prod.yml          # Production overrides
├── .env.example                     # Environment template
└── MIGRATION_PLAN.md                # Architecture documentation
```

## Architecture Patterns

### ash_typescript RPC (Data Layer)

The entire data layer is generated by ash_typescript. Each domain defines what's exposed:

```elixir
# backend/lib/template_app/domains/accounts/accounts.ex
defmodule TemplateApp.Domains.Accounts do
  use Ash.Domain,
    otp_app: :template_app,
    extensions: [AshTypescript.Rpc]

  typescript_rpc do
    namespace "accounts"

    resource User do
      typed_query :current_user, :read do
        fields [:id, :username, :role, :is_anonymous]
      end

      rpc_action :get_user, :by_id do
        get? true
      end

      rpc_action :change_username, :change_username
    end
  end
end
```

The RPC controller is minimal (~20 lines):

```elixir
# backend/lib/template_app_web/controllers/rpc_controller.ex
def run(conn, params) do
  result = AshTypescript.Rpc.run_action(:template_app, conn, params)
  json(conn, result)
end
```

### API Boundary Pattern

**Generated types are PRIVATE.** Components never import from `$lib/generated/` directly.

```
┌────────────────────────────────────────────────────────────────┐
│  Components / Routes                                            │
│  (import from $lib/api/ and $lib/types/ only)                  │
├────────────────────────────────────────────────────────────────┤
│  $lib/types/         │  $lib/api/                               │
│  UI types            │  Wrappers: DTO → UI transforms           │
│  (User, etc.)        │  Auth header injection                   │
│                      │  Error handling                          │
├──────────────────────┼─────────────────────────────────────────┤
│                      │  $lib/generated/ash_rpc.ts               │
│    ESLint BLOCKS     │  (PRIVATE - only api/ imports this)      │
│    direct imports    │  Generated: functions, DTOs, Zod schemas │
└──────────────────────┴─────────────────────────────────────────┘
```

Example API wrapper:

```typescript
// frontend/src/lib/api/accounts.ts
import { get_user } from "$lib/generated/ash_rpc";
import { getAuthHeaders } from "$lib/api/client";
import type { User } from "$lib/types/user";

function toUser(dto: Record<string, unknown>): User {
  return {
    id: dto.id as string,
    displayName: dto.username as string,
    isGuest: dto.is_anonymous as boolean,
    role: dto.role as User["role"],
  };
}

export async function fetchUser(userId: string): Promise<User> {
  const result = await get_user({
    input: { id: userId },
    headers: getAuthHeaders(),
  });

  if (!result.success) {
    throw new ApiError(result.errors);
  }

  return toUser(result.data);
}
```

### Hybrid Token Authentication

| Token | Lifetime | Storage | Validation | Purpose |
|-------|----------|---------|------------|---------|
| Access Token | 15 min | Svelte store (memory) | Stateless JWT | Every RPC call |
| Refresh Token | 7 days | HttpOnly cookie | Database | Only `/auth/refresh` |

```typescript
// frontend/src/lib/auth/store.ts
export const accessToken = writable<string | null>(null);
export const currentUser = writable<User | null>(null);

export async function login(username: string, password: string) {
  const res = await fetch(`${API_URL}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ username, password }),
    credentials: "include", // Required for HttpOnly cookie
  });

  const { access_token, user } = await res.json();
  accessToken.set(access_token);
  currentUser.set(user);
}
```

## Critical Rules

1. **Never import from `$lib/generated/`** outside `$lib/api/` (ESLint enforced)
2. **Pass actor to Ash** - All Ash operations need `actor: current_user` for policies
3. **Policies are deny-by-default** - Explicitly allow actions in Ash resources
4. **API wrappers transform DTOs** - UI gets clean types, not generated DTOs
5. **Auth headers via `getAuthHeaders()`** - Never hardcode Bearer tokens
6. **Use Svelte 5 runes** - `$state`, `$derived`, `$effect`, `$props` (not legacy stores in components)

## Key Patterns

### Svelte 5 Component

```svelte
<script lang="ts">
  import { fetchUser } from '$lib/api/accounts';
  import type { User } from '$lib/types/user';

  interface Props {
    userId: string;
  }

  let { userId }: Props = $props();
  let user = $state<User | null>(null);
  let loading = $state(true);

  $effect(() => {
    loading = true;
    fetchUser(userId)
      .then((u) => (user = u))
      .finally(() => (loading = false));
  });
</script>

{#if loading}
  <p>Loading...</p>
{:else if user}
  <h1>{user.displayName}</h1>
{/if}
```

### SvelteKit Load Function

```typescript
// frontend/src/routes/profile/[id]/+page.ts
import { fetchUser } from '$lib/api/accounts';
import type { PageLoad } from './$types';

export const load: PageLoad = async ({ params }) => {
  const user = await fetchUser(params.id);
  return { user };
};
```

### Ash Resource

```elixir
defmodule TemplateApp.Domains.MyDomain.Resources.Thing do
  use Ash.Resource,
    domain: TemplateApp.Domains.MyDomain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "things"
    repo TemplateApp.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    timestamps()
  end

  actions do
    defaults [:read, :destroy]
    create :create do
      accept [:name]
    end
  end

  policies do
    policy action(:read), authorize_if: always()
  end
end
```

## Documentation

| File | Purpose | Update when... |
|------|---------|----------------|
| `CLAUDE.md` | Project overview & setup | Stack changes, new domains |
| `.claude/conventions/` | Coding style rules | Style decisions change |
| `.claude/docs.md` | Patterns, gotchas, lessons | You fix bugs, discover edge cases |
| `MIGRATION_PLAN.md` | Full architecture docs | Architecture decisions change |

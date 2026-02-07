# Phoenix/Ash + SvelteKit Monorepo Template

A full-stack monorepo template featuring:
- **Backend**: Phoenix 1.8 + Ash Framework 3.0 (Elixir)
- **Frontend**: SvelteKit 2 + Svelte 5 (TypeScript)
- **Data Layer**: ash_typescript generates TypeScript client with full type safety
- **Auth**: Hybrid token system (JWT access tokens + DB-backed refresh tokens)
- **Infrastructure**: Docker Compose for development and production

## Quick Start

### Prerequisites

- **[Docker](https://www.docker.com/)** & **[Docker Compose](https://docs.docker.com/compose/)** - Required for database (and optional for full stack)
- **[Mise](https://mise.jdx.dev/)** - Runtime version manager (for local development without Docker)
- **[direnv](https://direnv.net/)** - Environment variable management

### Option 1: Docker (Recommended)

```bash
# Clone and setup
git clone <repository-url> my-app
cd my-app
cp .env.example .env

# Start all services (database, backend, frontend)
docker compose up

# Visit:
# - Frontend: http://localhost:5173
# - Backend API: http://localhost:4000
```

### Option 2: Local Development

```bash
# Clone and setup
git clone <repository-url> my-app
cd my-app
cp .env.example .env
direnv allow

# Install tools via mise
mise install

# Start database
docker compose up -d database

# Setup backend
cd backend
mix setup

# In a new terminal, start backend
cd backend
mix phx.server

# In another terminal, setup and start frontend
cd frontend
npm install
npm run dev

# Visit:
# - Frontend: http://localhost:5173
# - Backend API: http://localhost:4000
```

## Project Structure

```
/
├── backend/                    # Phoenix/Ash API
│   ├── lib/template_app/       # Business logic (Ash domains)
│   ├── lib/template_app_web/   # HTTP layer (controllers, plugs)
│   ├── config/                 # Environment configs
│   ├── priv/                   # Migrations, static files
│   └── Dockerfile              # Multi-stage: dev + prod
│
├── frontend/                   # SvelteKit SPA
│   ├── src/
│   │   ├── lib/
│   │   │   ├── generated/      # ash_typescript output (private)
│   │   │   ├── api/            # API boundary layer
│   │   │   ├── types/          # UI type definitions
│   │   │   ├── auth/           # Auth stores
│   │   │   └── components/     # Shared components
│   │   └── routes/             # SvelteKit pages
│   └── Dockerfile              # Multi-stage: dev + prod (nginx)
│
├── docker-compose.yml          # Development orchestration
├── docker-compose.prod.yml     # Production overrides
└── .env.example                # Environment template
```

## Development Workflow

### Backend Commands

```bash
cd backend

# Database
mix ecto.reset                    # Reset database
mix ecto.migrate                  # Run migrations

# Code generation
mix ash.codegen                   # Generate Ash migrations
mix ash_typescript.generate       # Regenerate TypeScript client

# Quality
mix quality                       # Run all checks
mix test                          # Run tests
```

### Frontend Commands

```bash
cd frontend

npm run dev                       # Start dev server
npm run build                     # Production build
npm run check                     # Type checking (svelte-check)
npm run lint                      # ESLint
```

### Adding a New Feature

1. **Define Ash resource/actions** in `backend/lib/template_app/domains/`
2. **Add `rpc_action` entries** in the domain's `typescript_rpc` block
3. **Regenerate TypeScript client**: `cd backend && mix ash_typescript.generate`
4. **Create UI types** in `frontend/src/lib/types/`
5. **Create API wrapper** in `frontend/src/lib/api/` (imports from generated, transforms DTOs)
6. **Build Svelte pages** in `frontend/src/routes/` (imports from api/)

## Architecture

### ash_typescript RPC

The entire data layer is generated. Each domain defines what's exposed:

```elixir
# backend/lib/template_app/domains/accounts/accounts.ex
typescript_rpc do
  namespace "accounts"

  resource User do
    rpc_action :get_user, :by_id do
      get? true
    end
    rpc_action :change_username, :change_username
  end
end
```

Generated output includes:
- Type-safe functions per action
- TypeScript interfaces for all resources
- Zod input validation schemas
- Field selection support
- Pagination support
- Error types

### API Boundary Pattern

Components never import from `$lib/generated/` directly. The `api/` layer transforms DTOs:

```typescript
// frontend/src/lib/api/accounts.ts
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

### Hybrid Token Authentication

| Token | Lifetime | Storage | Purpose |
|-------|----------|---------|---------|
| Access Token | 15 min | Svelte store (memory) | Every RPC call |
| Refresh Token | 7 days | HttpOnly cookie | Silent refresh |

## Production Deployment

Docker Compose is configured for **local development only**. For production, deploy using your preferred infrastructure (Fly.io, Railway, Kubernetes, etc.).

### Building Docker Images (Self-Hosted)

If deploying via Docker:

```bash
# Backend
docker build --target production -t myapp-backend ./backend

# Frontend (VITE_API_URL baked at build time)
docker build --target production \
  --build-arg VITE_API_URL=https://api.example.com \
  -t myapp-frontend ./frontend
```

### Environment Variables

| Variable | Used By | Description |
|----------|---------|-------------|
| `DATABASE_URL` | Backend | PostgreSQL connection string |
| `SECRET_KEY_BASE` | Backend | Phoenix secret (generate with `mix phx.gen.secret`) |
| `TOKEN_SIGNING_SECRET` | Backend | JWT signing secret |
| `PORT` | Backend | HTTP port (default: 4000) |
| `VITE_API_URL` | Frontend | Backend API URL (baked at build time) |

## Customization

### Renaming the App

Search and replace these patterns:
- `template_app` / `TemplateApp` / `TemplateAppWeb`
- `template_app_web` / `_template_app_key`

Update folder names accordingly.

## Code Quality

Pre-commit hooks (via Lefthook) automatically run:
- Elixir formatting + Credo
- Frontend linting + type checking

Skip hooks in emergencies: `LEFTHOOK=0 git commit`

## Resources

- [Ash Framework](https://ash-hq.org) - Business logic framework
- [Phoenix Framework](https://hexdocs.pm/phoenix) - Web framework
- [SvelteKit](https://kit.svelte.dev) - Frontend framework
- [Svelte 5](https://svelte.dev) - Component framework
- [Tailwind CSS](https://tailwindcss.com) - Styling

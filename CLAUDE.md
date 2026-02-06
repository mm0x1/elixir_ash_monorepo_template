# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Read `.claude/conventions/` files before writing code. Start with `conventions/index.md`.**

## Stack

- **Backend**: Phoenix 1.8, Ash 3.0, PostgreSQL
- **Frontend**: React 19, TypeScript, Vite, TailwindCSS 4.1, DaisyUI
- **Routing**: Inertia.js v2 (server-driven SPA)
- **Auth**: AshAuthentication (session-based)

## Commands

```bash
# Setup
mix setup                        # Full setup (deps, db, assets)
mix deps.get                     # Elixir dependencies
cd frontend && npm install       # Frontend dependencies

# Development
mix phx.server                   # Start server (localhost:4000)
iex -S mix phx.server            # Start with shell

# Database
mix ecto.reset                   # Drop, create, migrate, seed
mix ecto.migrate                 # Run migrations

# Ash Code Generation
mix ash.codegen                  # Generate migrations from Ash resources
mix ash.codegen --check          # Check if codegen is needed (CI)
mix ash.codegen --dev            # Generate with dev-only options
mix ash.codegen --dry-run        # Preview changes without applying

# Testing
mix test                         # Run Elixir tests
cd frontend && npm test          # Run frontend tests once (CI mode)
cd frontend && npm run test:unit # Run tests in watch mode

# Code quality
mix quality                      # Run all quality checks (format, credo, compile, lint)
mix quality.fix                  # Auto-fix formatting and linting
mix credo                        # Code quality analysis
mix credo --strict               # Strict mode with all checks
mix format                       # Format Elixir
cd frontend && npm run lint      # Lint frontend
cd frontend && npm run lint:fix  # Auto-fix linting issues
cd frontend && npm run build     # Build frontend
mise exec -- lefthook run pre-commit  # Run git hooks manually
```

## Git Hooks

Pre-commit hooks (via Lefthook) automatically check:
- Elixir formatting (`mix format`) and Credo quality checks
- Frontend linting (ESLint) and TypeScript type checking
- Code compiles without warnings

Hooks auto-fix formatting and linting issues, then stage the fixed files.

Skip hooks in emergencies: `LEFTHOOK=0 git commit`

## Project Structure

```
lib/template_app/
├── config/                      # App configuration
├── core/                        # Repo, mailer, secrets
├── logging/                     # Logging infrastructure
└── domains/
    └── accounts/                # User domain (DDD pattern)
        ├── resources/
        │   ├── user.ex          # User resource
        │   ├── token.ex         # Auth tokens
        │   ├── permission.ex    # Permissions
        │   └── user_permission.ex
        ├── changes/             # Ash changes
        ├── validations/         # Custom validations
        ├── checks/              # Policy checks
        └── accounts.ex          # Domain definition

lib/template_app_web/
├── controllers/                 # Inertia controllers
├── helpers/                     # Controller helpers
├── plugs/                       # Auth plugs
├── serializers/                 # JSON serialization
└── router/router.ex             # Routes

frontend/src/
├── pages/                       # Inertia pages
├── components/
│   ├── ui/                      # Button/, Loading/, Brand/
│   ├── forms/                   # FormField, TextField, SelectField
│   └── patterns/                # EmptyState, LoadingState, etc.
├── lib/
│   ├── logger/                  # Logging (dev console, prod POST)
│   ├── inertia/                 # useTypedPage, useFlash, usePageErrors
│   ├── store/notifications/     # useNotifications
│   ├── hooks/                   # useLocalStorage, useDebounce, etc.
│   ├── format/                  # formatDate, formatNumber, etc.
│   └── url/                     # buildUrl, useQueryParams
├── layouts/                     # Layout components
└── types/                       # TypeScript types
```

## Architecture Patterns

### Domain-Driven Design with Ash

The backend uses Ash Framework for business logic, organized by domain (e.g., `accounts`). Each domain contains:
- **Resources**: Data models with actions, policies, and validations
- **Changes**: Custom change modules for complex transformations
- **Validations**: Custom validation logic
- **Checks**: Policy check modules for authorization

### Inertia.js SPA Pattern

Inertia creates a single-page app experience with server-side routing:
- Controllers in `lib/template_app_web/controllers/` handle requests
- Controllers serialize data and pass it to React pages via `render_inertia/2`
- React pages in `frontend/src/pages/` receive props and render UI
- Navigation uses `router.visit()` for client-side transitions

### Key Integration Points

1. **Controller → Page**: Use `assign_prop/3` to pass serialized data to Inertia pages
2. **Page → Controller**: Use `useForm()` or `router.visit()` to submit data back
3. **Ash → Controller**: Query Ash resources with `actor: current_user` for authorization
4. **Controller → Ash**: Always serialize Ash structs before passing to Inertia (see serializers/)

## Critical Rules

See `.claude/conventions.md` for full details. Most critical:

1. **Serialize Ash structs** - Never pass raw Ash structs to Inertia (use serializers)
2. **Pass actor to Ash** - All Ash operations need `actor: current_user` for policies
3. **BasePageProps index signature** - Must include `[key: string]: unknown` for TypeScript
4. **Use router.visit()** - Not `router.replace()` - use `router.visit(url, { replace: true })`
5. **Policies are deny-by-default** - Explicitly allow actions in Ash resources

## Key Patterns

### Inertia Controller

```elixir
def index(conn, _params) do
  user = conn.assigns.current_user
  items = fetch_items(user)

  conn
  |> assign_prop(:items, Enum.map(items, &serialize/1))
  |> render_inertia("Items/Index")
end
```

### Inertia Page

```tsx
import type { BasePageProps } from "@/lib/inertia";

interface Props extends BasePageProps {
  items: Item[];
}

export default function Index({ items }: Props) {
  return (
    <div>
      {items.map((i) => (
        <div key={i.id}>{i.name}</div>
      ))}
    </div>
  );
}
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

| File                               | Purpose                    | Update when...                                    |
| ---------------------------------- | -------------------------- | ------------------------------------------------- |
| `CLAUDE.md`                        | Project overview & setup   | Stack changes, new domains, architecture shifts   |
| `.claude/conventions/`             | Coding style rules         | Style decisions change, new patterns emerge       |
| `.claude/docs.md`                  | Patterns, gotchas, lessons | You fix bugs, discover edge cases, learn patterns |
| `.claude/checklists/`              | Pre/post implementation    | Development workflow changes                      |

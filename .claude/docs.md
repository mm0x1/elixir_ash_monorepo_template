# Project Documentation for AI

## Quick Reference

| Area     | Tech                      | Notes             |
| -------- | ------------------------- | ----------------- |
| Backend  | Phoenix 1.8 + Ash 3.0     | Elixir 1.15+      |
| Frontend | React 19 + TypeScript     | Vite build        |
| Routing  | Inertia.js v2             | Server-driven SPA |
| Database | PostgreSQL                | AshPostgres       |
| Styling  | TailwindCSS 4.1 + DaisyUI |                   |
| Auth     | AshAuthentication + JWT   | Session-based     |

---

## Gotchas & Lessons Learned

### TypeScript + Inertia.js

**BasePageProps must have index signature:**

```typescript
// WRONG - causes TS2344 error with usePage<T>()
interface BasePageProps {
  errors?: Record<string, ErrorValue>;
  flash?: FlashMessages;
}

// CORRECT - Inertia's PageProps requires index signature
interface BasePageProps {
  errors?: Record<string, ErrorValue>;
  flash?: FlashMessages;
  [key: string]: unknown; // Required!
}
```

**Inertia router.replace() doesn't take options:**

```typescript
// WRONG - router.replace only takes URL
router.replace(url, { preserveState: true });

// CORRECT - use router.visit with replace option
router.visit(url, { preserveState: true, preserveScroll: true, replace: true });
```

### Ash Framework

**UUID Generation:**

```elixir
Ash.UUID.generate()    # Standard UUID v4
Ash.UUIDv7.generate()  # UUID v7
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

### Inertia Controllers

**Always serialize Ash structs:**

```elixir
# WRONG - Ash structs contain non-serializable data
conn |> assign_prop(:user, user) |> render_inertia("Profile")

# CORRECT
conn |> assign_prop(:user, serialize_user(user)) |> render_inertia("Profile")
```

---

## File Organization

```
lib/template_app/
├── core/                    # App core (repo, mailer)
├── config/                  # Configuration
└── domains/                 # Ash domains (DDD)
    └── accounts/
        ├── resources/       # Ash resources
        ├── changes/         # Custom changes
        ├── validations/     # Custom validations
        └── checks/          # Policy checks

lib/template_app_web/
├── controllers/             # Inertia controllers
├── helpers/                 # Controller helpers
└── plugs/                   # Custom plugs

frontend/src/
├── pages/                   # Inertia page components
├── components/
│   ├── ui/                  # Base UI (Button/, Loading/, Brand/)
│   ├── forms/               # Form components (FormField, TextField, SelectField)
│   ├── patterns/            # UI patterns (EmptyState, LoadingState, ErrorState, Pagination)
│   └── navigation/          # Nav components
├── layouts/                 # Layout wrappers
├── lib/
│   ├── logger/              # Logging service (dev console, prod POST /api/logs)
│   ├── inertia/             # Typed hooks (useTypedPage, useFlash, usePageErrors)
│   ├── store/notifications/ # Notification context (useNotifications)
│   ├── hooks/               # Common hooks (useLocalStorage, useDebounce, etc.)
│   ├── format/              # Formatters (date, number, string)
│   └── url/                 # URL utils (buildUrl, useQueryParams)
├── test/
│   └── utils.tsx            # Test utilities (renderWithProviders, mockPageProps)
└── types/
    └── common.ts            # Shared types (BasePageProps)
```

---

## Patterns

### Ash Resource

```elixir
defmodule TemplateApp.Domains.MyDomain.Resources.MyResource do
  use Ash.Resource,
    domain: TemplateApp.Domains.MyDomain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "my_resources"
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
      change relate_actor(:creator)
    end
  end

  policies do
    policy action(:read), authorize_if: always()
    policy action([:create, :update, :destroy]), authorize_if: actor_present()
  end
end
```

### Inertia Controller

```elixir
def index(conn, _params) do
  items = fetch_items(conn.assigns.current_user)
  conn
  |> assign_prop(:items, Enum.map(items, &serialize/1))
  |> render_inertia("Items/Index")
end
```

### React Page

```tsx
import { Head } from "@inertiajs/react";
import type { BasePageProps } from "@/types/common";

interface Props extends BasePageProps {
  items: Item[];
}

export default function Index({ items }: Props) {
  return (
    <>
      <Head title="Items" />
      <div>
        {items.map((item) => (
          <div key={item.id}>{item.name}</div>
        ))}
      </div>
    </>
  );
}
```

### Form with Inertia

```tsx
import { useForm } from "@inertiajs/react";

export default function CreateItem() {
  const { data, setData, post, processing, errors } = useForm({ name: "" });

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        post("/items");
      }}
    >
      <input
        value={data.name}
        onChange={(e) => setData("name", e.target.value)}
      />
      {errors.name && <span className="text-error">{errors.name}</span>}
      <button type="submit" disabled={processing}>
        Create
      </button>
    </form>
  );
}
```

---

## Frontend Utilities

### Logger

```typescript
import { logger } from "@/lib/logger";
logger.debug("Dev only"); // Console in dev
logger.info("Dev only"); // Console in dev
logger.warn("Warning"); // Console + POST /api/logs in prod
logger.error("Error", { ctx }); // Console + POST /api/logs in prod (redacted)
```

### Typed Inertia Hooks

```typescript
import { useTypedPage, useFlash, usePageErrors } from "@/lib/inertia";

const { props } = useTypedPage<MyPageProps>();
const flash = useFlash(); // { success?, error?, info?, warning? }
const { errors, hasErrors, getErrorMessage } = usePageErrors();
```

### Notifications (no UI - apps provide their own)

```typescript
import { useNotifications } from "@/lib/store/notifications";

const { success, error, warning, info, notifications, removeNotification } =
  useNotifications();
success("Saved!");
error("Failed", 10000); // 10s duration
```

### Common Hooks

```typescript
import {
  useLocalStorage,
  useDebounce,
  useCopyToClipboard,
  useMediaQuery,
} from "@/lib/hooks";

const [value, setValue] = useLocalStorage("key", defaultValue);
const debouncedSearch = useDebounce(searchTerm, 300);
const { copied, copy } = useCopyToClipboard();
const isMobile = useMediaQuery("(max-width: 768px)");
```

### Formatting

```typescript
import {
  formatDate,
  formatRelativeTime,
  formatNumber,
  truncate,
  pluralize,
} from "@/lib/format";

formatDate(date, { format: "long" }); // "January 4, 2026"
formatRelativeTime(date); // "2 hours ago"
formatNumber(1234.5, { style: "currency", currency: "USD" }); // "$1,234.50"
truncate("Long text", 10); // "Long te..."
pluralize(5, "item"); // "5 items"
```

---

## Checklist Before Implementing

- [ ] Does this need a new Ash action, or do existing actions suffice?
- [ ] Should this be server-side (Inertia) or client-side (React Query)?
- [ ] Is all data serialized before passing to Inertia?
- [ ] Are Ash policies defined? (deny-by-default)
- [ ] Is the actor passed to Ash calls?

---

## AI Tooling

### Svelte MCP Plugin

The Svelte MCP plugin provides documentation lookup and code analysis for Svelte 5 development.

**svelte-file-editor Subagent**: A specialized subagent for creating, editing, and reviewing Svelte files.

Benefits:
- Has its own context window, allowing it to fetch documentation, iterate with the `svelte-autofixer` tool, and write to the file system without consuming main agent context
- Delegation happens automatically when appropriate
- Can be explicitly requested for Svelte-related tasks

---

_Update this doc when you discover patterns, fix bugs, or learn from mistakes._

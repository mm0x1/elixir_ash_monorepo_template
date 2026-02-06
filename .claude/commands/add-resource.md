# /add-resource

Create a new Ash resource with all necessary files for this Phoenix + Ash + Inertia project.

## Arguments

- `name` (required): Resource name (e.g., "Comment", "Notification")
- `domain` (required): Ash domain (e.g., "Accounts", "Fandoms", "Posts")

## Instructions

### 1. Create Ash Resource

Create at `lib/template_app/domains/{{domain | downcase}}/resources/{{name | downcase}}.ex`:

```elixir
defmodule TemplateApp.Domains.{{domain}}.Resources.{{name}} do
  use Ash.Resource,
    domain: TemplateApp.Domains.{{domain}},
    data_layer: AshPostgres.DataLayer

  postgres do
    table "{{name | downcase | pluralize}}"
    repo TemplateApp.Repo
  end

  attributes do
    uuid_primary_key :id
    # Add attributes based on user description
    timestamps()
  end

  relationships do
    belongs_to :creator, TemplateApp.Domains.Accounts.Resources.User
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:field1, :field2]
      change relate_actor(:creator)
    end

    update :update do
      accept [:field1, :field2]
    end
  end

  policies do
    policy action(:read) do
      authorize_if always()
    end

    policy action([:create, :update, :destroy]) do
      authorize_if actor_present()
    end
  end
end
```

### 2. Add Resource to Domain

Update `lib/template_app/domains/{{domain | downcase}}/{{domain | downcase}}.ex`:

```elixir
defmodule TemplateApp.Domains.{{domain}} do
  use Ash.Domain

  resources do
    # ... existing resources ...
    resource TemplateApp.Domains.{{domain}}.Resources.{{name}}
  end
end
```

### 3. Generate and Run Migration

```bash
MIX_ENV=dev mix ash.codegen add_{{name | downcase | pluralize}}
MIX_ENV=dev mix ecto.migrate
```

### 4. (Optional) Create Inertia Controller

Create at `lib/template_app_web/controllers/{{name | downcase}}_controller.ex`:

```elixir
defmodule TemplateAppWeb.{{name}}Controller do
  use TemplateAppWeb, :controller

  alias TemplateApp.Domains.{{domain}}

  def index(conn, params) do
    items = {{domain}}.Resources.{{name}}
    |> Ash.Query.for_read(:read, %{}, actor: conn.assigns.current_user)
    |> Ash.read!()

    conn
    |> assign_prop(:{{name | downcase | pluralize}}, serialize_items(items))
    |> render_inertia("{{name | pluralize}}/Index")
  end

  def show(conn, %{"id" => id}) do
    item = Ash.get!({{domain}}.Resources.{{name}}, id, actor: conn.assigns.current_user)

    conn
    |> assign_prop(:{{name | downcase}}, serialize_item(item))
    |> render_inertia("{{name | pluralize}}/Show")
  end

  defp serialize_items(items), do: Enum.map(items, &serialize_item/1)

  defp serialize_item(item) do
    %{
      id: item.id,
      # Add serialized fields
      created_at: item.created_at,
      updated_at: item.updated_at
    }
  end
end
```

### 5. (Optional) Add Routes

Update `lib/template_app_web/router/router.ex`:

```elixir
scope "/", TemplateAppWeb do
  pipe_through [:browser, :require_authenticated_user]

  resources "/{{name | downcase | pluralize}}", {{name}}Controller, only: [:index, :show]
end
```

### 6. (Optional) Create React Page

Create at `frontend/src/pages/{{name | pluralize}}/Index.tsx`:

```tsx
import { Head } from "@inertiajs/react";
import { getPageTitle } from "@/config/app";
import type { BasePageProps } from "@/types/common";

interface {{name}} {
  id: string;
  // Add fields matching serializer
  created_at: string;
  updated_at: string;
}

interface Props extends BasePageProps {
  {{name | downcase | pluralize}}: {{name}}[];
}

export default function Index({ {{name | downcase | pluralize}} }: Props) {
  return (
    <>
      <Head title={getPageTitle("{{name | pluralize}}")} />
      <div className="container mx-auto p-4">
        <h1 className="text-2xl font-bold mb-4">{{name | pluralize}}</h1>
        <div className="grid gap-4">
          {{{name | downcase | pluralize}}.map(item => (
            <div key={item.id} className="card bg-base-200 p-4">
              {/* Render item */}
            </div>
          ))}
        </div>
      </div>
    </>
  );
}
```

### 7. Report Summary

Report back what was created:

- Ash resource file location
- Migration name
- Controller (if created)
- React pages (if created)
- Routes (if added)

Remind user to:

- Add any custom validations or changes as needed
- Update policies for proper authorization

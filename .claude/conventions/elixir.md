# Elixir/Phoenix/Ash Conventions

**Apply these conventions to all Elixir code in this project.**

---

## Core Elixir Style

### Pattern Matching Over Conditionals

**Principle**: Use pattern matching in function heads to handle different cases.

```elixir
# 🟢 YES: Pattern matching in function heads
def process(nil), do: {:error, :not_found}
def process(%User{active: false}), do: {:error, :inactive}
def process(%User{} = user), do: {:ok, transform(user)}

# 🔴 NO: Nested conditionals
def process(user) do
  if user do
    if user.active do
      {:ok, transform(user)}
    else
      {:error, :inactive}
    end
  else
    {:error, :not_found}
  end
end
```

### Pipe Operator for Data Transformation

**Principle**: Use `|>` for sequential data transformations. Each step should be a pure transformation.

```elixir
# 🟢 YES: Clear data flow
user
|> normalize_email()
|> validate_username()
|> hash_password()
|> persist!()

# 🔴 NO: Nested function calls
persist!(hash_password(validate_username(normalize_email(user))))

# 🟢 YES: Named intermediate when complex
validated_user = user |> normalize() |> validate()
result = validated_user |> enrich_with_roles() |> persist!()
```

### Guard Clauses

**Principle**: Use guards to constrain function matches.

```elixir
# 🟢 YES: Guards for type/value constraints
def calculate_discount(price, quantity) when is_number(price) and quantity > 0 do
  price * quantity * 0.9
end

def calculate_discount(_price, _quantity), do: {:error, :invalid_input}

# 🟡 Recommended: Guards over runtime checks
def process(items) when is_list(items) and length(items) > 0 do
  # Can assume non-empty list here
end
```

### `with` for Complex Control Flow

**Principle**: Use `with` for chained operations that can fail at any step.

```elixir
# 🟢 YES: with for multiple potential failures
def create_user_with_profile(params, actor) do
  with {:ok, user} <- Accounts.create_user(params, actor: actor),
       {:ok, profile} <- Profiles.create_profile(user, params, actor: actor),
       {:ok, _} <- send_welcome_email(user) do
    {:ok, %{user: user, profile: profile}}
  end
end

# 🔴 NO: Nested case statements
def create_user_with_profile(params, actor) do
  case Accounts.create_user(params, actor: actor) do
    {:ok, user} ->
      case Profiles.create_profile(user, params, actor: actor) do
        {:ok, profile} ->
          case send_welcome_email(user) do
            {:ok, _} -> {:ok, %{user: user, profile: profile}}
            error -> error
          end
        error -> error
      end
    error -> error
  end
end

# 🟢 YES: with + else for specific error handling
with {:ok, user} <- fetch_user(id),
     {:ok, _} <- authorize(user, :edit, actor) do
  {:ok, user}
else
  {:error, :not_found} -> {:error, "User not found"}
  {:error, :unauthorized} -> {:error, "Not authorized to edit this user"}
  error -> error
end
```

### Error Tuples

**Principle**: Use `{:ok, value}` and `{:error, reason}` consistently.

```elixir
# 🟢 YES: Consistent tuple returns
def fetch_user(id) do
  case Repo.get(User, id) do
    nil -> {:error, :not_found}
    user -> {:ok, user}
  end
end

# 🟢 YES: Bang functions for expected success
user = Ash.get!(User, id, actor: actor)  # Crashes if not found - let supervisor handle

# 🔴 NO: Silent nil return hides errors
def fetch_user(id) do
  Repo.get(User, id)  # Returns nil on not found - caller must check
end
```

---

## Phoenix Patterns

### Controller Structure

**Principle**: Controllers are thin - delegate to domain logic, serialize, render.

```elixir
# 🟢 YES: Thin controller
def show(conn, %{"id" => id}) do
  actor = conn.assigns.current_user

  case Accounts.get_user(id, actor: actor) do
    {:ok, user} ->
      conn
      |> assign_prop(:user, UserSerializer.serialize(user))
      |> render_inertia("Users/Show")

    {:error, _} ->
      conn
      |> put_flash(:error, "User not found")
      |> redirect(to: ~p"/users")
  end
end

# 🔴 NO: Business logic in controller
def show(conn, %{"id" => id}) do
  user = Repo.get!(User, id)
  if user.active and can_view?(conn.assigns.current_user, user) do
    # ... lots of logic here
  end
end
```

### Plug Conventions

**Principle**: Plugs do one thing. Chain plugs for composed behavior.

```elixir
# 🟢 YES: Single-purpose plug
defmodule TemplateAppWeb.Plugs.RequireAuth do
  def call(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in")
      |> redirect(to: ~p"/sign-in")
      |> halt()
    end
  end
end

# 🟢 YES: Composed in router
pipeline :authenticated do
  plug :fetch_current_user
  plug TemplateAppWeb.Plugs.RequireAuth
end
```

---

## Ash Framework Rules

### Resource Structure

**Principle**: Resources are self-contained. Attributes, actions, policies in one file.

```elixir
defmodule TemplateApp.Domains.Accounts.Resources.User do
  use Ash.Resource,
    domain: TemplateApp.Domains.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "users"
    repo TemplateApp.Repo
  end

  # 🟢 Group related attributes
  attributes do
    uuid_primary_key :id

    # Identity
    attribute :email, :ci_string, allow_nil?: false
    attribute :username, :string, allow_nil?: false

    # Security - mark sensitive
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true

    timestamps()
  end

  # 🟢 Identities for uniqueness
  identities do
    identity :unique_email, [:email]
    identity :unique_username, [:username]
  end

  # 🟢 Actions define what can be done
  actions do
    defaults [:read, :destroy]

    create :register do
      accept [:email, :username, :password]

      change fn changeset, _ ->
        password = Ash.Changeset.get_argument(changeset, :password)
        Ash.Changeset.change_attribute(changeset, :hashed_password, hash(password))
      end
    end
  end

  # 🟢 Policies define who can do what
  policies do
    policy action(:read) do
      authorize_if always()
    end

    policy action(:register) do
      authorize_if always()
    end

    policy action([:update, :destroy]) do
      authorize_if expr(id == ^actor(:id))
    end
  end
end
```

### Actor Passing (CRITICAL)

**Principle**: Always pass the actor to Ash operations for authorization.

```elixir
# 🔴 CRITICAL: Always pass actor
Ash.read!(User, actor: current_user)
Ash.create!(changeset, actor: current_user)
Ash.update!(record, params, actor: current_user)
Ash.destroy!(record, actor: current_user)

# 🔴 NO: Missing actor breaks authorization
Ash.read!(User)  # Policies won't work correctly

# 🟢 YES: In controller
def index(conn, _params) do
  actor = conn.assigns.current_user
  {:ok, users} = Accounts.list_users(actor: actor)
  # ...
end
```

### Serialization for Inertia (CRITICAL)

**Principle**: Never pass Ash structs directly to Inertia. Always serialize.

```elixir
# 🔴 CRITICAL: Serialize before Inertia
defmodule TemplateAppWeb.Serializers.UserSerializer do
  def serialize(nil), do: nil

  def serialize(%User{} = user) do
    %{
      id: user.id,
      email: user.email,
      username: user.username,
      is_admin: user.is_admin,
      inserted_at: user.inserted_at
    }
  end

  def serialize_list(users) do
    Enum.map(users, &serialize/1)
  end
end

# 🟢 YES: In controller
conn
|> assign_prop(:user, UserSerializer.serialize(user))
|> render_inertia("Users/Show")

# 🔴 NO: Raw Ash struct to frontend
conn
|> assign_prop(:user, user)  # Will break or expose internals
|> render_inertia("Users/Show")
```

### Policies (Deny by Default)

**Principle**: Policies deny unless explicitly authorized. Plan all access paths.

```elixir
# 🟢 Policies are additive - if any authorize_if passes, action is allowed
policies do
  # Public read
  policy action(:read) do
    authorize_if always()
  end

  # Owner can update/delete
  policy action([:update, :destroy]) do
    authorize_if expr(id == ^actor(:id))
  end

  # Admin bypass for specific actions
  policy action(:admin_update) do
    authorize_if actor_attribute_equals(:is_admin, true)
  end
end

# 🟢 Use bypass sparingly - for admin operations
policies do
  bypass actor_attribute_equals(:is_superadmin, true) do
    authorize_if always()
  end

  # Regular policies below...
end
```

### Complex Updates

**Principle**: For updates with side effects, disable atomic operations.

```elixir
# 🟢 When update has complex logic
update :change_password do
  accept [:current_password, :new_password]
  require_atomic? false  # Allows non-atomic changes

  validate fn changeset, context ->
    # Complex validation logic
  end

  change fn changeset, context ->
    # Side effects like audit logging
  end
end
```

---

## Inertia Integration

### Controller Helpers

```elixir
# 🟢 Standard pattern for Inertia controllers
def index(conn, params) do
  actor = conn.assigns.current_user

  with {:ok, items} <- Items.list_items(params, actor: actor) do
    conn
    |> assign_prop(:items, ItemSerializer.serialize_list(items))
    |> assign_prop(:meta, PaginationSerializer.serialize(items))
    |> render_inertia("Items/Index")
  end
end

def create(conn, %{"item" => item_params}) do
  actor = conn.assigns.current_user

  case Items.create_item(item_params, actor: actor) do
    {:ok, item} ->
      conn
      |> put_flash(:success, "Item created")
      |> redirect(to: ~p"/items/#{item.id}")

    {:error, %Ash.Error.Invalid{} = error} ->
      conn
      |> assign_errors(error)
      |> redirect(to: ~p"/items/new")
  end
end
```

### Flash Messages

```elixir
# 🟢 Consistent flash keys
conn |> put_flash(:success, "Operation completed")
conn |> put_flash(:error, "Something went wrong")
conn |> put_flash(:info, "Note: ...")
conn |> put_flash(:warning, "Caution: ...")
```

---

## Testing Patterns

### Testing with Actors

```elixir
# 🟢 Always provide actor in tests
test "user can read their own profile", %{user: user} do
  assert {:ok, _} = Accounts.get_user(user.id, actor: user)
end

test "user cannot read other user's private data", %{user: user, other: other} do
  assert {:error, %Ash.Error.Forbidden{}} =
    Accounts.get_user(other.id, actor: user, load: [:private_data])
end
```

### Testing Policies

```elixir
# 🟢 Test policy boundaries explicitly
describe "User policies" do
  test "owner can update their profile", %{user: user} do
    assert {:ok, _} = Accounts.update_user(user, %{username: "new"}, actor: user)
  end

  test "non-owner cannot update profile", %{user: user, other: other} do
    assert {:error, %Ash.Error.Forbidden{}} =
      Accounts.update_user(user, %{username: "hacked"}, actor: other)
  end

  test "admin can update any profile", %{user: user, admin: admin} do
    assert {:ok, _} = Accounts.admin_update_user(user, %{}, actor: admin)
  end
end
```

### Controller Testing

```elixir
# 🟢 Test authorization at controller level
test "requires authentication", %{conn: conn} do
  conn = get(conn, ~p"/profile")
  assert redirected_to(conn) == ~p"/sign-in"
end

test "shows user profile when authenticated", %{conn: conn, user: user} do
  conn = conn |> log_in_user(user) |> get(~p"/profile")
  assert html_response(conn, 200) =~ user.username
end
```

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing `actor:` in Ash calls | Always pass `actor: current_user` |
| Raw Ash structs to Inertia | Use serializers |
| Nested case statements | Use `with` |
| Logic in controllers | Extract to domain module |
| Hardcoded values | Use config or module attributes |
| Silent error swallowing | Propagate errors or crash with bang |
| Testing implementation | Test behavior (inputs → outputs) |

# Pragmatic Programmer Principles

**Actionable rules derived from "The Pragmatic Programmer" by David Thomas and Andrew Hunt.**

---

## Topic 9: DRY — The Evils of Duplication

**Principle**: Every piece of knowledge must have a single, unambiguous, authoritative representation.

### Rules

- 🔴 **Extract at 3+ uses** (Rule of Three)
- 🔴 **DRY applies to knowledge, not just code** — duplicated logic is worse than duplicated lines
- 🟡 **Business rules always get extracted** — even single use
- 🟡 **Comments that restate code violate DRY**
- 🟢 **Tolerate duplication across boundaries** — sometimes copying is better than coupling

### Extraction Thresholds

| Usage | Action |
|-------|--------|
| 1 time | Keep inline |
| 2 times | Consider extracting if complex |
| 3+ times | Extract to shared function/module |
| Business rule | Always extract with clear name |

### Elixir Example

```elixir
# 🔴 VIOLATION: Duplicated policy logic
policy action(:update), authorize_if: expr(user_id == ^actor(:id) and status == :draft)
policy action(:delete), authorize_if: expr(user_id == ^actor(:id) and status == :draft)

# 🟢 FIXED: Single source of truth
policy action([:update, :delete]) do
  authorize_if expr(user_id == ^actor(:id) and status == :draft)
end
```

### TypeScript Example

```typescript
// 🔴 VIOLATION: Duplicated transformation
const userDisplay = `${user.firstName} ${user.lastName}`.trim();
const adminDisplay = `${admin.firstName} ${admin.lastName}`.trim();

// 🟢 FIXED: Extract shared logic
const formatName = (person: { firstName: string; lastName: string }) =>
  `${person.firstName} ${person.lastName}`.trim();

const userDisplay = formatName(user);
const adminDisplay = formatName(admin);
```

### Warning Signs

- Copy-pasting code and changing variable names
- Updating same logic in multiple places
- Comments explaining the same concept differently

---

## Topic 10: Orthogonality

**Principle**: Changes in one module should not require changes in unrelated modules.

### Rules

- 🔴 **Ash resources own their data and policies** — never bypass
- 🔴 **React components don't know about Ash internals** — serializers are the boundary
- 🟡 **Modules should be independently testable**
- 🟡 **Avoid shotgun surgery** — one change, one place
- 🟢 **Prefer narrow interfaces** — expose only what's needed

### Elixir Example

```elixir
# 🟢 ORTHOGONAL: Serializer decouples backend from frontend
defmodule UserSerializer do
  def serialize(%User{} = user) do
    %{
      id: user.id,
      username: user.username,
      display_name: format_display_name(user)
    }
  end

  defp format_display_name(user) do
    # Logic contained in serializer
    "#{user.first_name} #{user.last_name}"
  end
end

# Frontend never sees User struct or Ash internals
```

### TypeScript Example

```typescript
// 🟢 ORTHOGONAL: Component doesn't know data source
interface UserCardProps {
  name: string;
  avatar: string;
  onEdit: () => void;
}

function UserCard({ name, avatar, onEdit }: UserCardProps) {
  // Doesn't know if data comes from API, cache, or props
  return (
    <Card>
      <Avatar src={avatar} />
      <span>{name}</span>
      <Button onClick={onEdit}>Edit</Button>
    </Card>
  );
}
```

### Warning Signs

- Changing one file requires changes to many others
- Can't test a module without setting up half the system
- Two modules share knowledge about internal structures

---

## Topic 11: Reversibility

**Principle**: Make decisions easy to change. Avoid locking yourself in.

### Rules

- 🔴 **Environment-specific values in config, not code**
- 🔴 **Abstract external service boundaries**
- 🟡 **Use dependency injection for testability**
- 🟡 **Feature flags for gradual rollouts**
- 🟢 **Design for easy replacement** — could you swap the database?

### Elixir Example

```elixir
# 🟢 REVERSIBLE: Provider is configurable
defmodule TemplateApp.Domains.Accounts.Resources.User do
  authentication do
    # Can swap hash algorithm via config
    hash_provider AshAuthentication.Argon2Provider
  end
end

# In config/config.exs
config :template_app, :feature_flags,
  new_dashboard: System.get_env("ENABLE_NEW_DASHBOARD") == "true"

# Usage
if FeatureFlags.enabled?(:new_dashboard) do
  render_new_dashboard()
else
  render_legacy_dashboard()
end
```

### TypeScript Example

```typescript
// 🟢 REVERSIBLE: API client abstracted
interface ApiClient {
  get<T>(path: string): Promise<T>;
  post<T>(path: string, data: unknown): Promise<T>;
}

// Can swap implementations
const client: ApiClient = import.meta.env.DEV
  ? new MockApiClient()
  : new HttpApiClient(config.apiUrl);
```

### Warning Signs

- Hardcoded URLs, paths, or credentials
- Direct calls to external services throughout codebase
- Can't test without real external services

---

## Topic 23: Design by Contract

**Principle**: Functions have preconditions, postconditions, and invariants.

### Rules

- 🔴 **Ash validations are preconditions** — if they pass, action can proceed
- 🔴 **Ash policies are authorization contracts**
- 🟡 **Use typespecs in Elixir** — document contracts
- 🟡 **TypeScript types are static contracts**
- 🟢 **Zod schemas are runtime contracts**

### Elixir Example

```elixir
# Validations are the precondition contract
create :register do
  accept [:email, :username, :password]

  # Preconditions - if these pass, we can proceed
  validate present(:email)
  validate present(:username)
  validate match(:email, ~r/^[^\s]+@[^\s]+$/)
  validate string_length(:password, min: 8)

  # Change assumes preconditions are met
  change fn changeset, _ ->
    # Can assume email is present and valid here
    password = Ash.Changeset.get_argument(changeset, :password)
    Ash.Changeset.change_attribute(changeset, :hashed_password, hash(password))
  end
end
```

### TypeScript Example

```typescript
// Type is the contract
interface ValidatedOrder {
  items: OrderItem[];  // Non-empty guaranteed by validation
  total: number;       // Calculated, guaranteed positive
  customerId: string;  // UUID guaranteed by validation
}

// Function trusts the contract
function processOrder(order: ValidatedOrder): ProcessedOrder {
  // Can assume order is valid - no defensive checks needed
  return {
    ...order,
    processedAt: new Date(),
    status: 'processing',
  };
}
```

### Warning Signs

- Defensive null checks everywhere
- Same validation logic repeated in multiple places
- Functions that work "sometimes" depending on input

---

## Topic 24: Dead Programs Tell No Lies

**Principle**: Crash early. Don't paper over problems.

### Rules

- 🔴 **Use bang (!) functions for expected success** — let supervisor handle failures
- 🔴 **Don't catch errors just to log and re-throw**
- 🟡 **Fail fast at system boundaries** — validate input immediately
- 🟡 **Let OTP supervisors do their job**
- 🟢 **Assertions for impossible states** — they document invariants

### Elixir Example

```elixir
# 🟢 CRASH EARLY: Bang function expects success
def get_current_user!(conn) do
  # Crashes if no user - this is correct, something is very wrong
  conn.assigns.current_user || raise "No current user in authenticated route"
end

# 🟢 Let supervisor handle process failures
def process_job(job) do
  result = do_work!(job)  # Crashes on failure
  {:ok, result}
  # Supervisor will restart, job will be retried
end

# 🔴 NO: Swallowing errors
def process_job(job) do
  try do
    do_work!(job)
  rescue
    _ -> {:error, :failed}  # Hides the real problem
  end
end
```

### TypeScript Example

```typescript
// 🟢 FAIL FAST: Throw early for invariant violations
function getUser(id: string): User {
  const user = userCache.get(id);
  if (!user) {
    throw new Error(`Invariant violation: user ${id} not in cache after fetch`);
  }
  return user;
}

// 🔴 NO: Silent fallback hides bugs
function getUser(id: string): User | null {
  return userCache.get(id) ?? null;  // Caller might not check
}
```

### Warning Signs

- Catch blocks that just log and continue
- Functions returning null/undefined for error cases
- Defensive code that handles "impossible" cases

---

## Topic 28: Decoupling

**Principle**: Minimize dependencies between modules.

### Rules

- 🔴 **Ash domains are decoupling boundaries** — call through domain, not direct Ash
- 🔴 **Message passing over direct calls in OTP**
- 🟡 **React components communicate via props and callbacks**
- 🟡 **Depend on abstractions, not concretions**
- 🟢 **Law of Demeter** — only talk to immediate friends

### Elixir Example

```elixir
# 🟢 DECOUPLED: Controller calls domain, domain calls Ash
defmodule TemplateAppWeb.UserController do
  def show(conn, %{"id" => id}) do
    # Controller knows about Accounts domain, not Ash internals
    case Accounts.get_user(id, actor: conn.assigns.current_user) do
      {:ok, user} -> # ...
      {:error, _} -> # ...
    end
  end
end

defmodule TemplateApp.Domains.Accounts do
  def get_user(id, opts) do
    # Domain encapsulates Ash details
    User
    |> Ash.get(id, opts)
  end
end

# 🔴 COUPLED: Controller knows about Ash
defmodule TemplateAppWeb.UserController do
  def show(conn, %{"id" => id}) do
    user = User
           |> Ash.Query.filter(id == ^id)
           |> Ash.Query.load([:roles, :permissions])
           |> Ash.read_one!(actor: conn.assigns.current_user)
    # Controller knows too much about Ash internals
  end
end
```

### Warning Signs

- Module A calls Module B which calls Module C, passing data through
- Changing internal structure breaks external callers
- Tests require mocking multiple layers

---

## Topic 30: Transforming Programming

**Principle**: Think in data pipelines. Input → Transform → Output.

### Rules

- 🔴 **Use pipe operator in Elixir** — make data flow visible
- 🔴 **Use method chains or compose in TypeScript**
- 🟡 **Each transformation step should be independently testable**
- 🟡 **Name intermediate values when pipeline gets long**
- 🟢 **Visualize data shapes at each step**

### Elixir Example

```elixir
# 🟢 TRANSFORMATION: Clear data flow
def process_order(params) do
  params                    # %{items: [...], customer: "123"}
  |> parse_items()          # %{items: [Item, ...], customer_id: "123"}
  |> validate_stock()       # {:ok, %{...}} | {:error, :out_of_stock}
  |> calculate_totals()     # %{..., subtotal: 100, tax: 10, total: 110}
  |> apply_discounts()      # %{..., total: 99}
  |> create_order()         # {:ok, %Order{}} | {:error, changeset}
end
```

### TypeScript Example

```typescript
// 🟢 TRANSFORMATION: Each step transforms data
const processedOrders = rawOrders
  .filter(isValidOrder)           // RawOrder[] → RawOrder[]
  .map(parseOrder)                // RawOrder[] → ParsedOrder[]
  .map(enrichWithCustomer)        // ParsedOrder[] → EnrichedOrder[]
  .filter(hasAvailableStock)      // EnrichedOrder[] → EnrichedOrder[]
  .map(calculateTotals);          // EnrichedOrder[] → FinalOrder[]
```

### Warning Signs

- Functions that do multiple unrelated things
- Data modified in place rather than transformed
- Hard to trace how data changes through the system

---

## Topic 32: Configuration

**Principle**: Keep configuration out of code.

### Rules

- 🔴 **Environment variables for secrets**
- 🔴 **Application config for environment-specific values**
- 🟡 **Safe defaults** — app should work without explicit config
- 🟡 **Validate config at startup** — fail fast on bad config
- 🟢 **Document all config options**

### Elixir Example

```elixir
# config/runtime.exs - runtime configuration
config :template_app,
  api_url: System.get_env("API_URL") || "http://localhost:4000",
  feature_flags: %{
    new_dashboard: System.get_env("ENABLE_NEW_DASHBOARD") == "true"
  }

# Validate at startup
defmodule TemplateApp.Config do
  def validate! do
    unless Application.get_env(:template_app, :api_url) do
      raise "API_URL configuration is required"
    end
  end
end
```

### Warning Signs

- Hardcoded URLs, API keys, or paths
- Different code paths for different environments
- Secrets committed to version control

---

## Topic 40: Refactoring

**Principle**: Refactor early and often. Don't let code rot.

### Rules

- 🔴 **Tests must pass before and after**
- 🔴 **One behavior change at a time**
- 🟡 **Refactor when you see duplication**
- 🟡 **Refactor when function exceeds 30 lines**
- 🟢 **Refactor when you need to add a comment explaining what code does**

### Refactoring Triggers

| Trigger | Action |
|---------|--------|
| Function > 30 lines | Extract smaller functions |
| Module > 300 lines | Split into focused modules |
| Nested conditionals > 2 levels | Extract or use pattern matching |
| Duplicated code | Extract shared function |
| Need "what" comment | Make code self-explanatory |
| Hard to name | Probably doing too much |

### Checklist Reference

See `../checklists/refactoring.md` for full refactoring workflow.

---

## Topic 43: Stay Safe Out There

**Principle**: Security is not optional. Design for it from the start.

### Rules

- 🔴 **Never trust user input** — validate everything
- 🔴 **Use parameterized queries** — Ash does this automatically
- 🔴 **Mark sensitive fields** — `sensitive?: true` in Ash
- 🟡 **Validate on both client and server**
- 🟡 **Sanitize output** — React does this by default
- 🟢 **Principle of least privilege** — deny by default

### Elixir Example

```elixir
# 🟢 SAFE: Ash parameterizes automatically
filter expr(username == ^arg(:username))  # No SQL injection

# 🟢 SAFE: Sensitive fields marked
attribute :hashed_password, :string, sensitive?: true
attribute :api_token, :string, sensitive?: true

# 🟢 SAFE: Policies enforce authorization
policies do
  policy always() do
    forbid_if always()  # Deny by default
  end

  policy action(:read) do
    authorize_if expr(id == ^actor(:id))  # Only own data
  end
end
```

### Warning Signs

- String interpolation in queries
- Passwords or tokens logged
- Broad permissions "for convenience"
- Security checks only on frontend

---

## Topic 44: Naming Things

**Principle**: Good names reveal intent and create shared vocabulary.

### Rules

- 🔴 **Names reveal intent, not implementation**
- 🔴 **Consistent vocabulary across codebase**
- 🟡 **Elixir**: snake_case functions, PascalCase modules
- 🟡 **TypeScript**: camelCase functions, PascalCase components/types
- 🟢 **Predicates**: `?` suffix in Elixir, `is`/`has` prefix in TypeScript

### Project Vocabulary

| Term | Meaning |
|------|---------|
| Resource | Ash data model with attributes, actions, policies |
| Action | Ash operation (read, create, update, destroy, custom) |
| Actor | Currently authenticated user passed for authorization |
| Props | Data passed from Phoenix to React page via Inertia |
| Serializer | Module that transforms Ash struct to JSON-safe map |
| Domain | Ash grouping of related resources |
| Policy | Authorization rule on an Ash action |

### Examples

```elixir
# 🟢 YES: Intent-revealing names
def can_edit?(user, resource), do: # ...
def fetch_active_users(opts), do: # ...
def calculate_order_total(order), do: # ...

# 🔴 NO: Implementation-revealing or vague
def check(u, r), do: # ...
def get_data(opts), do: # ...
def process(order), do: # ...
```

```typescript
// 🟢 YES: Clear, consistent naming
const isLoading = status === 'loading';
const hasPermission = user.permissions.includes(required);
function handleSubmit() { ... }
function formatCurrency(amount: number) { ... }

// 🔴 NO: Unclear or inconsistent
const loading = status === 'loading';  // Missing "is" prefix
const perm = user.permissions.includes(required);  // Abbreviated
function doIt() { ... }  // Vague
function curr(n: number) { ... }  // Cryptic
```

### Warning Signs

- Need to read implementation to understand function
- Same concept has different names in different places
- Abbreviations that aren't universally known

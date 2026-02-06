# Functional Programming Conventions

**Apply these paradigm conventions to both Elixir and TypeScript code.**

---

## Core Principles

### Pure Functions

**Principle**: A pure function always produces the same output for the same input and has no side effects.

```elixir
# 🟢 YES: Pure function - same input, same output
def calculate_discount(price, percentage) do
  price * (1 - percentage / 100)
end

# 🔴 NO: Impure - reads external state
def calculate_discount(price) do
  percentage = Application.get_env(:app, :discount)  # External dependency
  price * (1 - percentage / 100)
end
```

```typescript
// 🟢 YES: Pure function
function calculateTotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price, 0);
}

// 🔴 NO: Impure - modifies external state
let totalCalculations = 0;
function calculateTotal(items: Item[]): number {
  totalCalculations++;  // Side effect
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

### Immutability

**Principle**: Never mutate data. Transform into new values.

```elixir
# 🟢 YES: Transform, don't mutate
def update_user(user, attrs) do
  %{user | name: attrs[:name], email: attrs[:email]}
end

# Elixir data is immutable by default - this is the norm
list = [1, 2, 3]
new_list = [0 | list]  # Creates new list, original unchanged
```

```typescript
// 🟢 YES: Spread for immutable updates
function updateUser(user: User, updates: Partial<User>): User {
  return { ...user, ...updates };
}

// 🟢 YES: Array methods that return new arrays
const doubled = numbers.map(n => n * 2);
const evens = numbers.filter(n => n % 2 === 0);
const sum = numbers.reduce((acc, n) => acc + n, 0);

// 🔴 NO: Mutating methods
numbers.push(4);        // Mutates array
numbers.sort();         // Mutates in place
user.name = 'New Name'; // Direct mutation
```

### Composition Over Inheritance

**Principle**: Build complex behavior by combining simple functions.

```elixir
# 🟢 YES: Function composition
def process_user(user) do
  user
  |> validate()
  |> normalize()
  |> enrich()
  |> persist()
end

# Each function is simple, combined for complex behavior
def validate(user), do: # ...
def normalize(user), do: # ...
def enrich(user), do: # ...
def persist(user), do: # ...
```

```typescript
// 🟢 YES: Compose functions
const processUser = (user: User) =>
  pipe(
    user,
    validate,
    normalize,
    enrich,
    persist
  );

// Or with simple chaining
const processUser = (user: User) =>
  persist(enrich(normalize(validate(user))));

// 🔴 NO: Inheritance for code reuse
class BaseProcessor { ... }
class UserProcessor extends BaseProcessor { ... }
class AdminProcessor extends UserProcessor { ... }
```

### Declarative Over Imperative

**Principle**: Describe what you want, not how to get it.

```elixir
# 🟢 YES: Declarative - describes intent
adults = Enum.filter(users, & &1.age >= 18)
names = Enum.map(adults, & &1.name)

# 🔴 NO: Imperative - describes steps
adults = []
for user <- users do
  if user.age >= 18 do
    adults = adults ++ [user]
  end
end
names = []
for adult <- adults do
  names = names ++ [adult.name]
end
```

```typescript
// 🟢 YES: Declarative
const adultNames = users
  .filter(user => user.age >= 18)
  .map(user => user.name);

// 🔴 NO: Imperative
const adultNames: string[] = [];
for (let i = 0; i < users.length; i++) {
  if (users[i].age >= 18) {
    adultNames.push(users[i].name);
  }
}
```

---

## Data Transformation

### Pipeline Thinking

**Principle**: Think of data flowing through transformations.

```
Input → Transform₁ → Transform₂ → Transform₃ → Output
```

```elixir
# 🟢 YES: Data pipeline
def process_order(raw_order) do
  raw_order
  |> parse_order()           # Raw → Parsed
  |> validate_order()        # Parsed → Validated
  |> calculate_totals()      # Validated → WithTotals
  |> apply_discounts()       # WithTotals → WithDiscounts
  |> format_for_display()    # WithDiscounts → Display
end
```

```typescript
// 🟢 YES: Method chaining as pipeline
const result = orders
  .filter(order => order.status === 'active')
  .map(order => ({
    ...order,
    total: calculateTotal(order.items),
  }))
  .sort((a, b) => b.total - a.total)
  .slice(0, 10);
```

### Map / Filter / Reduce

**Principle**: Use these three operations for most collection transformations.

| Operation | Purpose | Returns |
|-----------|---------|---------|
| `map` | Transform each element | Same-length collection |
| `filter` | Keep elements matching predicate | Shorter-or-equal collection |
| `reduce` | Accumulate to single value | Single value |

```elixir
# Map: Transform each
prices = Enum.map(items, & &1.price)

# Filter: Keep matching
expensive = Enum.filter(items, & &1.price > 100)

# Reduce: Accumulate
total = Enum.reduce(items, 0, fn item, acc -> acc + item.price end)

# Combined
total_expensive =
  items
  |> Enum.filter(& &1.price > 100)
  |> Enum.map(& &1.price)
  |> Enum.sum()
```

```typescript
// Map: Transform each
const prices = items.map(item => item.price);

// Filter: Keep matching
const expensive = items.filter(item => item.price > 100);

// Reduce: Accumulate
const total = items.reduce((sum, item) => sum + item.price, 0);

// Combined
const totalExpensive = items
  .filter(item => item.price > 100)
  .reduce((sum, item) => sum + item.price, 0);
```

### Named Intermediates for Clarity

**Principle**: Name intermediate values when the pipeline gets complex.

```elixir
# 🟢 YES: Named intermediates for complex pipelines
def calculate_report(orders) do
  active_orders = Enum.filter(orders, & &1.status == :active)

  orders_with_totals =
    active_orders
    |> Enum.map(&calculate_order_total/1)
    |> Enum.filter(& &1.total > 0)

  %{
    count: length(orders_with_totals),
    total: Enum.sum(Enum.map(orders_with_totals, & &1.total)),
    average: calculate_average(orders_with_totals)
  }
end

# 🔴 NO: Overly long pipeline
def calculate_report(orders) do
  orders
  |> Enum.filter(& &1.status == :active)
  |> Enum.map(&calculate_order_total/1)
  |> Enum.filter(& &1.total > 0)
  |> then(fn orders_with_totals ->
    %{
      count: length(orders_with_totals),
      total: Enum.sum(Enum.map(orders_with_totals, & &1.total)),
      average: calculate_average(orders_with_totals)
    }
  end)
end
```

---

## Function Design

### Single Responsibility

**Principle**: Each function does one thing well.

```elixir
# 🟢 YES: Single responsibility
def validate_email(email), do: # just validation
def normalize_email(email), do: # just normalization
def save_user(user), do: # just persistence

# Use together
def register_user(email) do
  email
  |> validate_email()
  |> normalize_email()
  |> create_user()
  |> save_user()
end

# 🔴 NO: Multiple responsibilities
def register_user(email) do
  # Validates AND normalizes AND saves - too much
  if valid_email?(email) do
    normalized = String.downcase(email)
    Repo.insert!(%User{email: normalized})
  end
end
```

### Total Functions

**Principle**: Handle all possible inputs. No unexpected crashes.

```elixir
# 🟢 YES: Total function - handles all cases
def divide(a, b) when b != 0, do: {:ok, a / b}
def divide(_, 0), do: {:error, :division_by_zero}

# 🔴 NO: Partial function - crashes on some inputs
def divide(a, b), do: a / b  # Crashes when b = 0
```

```typescript
// 🟢 YES: Total function
function divide(a: number, b: number): number | null {
  if (b === 0) return null;
  return a / b;
}

// Or with Result type
type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };

function divide(a: number, b: number): Result<number, 'division_by_zero'> {
  if (b === 0) return { ok: false, error: 'division_by_zero' };
  return { ok: true, value: a / b };
}
```

### Referential Transparency

**Principle**: A function call can be replaced with its result.

```elixir
# 🟢 YES: Referentially transparent
add(2, 3)  # Can be replaced with 5 anywhere

# 🔴 NO: Not referentially transparent
DateTime.utc_now()  # Different result each call
random_number()     # Different result each call
read_file(path)     # Depends on external state
```

---

## State Management

### Pure Core, Impure Shell

**Principle**: Keep business logic pure. Push side effects to the edges.

```
┌─────────────────────────────────────────┐
│              Impure Shell               │
│  (HTTP, Database, File I/O, Logging)    │
├─────────────────────────────────────────┤
│              Pure Core                  │
│  (Business Logic, Validation, etc.)     │
└─────────────────────────────────────────┘
```

```elixir
# Pure core - business logic
defmodule OrderCalculator do
  # All pure functions, no side effects
  def calculate_total(items), do: # ...
  def apply_discount(total, code), do: # ...
  def validate_order(order), do: # ...
end

# Impure shell - side effects at edges
defmodule OrderController do
  def create(conn, params) do
    # Read from request (impure)
    items = params["items"]

    # Pure business logic
    total = OrderCalculator.calculate_total(items)
    validated = OrderCalculator.validate_order(%{items: items, total: total})

    # Write to database (impure)
    case Orders.create(validated, actor: conn.assigns.current_user) do
      {:ok, order} -> # ...
      {:error, _} -> # ...
    end
  end
end
```

### Isolate Side Effects

**Principle**: Side effects should be explicit and contained.

```elixir
# 🟢 YES: Side effects clearly marked and contained
def process_order(order) do
  # Pure transformations
  validated = validate(order)
  calculated = calculate_totals(validated)

  # Side effect at the end, clearly visible
  persist_order(calculated)  # <-- Side effect
  send_confirmation_email(calculated)  # <-- Side effect
end

# 🔴 NO: Side effects scattered throughout
def process_order(order) do
  log("Processing order")  # Side effect
  validated = validate(order)
  Metrics.increment(:orders)  # Side effect
  calculated = calculate_totals(validated)
  persist_order(calculated)  # Side effect
  send_confirmation_email(calculated)  # Side effect
end
```

---

## Cross-Language Mapping

| Concept | Elixir | TypeScript |
|---------|--------|------------|
| **Pipeline** | `\|>` operator | Method chaining, `pipe()` |
| **Pattern match** | Function heads, `case`, `with` | Destructuring, type guards, switch |
| **Option type** | `nil` with guards | `T \| null \| undefined` |
| **Result type** | `{:ok, value} \| {:error, reason}` | `Result<T, E>` custom type |
| **Immutable update** | `%{map \| key: value}` | `{ ...obj, key: value }` |
| **List comprehension** | `for x <- list, do: ...` | `.map()`, `.filter()` |
| **Reduce** | `Enum.reduce/3` | `.reduce()` |
| **Partial application** | `&function/1`, `&Module.func(&1, fixed)` | Arrow functions, `.bind()` |
| **Higher-order function** | `Enum.map(list, &transform/1)` | `list.map(transform)` |
| **Closure** | Anonymous function captures scope | Arrow function captures scope |

---

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Mutation | Unpredictable state | Use immutable transforms |
| Shared mutable state | Race conditions, bugs | Isolate state, message passing |
| Null checks everywhere | Defensive code bloat | Option types, early returns |
| Side effects in loops | Hard to reason about | Map/filter/reduce |
| God functions | Hard to test/maintain | Single responsibility |
| Inheritance hierarchies | Tight coupling | Composition |
| Implicit dependencies | Hidden coupling | Explicit parameters |
| Magic numbers/strings | Unclear intent | Named constants |

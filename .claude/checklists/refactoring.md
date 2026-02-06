# Refactoring Checklist

**Follow this checklist for safe, systematic refactoring.**

---

## Before Refactoring

### Prerequisites

- [ ] **All tests pass** — Run `mix test` and `npm test`
- [ ] **Changes committed** — Create safe rollback point
- [ ] **Scope is limited** — One type of change at a time

### Identify the Target

| Question | Answer |
|----------|--------|
| What's the smell? | |
| Why is it a problem? | |
| What's the ideal state? | |
| What's the minimum change? | |

---

## Refactoring Triggers

**Refactor when you see:**

| Trigger | Threshold | Action |
|---------|-----------|--------|
| Duplicated code | 3+ occurrences | Extract function/module |
| Long function | > 30 lines | Extract helper functions |
| Long module | > 300 lines | Split into focused modules |
| Deep nesting | > 2 levels | Use pattern matching, early returns |
| Complex conditional | Hard to follow | Extract to named function |
| Magic values | Any hardcoded value | Extract to constant/config |
| "What" comment needed | Code isn't clear | Make code self-explanatory |
| Shotgun surgery | Change touches many files | Consolidate related logic |

---

## Safe Refactoring Steps

### Step 1: Understand Current State

- [ ] Read the code thoroughly
- [ ] Understand all callers/usages
- [ ] Identify the behavior (not implementation)

### Step 2: Ensure Test Coverage

- [ ] Tests exist for current behavior
- [ ] If not, **write tests first**
- [ ] Tests should define behavior, not implementation

```elixir
# Good: Tests behavior
test "calculates discount for bulk orders" do
  order = %{items: [%{price: 100, quantity: 10}]}
  assert calculate_discount(order) == 10
end

# Bad: Tests implementation
test "calls discount_calculator module" do
  # Testing internal structure
end
```

### Step 3: Apply Refactoring Pattern

Choose the appropriate pattern:

| Pattern | When to Use |
|---------|-------------|
| Extract Function | Logic is reusable or makes code clearer |
| Inline Function | Indirection adds no value |
| Rename | Name doesn't reveal intent |
| Extract Module | File too large, responsibilities unclear |
| Replace Conditional with Pattern Match | Nested if/case |
| Replace Loop with Pipeline | Imperative iteration |

### Step 4: Make Small Changes

- [ ] Change ONE thing at a time
- [ ] Run tests after each change
- [ ] Commit after each successful change (squash later if needed)

### Step 5: Verify Behavior Preserved

- [ ] All original tests still pass
- [ ] No new warnings
- [ ] Manual smoke test if appropriate

---

## After Refactoring

### Verification Checklist

- [ ] **All tests pass** — `mix test && cd frontend && npm test`
- [ ] **TypeScript compiles** — `cd frontend && npm run typecheck`
- [ ] **Code formatted** — `mix format && cd frontend && npm run lint:fix`
- [ ] **Quality checks pass** — `mix quality`

### Documentation Updates

- [ ] Update `.claude/docs.md` if pattern discovered
- [ ] Update relevant convention file if new pattern established
- [ ] Add comment if refactoring reason is non-obvious

### Cleanup

- [ ] Remove any temporary code/comments
- [ ] Squash WIP commits if applicable
- [ ] Update PR description with refactoring rationale

---

## Common Refactoring Patterns

### Extract Function (Elixir)

```elixir
# Before
def process_order(order) do
  # 50 lines of mixed responsibilities
end

# After
def process_order(order) do
  order
  |> validate_order()
  |> calculate_totals()
  |> apply_discounts()
  |> persist_order()
end

defp validate_order(order), do: # focused logic
defp calculate_totals(order), do: # focused logic
defp apply_discounts(order), do: # focused logic
defp persist_order(order), do: # focused logic
```

### Replace Conditional with Pattern Match

```elixir
# Before
def get_status(user) do
  cond do
    user.is_admin -> :admin
    user.is_verified -> :verified
    true -> :pending
  end
end

# After
def get_status(%{is_admin: true}), do: :admin
def get_status(%{is_verified: true}), do: :verified
def get_status(_), do: :pending
```

### Extract Component (React)

```typescript
// Before: Large component with mixed concerns
function OrderPage({ order }: Props) {
  // 200 lines including header, items, summary, actions
}

// After: Composed smaller components
function OrderPage({ order }: Props) {
  return (
    <div>
      <OrderHeader order={order} />
      <OrderItems items={order.items} />
      <OrderSummary totals={order.totals} />
      <OrderActions order={order} />
    </div>
  );
}
```

---

## Refactoring Anti-Patterns

| Anti-Pattern | Problem | Instead |
|--------------|---------|---------|
| Big Bang Refactor | Too risky, hard to debug | Small incremental changes |
| Refactor Without Tests | Can't verify correctness | Write tests first |
| Refactor + Add Features | Can't isolate issues | Separate commits |
| Premature Abstraction | Complexity without benefit | Wait for duplication |
| Perfect Code | Never done | Good enough is good enough |

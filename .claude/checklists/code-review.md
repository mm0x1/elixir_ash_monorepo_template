# Code Review Checklist

**Use this checklist when reviewing code changes.**

---

## 1. Correctness

- [ ] **Logic handles all expected inputs**
- [ ] **Error cases handled appropriately** — Not swallowed silently
- [ ] **Actor passed to all Ash operations** — `actor: current_user`
- [ ] **Policies allow required actions**
- [ ] **Edge cases considered** — Empty lists, nil values, boundary conditions

---

## 2. Conventions Compliance

### General Style

- [ ] **No duplicated code** — DRY check (3+ uses → extract)
- [ ] **Names are clear and consistent** — Follow project vocabulary
- [ ] **No commented-out code**
- [ ] **No debug statements** — `IO.inspect`, `console.log`, `dbg()`
- [ ] **Functions are reasonably sized** — Under 30 lines preferred
- [ ] **Comments explain "why", not "what"**

### Elixir Specific

- [ ] **Pattern matching over conditionals**
- [ ] **Pipe operator for data transformations**
- [ ] **`with` for complex control flow** — No nested case
- [ ] **Bang functions for expected success**
- [ ] **Ash structs serialized before Inertia** — Never raw structs to frontend
- [ ] **Policies defined for all new actions**
- [ ] **Validations as preconditions**

### TypeScript Specific

- [ ] **No `any` types** — Use proper types or `unknown` with guards
- [ ] **Props interface extends BasePageProps** — With index signature
- [ ] **Hook dependency arrays correct**
- [ ] **Early returns for conditional rendering**
- [ ] **Named handler functions** — Not complex inline handlers
- [ ] **Loading and error states handled**

---

## 3. Security

- [ ] **User input validated** — Both client and server
- [ ] **Sensitive data marked** — `sensitive?: true` for passwords, tokens
- [ ] **No secrets in code** — Use environment variables
- [ ] **Authorization enforced** — Policies or explicit checks
- [ ] **No SQL injection vectors** — Ash handles this, but verify custom queries
- [ ] **Output sanitized** — React handles this, verify any `dangerouslySetInnerHTML`

---

## 4. Performance

- [ ] **No N+1 queries** — Preload relationships as needed
- [ ] **Expensive computations memoized** — `useMemo` in React
- [ ] **No unnecessary re-renders** — Check dependency arrays
- [ ] **Pagination for lists** — Don't load unbounded data

---

## 5. Testing

- [ ] **Tests exist for new functionality**
- [ ] **Tests pass** — All existing + new
- [ ] **Tests cover failure cases**
- [ ] **No testing implementation details** — Test behavior

---

## 6. Documentation

- [ ] **Types/specs document intent**
- [ ] **Complex logic has explanatory comments**
- [ ] **Gotchas added to `.claude/docs.md`** — If discovered during review
- [ ] **Breaking changes documented**

---

## Review Summary Template

```markdown
## Review Summary

**Reviewed**: [PR/commit description]
**Verdict**: [ ] Approved [ ] Changes requested [ ] Needs discussion

### Findings

#### 🔴 Critical (Must Fix)
-

#### 🟡 Recommended (Should Fix)
-

#### 🟢 Suggestions (Nice to Have)
-

### Notes
```

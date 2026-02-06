# Conventions Index

**Read this file first to determine which convention files apply to your task.**

---

## Critical Rules (Quick Reference)

| Rule | Severity | Source |
|------|----------|--------|
| Serialize Ash structs before Inertia | 🔴 Critical | elixir.md |
| Pass `actor:` to all Ash operations | 🔴 Critical | elixir.md |
| Policies are deny-by-default | 🔴 Critical | elixir.md |
| No `any` type in TypeScript | 🔴 Critical | typescript.md |
| BasePageProps needs index signature | 🔴 Critical | typescript.md |
| Use `router.visit()`, not `router.replace()` | 🟡 Important | typescript.md |
| Extract at 3+ uses (Rule of Three) | 🟡 Important | pragmatic.md |
| Pure functions at core, side effects at boundaries | 🟡 Important | functional.md |

---

## Which Files to Read

| Task Type | Primary | Secondary | Checklist |
|-----------|---------|-----------|-----------|
| New Ash resource | elixir.md | functional.md | pre-implementation.md |
| Ash policy/action | elixir.md | pragmatic.md | code-review.md |
| React component | typescript.md | functional.md | pre-implementation.md |
| React hook | typescript.md | functional.md | code-review.md |
| Refactoring | pragmatic.md | functional.md | refactoring.md |
| Full feature (E2E) | ALL | - | pre-implementation.md |
| Code review | ALL | - | code-review.md |

---

## File Summaries

### `elixir.md` (~8KB)
Elixir/Phoenix/Ash conventions including:
- Pattern matching, pipes, guards, `with` statements
- Phoenix controller patterns
- Ash resources, actions, policies, serialization
- Inertia integration helpers
- Testing with actors

### `typescript.md` (~7KB)
TypeScript/React conventions including:
- Strict typing, avoiding `any`
- React functional components and hooks
- Inertia.js integration patterns
- Zod schemas for runtime validation
- Component testing approaches

### `functional.md` (~6KB)
Functional programming paradigm including:
- Pure functions, immutability, composition
- Pipeline thinking (Elixir |>, JS chaining)
- State isolation patterns
- Cross-language concept mapping

### `pragmatic.md` (~10KB)
Pragmatic Programmer principles as actionable rules:
- DRY, Orthogonality, Reversibility
- Design by Contract, Dead Programs
- Decoupling, Transforming Programming
- Configuration, Refactoring, Security, Naming

---

## Convention Format

All convention files follow this structure:

```markdown
## Section Name

**Principle**: One-line summary

**Rules**:
- 🔴 Critical rule (must follow)
- 🟡 Recommended rule (should follow)
- 🟢 Suggestion (nice to have)

**YES Example**:
```code
// Good pattern
```

**NO Example**:
```code
// Anti-pattern to avoid
```
```

---

## Updating Conventions

When you discover a new pattern or gotcha:

1. Add to the appropriate convention file
2. If it's a cross-cutting concern, add to this index
3. Update `.claude/docs.md` if it's a specific lesson learned
4. Consider adding to a checklist if it should be verified

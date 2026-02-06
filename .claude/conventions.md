# Coding Conventions

**Read the relevant convention files before writing code.**

---

## Convention Files

| File | When to Read |
|------|--------------|
| `conventions/index.md` | **Always first** — routes you to relevant files |
| `conventions/elixir.md` | Elixir, Phoenix, Ash work |
| `conventions/typescript.md` | TypeScript, React work |
| `conventions/functional.md` | Understanding paradigm patterns |
| `conventions/pragmatic.md` | Design decisions, refactoring |

---

## Critical Rules (Always Apply)

| Rule | Details |
|------|---------|
| 🔴 **Serialize Ash structs** | Never pass raw Ash structs to Inertia. Use serializers. |
| 🔴 **Pass actor to Ash calls** | All Ash operations need `actor: current_user` |
| 🔴 **No `any` in TypeScript** | Use proper types or `unknown` with type guards |
| 🔴 **BasePageProps index signature** | Must include `[key: string]: unknown` |
| 🔴 **router.visit(), not router.replace()** | Use `router.visit(url, { replace: true })` |

---

## Checklists

| Checklist | When to Use |
|-----------|-------------|
| `checklists/pre-implementation.md` | Before starting a new feature |
| `checklists/code-review.md` | When reviewing code |
| `checklists/refactoring.md` | Before refactoring |

---

## Quick Decision Guide

| Situation | Read |
|-----------|------|
| Creating Ash resource | `elixir.md` → Ash Framework Rules |
| Writing React component | `typescript.md` → React Patterns |
| Deciding when to extract | `pragmatic.md` → Topic 9: DRY |
| Handling errors | `elixir.md` → Error Tuples; `pragmatic.md` → Topic 24 |
| Structuring data flow | `functional.md` → Data Transformation |
| Naming things | `pragmatic.md` → Topic 44: Naming |

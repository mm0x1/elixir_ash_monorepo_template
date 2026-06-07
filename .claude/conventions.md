# Coding Conventions

**Read the relevant convention files before writing code.**

---

## Convention Files

| File | When to Read |
|------|--------------|
| `conventions/index.md` | **Always first** — routes you to relevant files |
| `conventions/elixir.md` | Elixir, Phoenix, Ash work |
| `conventions/typescript.md` | TypeScript, Svelte work |
| `conventions/functional.md` | Understanding paradigm patterns |
| `conventions/pragmatic.md` | Design decisions, refactoring |

---

## Critical Rules (Always Apply)

| Rule | Details |
|------|---------|
| 🔴 **Serialize Ash structs** | Never put raw Ash structs in a JSON response. Use a serializer. |
| 🔴 **Pass actor to Ash calls** | All Ash operations need `actor: current_user`; the plug must `set_actor/2` |
| 🔴 **No `any` in TypeScript** | Use proper types or `unknown` with type guards |
| 🔴 **`features → shared` is one-way** | Shared code must never import from `features/` |
| 🔴 **Svelte 5 runes in components** | `$state`, `$derived`, `$effect`, `$props` |

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
| Writing Svelte component | `typescript.md` → Svelte Patterns |
| Deciding when to extract | `pragmatic.md` → Topic 9: DRY |
| Handling errors | `elixir.md` → Error Tuples; `pragmatic.md` → Topic 24 |
| Structuring data flow | `functional.md` → Data Transformation |
| Naming things | `pragmatic.md` → Topic 44: Naming |

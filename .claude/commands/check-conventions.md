# /check-conventions

Validate code against project conventions and report violations.

## Instructions

### 1. Determine Scope

Check what files to validate:

```bash
# Option A: Staged files (pre-commit)
git diff --cached --name-only

# Option B: Recent changes
git diff --name-only HEAD~1

# Option C: All modified files
git status --porcelain | awk '{print $2}'
```

### 2. Load Conventions

Read the relevant convention files based on file types:

| Files Present | Load These |
|---------------|------------|
| `*.ex`, `*.exs` | `conventions/elixir.md`, `conventions/functional.md` |
| `*.ts`, `*.tsx` | `conventions/typescript.md`, `conventions/functional.md` |
| Both | All convention files |

Always also load:
- `conventions/pragmatic.md` for cross-cutting principles
- `checklists/code-review.md` for verification checklist

### 3. Check Critical Rules

These rules MUST be followed - violations are blockers:

| Rule | How to Check |
|------|--------------|
| Serialize Ash structs | Search for `assign_prop` or `render_inertia` with raw variables |
| Actor in Ash calls | Search for `Ash.` calls missing `actor:` |
| No `any` types | Search for `: any` in TypeScript files |
| BasePageProps | Check Props interfaces extend BasePageProps with index signature |
| router.visit() | Search for `router.replace(` usage |

### 4. Run Automated Checks

```bash
# Elixir formatting
mix format --check-formatted

# Elixir quality
mix credo --strict

# TypeScript types
cd frontend && npm run typecheck

# Frontend linting
cd frontend && npm run lint
```

### 5. Manual Convention Review

For each file, verify:

#### Elixir Files
- [ ] Pattern matching used over conditionals
- [ ] Pipe operators for data transformations
- [ ] `with` for complex conditional flows
- [ ] Bang functions for expected success
- [ ] Ash policies defined for actions
- [ ] Serializers used at Inertia boundary

#### TypeScript Files
- [ ] Proper types (no `any`)
- [ ] Props extend BasePageProps
- [ ] Hook dependency arrays correct
- [ ] Early returns for conditionals
- [ ] Loading/error states handled

#### Functional Paradigm
- [ ] Pure functions preferred
- [ ] Immutable data transformations
- [ ] No side effects in pure functions

### 6. Report Findings

Generate a report with:

```markdown
## Convention Check Results

### Summary
- Files checked: X
- Critical violations: X
- Recommended fixes: X
- Suggestions: X

### Critical Violations (Must Fix)
| File | Line | Rule | Issue |
|------|------|------|-------|
| ... | ... | ... | ... |

### Recommended Fixes
| File | Line | Rule | Issue |
|------|------|------|-------|
| ... | ... | ... | ... |

### Suggestions
| File | Line | Rule | Issue |
|------|------|------|-------|
| ... | ... | ... | ... |
```

## Quick Check

For rapid validation before commit:

```bash
# Run all quality checks
mix quality

# If that passes, conventions are likely followed
```

## Using the Conventions Enforcer Agent

For thorough validation, use the conventions-enforcer agent:

```
Use the Task tool to launch conventions-enforcer agent with prompt:
"Check all staged files against project conventions"
```

The agent provides detailed reports with specific fixes.

## Common Violations and Fixes

### Raw Ash Struct to Inertia

```elixir
# Wrong
assign_prop(:user, user)

# Correct
assign_prop(:user, UserSerializer.serialize(user))
```

### Missing Actor

```elixir
# Wrong
Ash.create!(changeset)

# Correct
Ash.create!(changeset, actor: current_user)
```

### TypeScript `any`

```typescript
// Wrong
function handle(data: any) { ... }

// Correct
function handle(data: UserData) { ... }
// Or with unknown
function handle(data: unknown) {
  if (isUserData(data)) { ... }
}
```

### router.replace

```typescript
// Wrong
router.replace('/dashboard')

// Correct
router.visit('/dashboard', { replace: true })
```

## Convention File Locations

| File | Purpose |
|------|---------|
| `conventions/index.md` | Master routing table |
| `conventions/elixir.md` | Elixir/Phoenix/Ash rules |
| `conventions/typescript.md` | TypeScript/React rules |
| `conventions/functional.md` | FP paradigm patterns |
| `conventions/pragmatic.md` | Pragmatic Programmer principles |
| `checklists/code-review.md` | Review checklist |

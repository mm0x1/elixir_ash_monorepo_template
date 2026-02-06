# Post Tool Use Hook

Runs after Claude makes file changes to ensure code quality.

## Auto-Format After Edits

### Elixir Files

When `.ex` or `.exs` files are modified:

```bash
mix format
```

### TypeScript/React Files

When `.ts`, `.tsx`, `.js`, or `.jsx` files are modified:

```bash
cd frontend && npm run lint:fix
```

## Report Formatting Changes

If formatting changes any files, report:
- "Formatted [N] Elixir files"
- "Fixed linting issues in [N] frontend files"

## Verification Checks

After significant changes, run:

```bash
# Quick verification
mix format --check-formatted
cd frontend && npm run lint
```

## When to Skip

Skip auto-actions when:
- Only reading files (no modifications)
- Modifying non-code files (README, docs)
- Running tests or commands

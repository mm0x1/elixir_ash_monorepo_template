# /verify-app

Test the application end-to-end to verify everything works.

## Instructions

### 1. Check Code Quality

Run formatting and linting:

```bash
# Format Elixir code
mix format --check-formatted

# Lint frontend
cd frontend && npm run lint
```

### 2. Run Tests

```bash
# Run Elixir tests
MIX_ENV=test mix test

# Run frontend tests (if any)
cd frontend && npm test
```

### 3. TypeScript Check

Verify TypeScript compiles without errors:

```bash
# Check for TypeScript errors
cd frontend && npm run typecheck
```

### 4. Build Check

Verify the app builds without errors:

```bash
# Build frontend assets
cd frontend && npm run build
```

### 5. Start Server (Optional)

If tests pass, verify the app starts:

```bash
MIX_ENV=dev mix phx.server
```

### 6. Manual Checks (if server running)

- [ ] Visit http://localhost:4000 - home page loads
- [ ] Check browser console for JavaScript errors
- [ ] Test Inertia navigation (no full page reloads)
- [ ] Test authentication flow if applicable

### 7. Report Results

Report back:
- Number of passing/failing tests
- Any linting errors found
- Any TypeScript errors found
- Any build errors
- Whether server starts successfully

## Quick Verification (Non-Interactive)

For quick checks without starting the server:

```bash
mix format --check-formatted && \
MIX_ENV=test mix test && \
cd frontend && npm run lint && npm run typecheck && npm run build
```

If all commands pass, the app is in a good state.

## Common Issues

### Test Database Issues

```bash
MIX_ENV=test mix ecto.reset
```

### Stale Compiled Code

```bash
mix clean
mix compile
```

### Node Modules Issues

```bash
cd frontend && rm -rf node_modules && npm install
```

## Update Documentation

If you encounter and fix issues during verification, update `.claude/docs.md` with:
- Error messages and their solutions
- TypeScript/compilation fixes
- Configuration gotchas discovered

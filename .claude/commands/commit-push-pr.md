# /commit-push-pr

Commit changes, push to GitHub, and create a PR.

## Pre-computed Context

```bash
# Get current branch
BRANCH=$(git branch --show-current)

# Get git status
GIT_STATUS=$(git status --short)

# Get staged changes
STAGED=$(git diff --cached --stat)

# Get unstaged changes
UNSTAGED=$(git diff --stat)
```

## Instructions

1. Review the changes:
   - Staged: {{STAGED}}
   - Unstaged: {{UNSTAGED}}

2. If there are unstaged changes, stage them:
   ```bash
   git add .
   ```

3. Generate a commit message based on the changes in {{GIT_STATUS}}
   - Follow conventional commits format (feat:, fix:, chore:, docs:, refactor:, test:)
   - Be specific about what changed
   - For this Phoenix + Ash + Inertia project, mention:
     - Backend changes (Ash resources, controllers, etc.)
     - Frontend changes (React components, types)

4. Commit:
   ```bash
   git commit -m "your generated message"
   ```

5. Push to origin:
   ```bash
   git push origin {{BRANCH}}
   ```

6. Create PR using GitHub CLI:
   ```bash
   gh pr create --fill
   ```

7. Report the PR URL to the user

## Example Commit Messages

```
feat(accounts): add user profile update action

- Add update_profile action to User resource
- Create ProfileController with show/update actions
- Add Profile/Edit.tsx React component
```

```
fix(auth): improve error handling for sign in

- Add validation for empty username
- Update error messages for clarity
- Add test coverage for edge cases
```

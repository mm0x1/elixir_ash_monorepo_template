#!/usr/bin/env bash
set -euo pipefail

# Rename the template app throughout the monorepo.
# Usage: ./scripts/rename.sh my_new_app

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ── Validate input ──────────────────────────────────────────────────

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <new_app_name>"
  echo "  new_app_name must be lowercase snake_case (e.g. my_cool_app)"
  exit 1
fi

NEW_SNAKE="$1"

if ! [[ "$NEW_SNAKE" =~ ^[a-z][a-z0-9]*(_[a-z0-9]+)*$ ]] || [[ ${#NEW_SNAKE} -lt 2 ]]; then
  echo "Error: '$NEW_SNAKE' is not valid snake_case (lowercase letters, digits, underscores; at least 2 chars)."
  exit 1
fi

# ── Derive name variants ────────────────────────────────────────────

to_pascal() {
  echo "$1" | sed -E 's/(^|_)([a-z])/\U\2/g'
}

to_kebab() {
  echo "$1" | tr '_' '-'
}

to_screaming() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

OLD_SNAKE="template_app"
OLD_PASCAL="TemplateApp"
OLD_KEBAB="template-app"
OLD_SCREAMING="TEMPLATE_APP"

NEW_PASCAL="$(to_pascal "$NEW_SNAKE")"
NEW_KEBAB="$(to_kebab "$NEW_SNAKE")"
NEW_SCREAMING="$(to_screaming "$NEW_SNAKE")"

echo "Renaming template app:"
echo "  snake_case:     $OLD_SNAKE  ->  $NEW_SNAKE"
echo "  PascalCase:     $OLD_PASCAL ->  $NEW_PASCAL"
echo "  kebab-case:     $OLD_KEBAB  ->  $NEW_KEBAB"
echo "  SCREAMING_SNAKE: $OLD_SCREAMING -> $NEW_SCREAMING"
echo ""

# ── Confirmation ────────────────────────────────────────────────────

read -rp "Proceed? (y/N) " answer
if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

# ── Directories to skip ─────────────────────────────────────────────

EXCLUDE_DIRS=(.git _build deps node_modules .elixir_ls)
PRUNE_ARGS=()
for d in "${EXCLUDE_DIRS[@]}"; do
  PRUNE_ARGS+=(-name "$d" -prune -o)
done

# ── Step 1: Replace file contents ───────────────────────────────────

echo ""
echo "=== Replacing file contents ==="
file_count=0

while IFS= read -r -d '' file; do
  # Skip binary files
  if file --brief --mime "$file" | grep -qv 'text/\|application/json\|application/javascript\|application/xml'; then
    continue
  fi

  changed=false
  if grep -q "$OLD_PASCAL" "$file" 2>/dev/null; then changed=true; fi
  if grep -q "$OLD_SNAKE" "$file" 2>/dev/null; then changed=true; fi
  if grep -q "$OLD_KEBAB" "$file" 2>/dev/null; then changed=true; fi
  if grep -q "$OLD_SCREAMING" "$file" 2>/dev/null; then changed=true; fi

  if $changed; then
    # PascalCase first (longer match before snake_case which is a substring)
    sed -i \
      -e "s/$OLD_PASCAL/$NEW_PASCAL/g" \
      -e "s/$OLD_SNAKE/$NEW_SNAKE/g" \
      -e "s/$OLD_KEBAB/$NEW_KEBAB/g" \
      -e "s/$OLD_SCREAMING/$NEW_SCREAMING/g" \
      "$file"
    echo "  replaced in: ${file#"$REPO_ROOT/"}"
    ((file_count++)) || true
  fi
done < <(find "$REPO_ROOT" "${PRUNE_ARGS[@]}" -type f -print0)

echo "  $file_count files updated"

# ── Step 2: Rename files ────────────────────────────────────────────

echo ""
echo "=== Renaming files ==="
rename_count=0

while IFS= read -r -d '' file; do
  dir="$(dirname "$file")"
  base="$(basename "$file")"
  newbase="${base//$OLD_SNAKE/$NEW_SNAKE}"
  if [[ "$base" != "$newbase" ]]; then
    if git -C "$REPO_ROOT" ls-files --error-unmatch "$file" &>/dev/null; then
      git -C "$REPO_ROOT" mv "$file" "$dir/$newbase"
    else
      mv "$file" "$dir/$newbase"
    fi
    echo "  file: ${file#"$REPO_ROOT/"} -> $newbase"
    ((rename_count++)) || true
  fi
done < <(find "$REPO_ROOT" "${PRUNE_ARGS[@]}" -type f -name "*${OLD_SNAKE}*" -print0)

echo "  $rename_count files renamed"

# ── Step 3: Rename directories (depth-first) ────────────────────────

echo ""
echo "=== Renaming directories ==="
dir_count=0

while IFS= read -r -d '' dir; do
  parent="$(dirname "$dir")"
  base="$(basename "$dir")"
  newbase="${base//$OLD_SNAKE/$NEW_SNAKE}"
  if [[ "$base" != "$newbase" ]]; then
    if git -C "$REPO_ROOT" ls-files "$dir/" &>/dev/null 2>&1; then
      git -C "$REPO_ROOT" mv "$dir" "$parent/$newbase"
    else
      mv "$dir" "$parent/$newbase"
    fi
    echo "  dir:  ${dir#"$REPO_ROOT/"} -> $newbase"
    ((dir_count++)) || true
  fi
done < <(find "$REPO_ROOT" "${PRUNE_ARGS[@]}" -type d -name "*${OLD_SNAKE}*" -print0 | sort -rz)

echo "  $dir_count directories renamed"

# ── Step 4: Install dependencies ────────────────────────────────────

echo ""
echo "=== Installing dependencies ==="

if [[ -f "$REPO_ROOT/backend/mix.exs" ]]; then
  echo "  Running mix deps.get..."
  (cd "$REPO_ROOT/backend" && mix deps.get --quiet 2>&1) || echo "  Warning: mix deps.get failed"
fi

if [[ -f "$REPO_ROOT/frontend/package.json" ]]; then
  echo "  Running npm install..."
  (cd "$REPO_ROOT/frontend" && npm install --silent 2>&1) || echo "  Warning: npm install failed"
fi

# ── Summary ─────────────────────────────────────────────────────────

echo ""
echo "=== Done ==="
echo "  $file_count files updated"
echo "  $rename_count files renamed"
echo "  $dir_count directories renamed"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff --stat"
echo "  2. Update the database name in .env / docker-compose"
echo "  3. Run: cd backend && mix setup"

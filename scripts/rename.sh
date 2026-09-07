#!/usr/bin/env bash
set -euo pipefail

# Rename the template app throughout the monorepo.
# Usage: ./scripts/rename.sh [--dry-run] my_new_app

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ── Validate input ──────────────────────────────────────────────────

DRY_RUN=false
if [[ $# -eq 2 && "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  shift
elif [[ $# -eq 2 && "$2" == "--dry-run" ]]; then
  DRY_RUN=true
  set -- "$1"
fi

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 [--dry-run] <new_app_name>"
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
  local result=""
  local part first_upper
  local -a parts

  IFS="_" read -ra parts <<< "$1"
  for part in "${parts[@]}"; do
    first_upper="$(printf '%s' "${part:0:1}" | tr '[:lower:]' '[:upper:]')"
    result+="$first_upper${part:1}"
  done

  printf '%s\n' "$result"
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

if $DRY_RUN; then
  echo "Dry run: no files will be changed."
else
  read -rp "Proceed? (y/N) " answer
  if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# ── Step 1: Replace file contents ───────────────────────────────────

echo ""
echo "=== Replacing file contents ==="
file_count=0

replace_contents() {
  local file="$1"
  local temp_file file_mode line

  temp_file="$(mktemp "${file}.rename.XXXXXX")"
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line//$OLD_PASCAL/$NEW_PASCAL}"
    line="${line//$OLD_SNAKE/$NEW_SNAKE}"
    line="${line//$OLD_KEBAB/$NEW_KEBAB}"
    line="${line//$OLD_SCREAMING/$NEW_SCREAMING}"
    printf '%s\n' "$line" >> "$temp_file"
  done < "$file"

  file_mode="$(stat -c '%a' "$file" 2>/dev/null || stat -f '%Lp' "$file")"
  chmod "$file_mode" "$temp_file"
  mv "$temp_file" "$file"
}

while IFS= read -r -d '' relative; do
  file="$REPO_ROOT/$relative"
  [[ -L "$file" ]] && continue

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
    if $DRY_RUN; then
      echo "  would replace in: $relative"
    else
      replace_contents "$file"
      echo "  replaced in: $relative"
    fi
    ((file_count++)) || true
  fi
done < <(git -C "$REPO_ROOT" ls-files -co --exclude-standard -z)

echo "  $file_count files updated"

# ── Step 2: Rename files ────────────────────────────────────────────

echo ""
echo "=== Renaming files ==="
rename_count=0

while IFS= read -r -d '' relative; do
  file="$REPO_ROOT/$relative"
  [[ -L "$file" ]] && continue
  dir="$(dirname "$file")"
  base="$(basename "$file")"
  newbase="${base//$OLD_SNAKE/$NEW_SNAKE}"
  if [[ "$base" != "$newbase" ]]; then
    if $DRY_RUN; then
      echo "  would rename file: $relative -> $newbase"
    else
      if git -C "$REPO_ROOT" ls-files --error-unmatch -- "$relative" &>/dev/null; then
        target_dir="${relative%/*}"
        [[ "$target_dir" == "$relative" ]] && target_dir="."
        git -C "$REPO_ROOT" mv "$relative" "$target_dir/$newbase"
      else
        mv "$file" "$dir/$newbase"
      fi
      echo "  file: $relative -> $newbase"
    fi
    ((rename_count++)) || true
  fi
done < <(git -C "$REPO_ROOT" ls-files -co --exclude-standard -z -- "*${OLD_SNAKE}*")

echo "  $rename_count files renamed"

# ── Step 3: Rename directories (depth-first) ────────────────────────

echo ""
echo "=== Renaming directories ==="
dir_count=0

dirs=()
while IFS= read -r -d '' relative; do
  dir="$REPO_ROOT/$(dirname "$relative")"

  while [[ "$dir" != "$REPO_ROOT" ]]; do
    if [[ "$(basename "$dir")" == *"$OLD_SNAKE"* ]]; then
      already_seen=false
      for existing_dir in "${dirs[@]}"; do
        if [[ "$existing_dir" == "$dir" ]]; then
          already_seen=true
          break
        fi
      done

      if ! $already_seen; then
        dirs+=("$dir")
      fi
    fi
    dir="$(dirname "$dir")"
  done
done < <(git -C "$REPO_ROOT" ls-files -co --exclude-standard -z)

while ((${#dirs[@]} > 0)); do
  deepest_index=-1

  for index in "${!dirs[@]}"; do
    if ((deepest_index == -1 || ${#dirs[$index]} > ${#dirs[$deepest_index]})); then
      deepest_index="$index"
    fi
  done

  dir="${dirs[$deepest_index]}"
  unset 'dirs[deepest_index]'
  [[ -d "$dir" ]] || continue
  parent="$(dirname "$dir")"
  base="$(basename "$dir")"
  newbase="${base//$OLD_SNAKE/$NEW_SNAKE}"
  if [[ "$base" != "$newbase" ]]; then
    if $DRY_RUN; then
      echo "  would rename dir: ${dir#"$REPO_ROOT/"} -> $newbase"
    else
      if git -C "$REPO_ROOT" ls-files "${dir#"$REPO_ROOT/"}/" &>/dev/null 2>&1; then
        git -C "$REPO_ROOT" mv "$dir" "$parent/$newbase"
      else
        mv "$dir" "$parent/$newbase"
      fi
      echo "  dir:  ${dir#"$REPO_ROOT/"} -> $newbase"
    fi
    ((dir_count++)) || true
  fi
done

echo "  $dir_count directories renamed"

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
echo "  3. Run: mise run setup"

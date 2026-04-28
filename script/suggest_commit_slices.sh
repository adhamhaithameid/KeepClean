#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

git diff --name-only >> "$TMP_FILE"
git diff --cached --name-only >> "$TMP_FILE"
git ls-files --others --exclude-standard >> "$TMP_FILE"

sort -u "$TMP_FILE" -o "$TMP_FILE"

if [[ ! -s "$TMP_FILE" ]]; then
  echo "No local changes detected."
  exit 0
fi

print_group() {
  local title="$1"
  local commit_msg="$2"
  local pattern="$3"

  local matches
  matches="$(grep -E "$pattern" "$TMP_FILE" || true)"
  if [[ -z "$matches" ]]; then
    return 0
  fi

  local count
  count="$(printf '%s\n' "$matches" | sed '/^$/d' | wc -l | tr -d ' ')"

  echo "[$title] $count file(s)"
  printf '%s\n' "$matches" | sed 's/^/  - /'
  echo "  commit: $commit_msg"
  echo
}

echo "Suggested atomic slices:"
echo

print_group "CI" "ci: add or update workflow automation" '^\.github/workflows/'
print_group "Build Config" "build: sync project generation and Xcode config" '^(project\.yml|KeepClean\.xcodeproj/)'
print_group "App Core" "feat(app): wire core application state updates" '^KeepClean/App/'
print_group "Models" "feat(models): update app state and domain logic" '^KeepClean/Models/'
print_group "Services" "feat(services): extend system integration services" '^KeepClean/Services/'
print_group "Views" "feat(ui): refine tabs and interaction flows" '^KeepClean/Views/'
print_group "Assets" "chore(assets): refresh app icon and image resources" '^KeepClean/Resources/Assets\.xcassets/'
print_group "Unit Tests" "test(unit): align tests with new behavior" '^KeepCleanTests/'
print_group "UI Tests" "test(ui): update UI coverage for flow changes" '^KeepCleanUITests/'
print_group "Docs" "docs: update supporting documentation" '^docs/'

OTHER_MATCHES="$(grep -Ev '^(\.github/workflows/|project\.yml|KeepClean\.xcodeproj/|KeepClean/App/|KeepClean/Models/|KeepClean/Services/|KeepClean/Views/|KeepClean/Resources/Assets\.xcassets/|KeepCleanTests/|KeepCleanUITests/|docs/)' "$TMP_FILE" || true)"
if [[ -n "$OTHER_MATCHES" ]]; then
  echo "[Other] $(printf '%s\n' "$OTHER_MATCHES" | sed '/^$/d' | wc -l | tr -d ' ') file(s)"
  printf '%s\n' "$OTHER_MATCHES" | sed 's/^/  - /'
  echo "  commit: chore: reconcile miscellaneous repository updates"
  echo
fi

echo "Loop:"
echo "  1) git add -p <files in one slice>"
echo "  2) git diff --cached"
echo "  3) git commit"

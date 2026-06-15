#!/usr/bin/env bash
# shellcheck disable=SC2155
#
# update-defaults.sh — For each tool in neovim-pack, find the latest GitHub
# release (or npm version for prettier) that is older than 7 days. Update
# devcontainer-feature.json default values accordingly.
#
# Requires: curl, jq
# Optional: GITHUB_TOKEN env var (raises API rate limit from 60→5000/hr)
set -euo pipefail

FEATURE_JSON="src/neovim-pack/devcontainer-feature.json"
MIN_AGE_DAYS="${MIN_AGE_DAYS:-7}"

# ── GitHub repos → JSON option keys ──────────────────────────────────────────
# Format: "owner/repo optionKey"
GH_TOOLS=(
  "neovim/neovim neovimVersion"
  "BurntSushi/ripgrep ripgrepVersion"
  "dandavison/delta deltaVersion"
  "junegunn/fzf fzfVersion"
  "ast-grep/ast-grep astGrepVersion"
  "jesseduffield/lazygit lazygitVersion"
  "tree-sitter/tree-sitter treeSitterVersion"
  "sharkdp/fd fdVersion"
)

# ── Helpers ──────────────────────────────────────────────────────────────────

gh_api() {
  local url="$1"
  local -a curl_args=(curl -fsSL)
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl_args+=(-H "Authorization: token ${GITHUB_TOKEN}")
  fi
  curl_args+=("$url")
  "${curl_args[@]}"
}

# Find latest non-prerelease GH release older than $MIN_AGE_DAYS days.
# Returns tag name (e.g. "v0.10.0") or empty string.
gh_stable_version() {
  local repo="$1"
  local cutoff
  cutoff=$(date -u -d "${MIN_AGE_DAYS} days ago" +%s 2>/dev/null \
        || date -u -v-"${MIN_AGE_DAYS}"d +%s)  # GNU || BSD date

  local releases
  releases=$(gh_api "https://api.github.com/repos/${repo}/releases?per_page=30")

  echo "$releases" | jq -r --argjson cutoff "$cutoff" '
    [ .[] | select(.prerelease == false and .draft == false) ] |
    map(select((.published_at // .created_at) |
               sub("\\.[0-9]+Z$"; "Z") |
               strptime("%Y-%m-%dT%H:%M:%SZ") |
               mktime < $cutoff)) |
    first | .tag_name // empty
  '
}

# Find latest npm version older than $MIN_AGE_DAYS days.
npm_stable_version() {
  local package="$1"
  local cutoff
  cutoff=$(date -u -d "${MIN_AGE_DAYS} days ago" +%s 2>/dev/null \
        || date -u -v-"${MIN_AGE_DAYS}"d +%s)

  local registry
  registry=$(curl -fsSL "https://registry.npmjs.org/${package}")

  echo "$registry" | jq -r --argjson cutoff "$cutoff" '
    .time as $times |
    [ .versions | keys[] ] |
    map(select(. as $v |
      ($times[$v] // empty) |
      sub("\\.[0-9]+Z$"; "Z") |
      strptime("%Y-%m-%dT%H:%M:%SZ") |
      mktime < $cutoff
    )) |
    last // empty
  '
}

# ── Main ─────────────────────────────────────────────────────────────────────

changes=0

for entry in "${GH_TOOLS[@]}"; do
  repo="${entry% *}"
  option="${entry#* }"

  echo "Checking ${repo}..."
  version=$(gh_stable_version "$repo")

  if [[ -z "$version" ]]; then
    echo "  ⚠ No release older than ${MIN_AGE_DAYS}d found, keeping current default"
    continue
  fi

  current=$(jq -r ".options.${option}.default" "$FEATURE_JSON")
  if [[ "$current" == "$version" ]]; then
    echo "  ✓ Already at ${version}"
    continue
  fi

  echo "  → Updating ${option}: ${current} → ${version}"
  jq --arg opt "$option" --arg ver "$version" \
    '.options[$opt].default = $ver' "$FEATURE_JSON" > "${FEATURE_JSON}.tmp"
  mv "${FEATURE_JSON}.tmp" "$FEATURE_JSON"
  changes=$((changes + 1))
done

# Handle prettier (npm)
echo "Checking prettier (npm)..."
prettier_ver=$(npm_stable_version "prettier")

if [[ -n "$prettier_ver" ]]; then
  current=$(jq -r '.options.prettierVersion.default' "$FEATURE_JSON")
  if [[ "$current" != "$prettier_ver" ]]; then
    echo "  → Updating prettierVersion: ${current} → ${prettier_ver}"
    jq --arg ver "$prettier_ver" \
      '.options.prettierVersion.default = $ver' "$FEATURE_JSON" > "${FEATURE_JSON}.tmp"
    mv "${FEATURE_JSON}.tmp" "$FEATURE_JSON"
    changes=$((changes + 1))
  else
    echo "  ✓ Already at ${prettier_ver}"
  fi
else
  echo "  ⚠ No version older than ${MIN_AGE_DAYS}d found, keeping current default"
fi

echo ""
echo "Total changes: ${changes}"
echo "changes=${changes}" >> "${GITHUB_OUTPUT:-/dev/null}"

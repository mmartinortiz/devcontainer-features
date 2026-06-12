#!/usr/bin/env bash
set -euo pipefail

# Validate feature repository structure and content

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

ERRORS=0

echo "=== Validating feature repository ==="
echo ""

# Check for required files
echo "Checking required files..."
if [[ ! -f "src/neovim-pack/devcontainer-feature.json" ]]; then
  echo "✗ Missing: src/neovim-pack/devcontainer-feature.json"
  ((ERRORS++))
else
  echo "✓ src/neovim-pack/devcontainer-feature.json"
fi

if [[ ! -f "src/neovim-pack/install.sh" ]]; then
  echo "✗ Missing: src/neovim-pack/install.sh"
  ((ERRORS++))
else
  echo "✓ src/neovim-pack/install.sh"
fi

if [[ ! -f "src/neovim-pack/test/test.sh" ]]; then
  echo "✗ Missing: src/neovim-pack/test/test.sh"
  ((ERRORS++))
else
  echo "✓ src/neovim-pack/test/test.sh"
fi

echo ""
echo "Validating JSON schema..."
if ! command -v jq &>/dev/null; then
  echo "⚠ jq not found, skipping JSON validation"
else
  if ! jq empty "src/neovim-pack/devcontainer-feature.json"; then
    echo "✗ Invalid JSON: src/neovim-pack/devcontainer-feature.json"
    ((ERRORS++))
  else
    echo "✓ Valid JSON: src/neovim-pack/devcontainer-feature.json"
  fi
fi

echo ""
echo "Validating shell scripts..."
if ! command -v shellcheck &>/dev/null; then
  echo "⚠ shellcheck not found, skipping shell validation"
else
  for script in src/neovim-pack/install.sh src/neovim-pack/test/test.sh; do
    if shellcheck "$script"; then
      echo "✓ $script"
    else
      echo "✗ $script has shellcheck errors"
      ((ERRORS++))
    fi
  done
fi

echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo "✓ All validations passed"
  exit 0
else
  echo "✗ $ERRORS validation error(s) found"
  exit 1
fi

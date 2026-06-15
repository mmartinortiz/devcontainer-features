#!/usr/bin/env bash
set -euo pipefail

echo "=== Testing Neovim Pack ==="

# Test each binary exists and responds to --version
for cmd in nvim rg delta; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "✗ $cmd not found in PATH"
    exit 1
  fi
  
  if ! "$cmd" --version &>/dev/null; then
    echo "✗ $cmd --version failed"
    exit 1
  fi
  
  echo "✓ $cmd installed and working"
done

echo ""
echo "=== All tests passed ==="

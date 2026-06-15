#!/usr/bin/env bash
set -e

# Check all binaries exist and are executable
check() {
  if command -v "$1" > /dev/null 2>&1; then
    echo "PASS: $1 found at $(command -v "$1")"
  else
    echo "FAIL: $1 not found"
    exit 1
  fi
}

check nvim
check rg
check delta
check fzf
check sg
check lazygit
check tree-sitter
check fd

# Check alias files exist
check_file() {
  if [ -f "$1" ]; then
    echo "PASS: $1 exists"
  else
    echo "FAIL: $1 not found"
    exit 1
  fi
}

check_file /etc/profile.d/neovim-pack-aliases.sh
check_file /etc/fish/conf.d/neovim-pack-aliases.fish

echo "All checks passed!"

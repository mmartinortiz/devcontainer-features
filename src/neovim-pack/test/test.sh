#!/usr/bin/env bash
set -e

# Source nvm if installed (node feature sets up PATH in bash profile)
export NVM_DIR="${NVM_DIR:-/usr/local/share/nvm}"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Check all binaries exist and are executable
check() {
  if command -v "$1" >/dev/null 2>&1; then
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
check ast-grep
check lazygit
check fd
check pip3
check node
check npm

# Check alias files exist
check_file() {
  if [ -f "$1" ]; then
    echo "PASS: $1 exists"
  else
    echo "FAIL: $1 not found"
    exit 1
  fi
}

check_file /etc/profile.d/neovim-pack.sh
check_file /etc/fish/conf.d/neovim-pack.fish

echo "All checks passed!"

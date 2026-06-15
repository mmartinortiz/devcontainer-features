#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2154
set -e

source ./library_scripts.sh

# Set defaults for version variables
NEOVIM_VERSION="${NEOVIM_VERSION:-latest}"
RIPGREP_VERSION="${RIPGREP_VERSION:-latest}"
DELTA_VERSION="${DELTA_VERSION:-latest}"
FZF_VERSION="${FZF_VERSION:-latest}"
AST_GREP_VERSION="${AST_GREP_VERSION:-latest}"
LAZYGIT_VERSION="${LAZYGIT_VERSION:-latest}"
TREE_SITTER_VERSION="${TREE_SITTER_VERSION:-latest}"
FD_VERSION="${FD_VERSION:-latest}"

# Map uname -m to Go arch convention (fzf uses amd64/arm64)
case "$(uname -m)" in
  x86_64)  FZF_ARCH="amd64" ;;
  aarch64) FZF_ARCH="arm64" ;;
  *)       FZF_ARCH="$(uname -m)" ;;
esac

# Map uname -m for lazygit (x86_64 stays, aarch64 -> arm64)
case "$(uname -m)" in
  aarch64) LAZYGIT_ARCH="arm64" ;;
  *)       LAZYGIT_ARCH="$(uname -m)" ;;
esac

# Map uname -m for tree-sitter (x86_64 -> x64, aarch64 -> arm64)
case "$(uname -m)" in
  x86_64)  TREE_SITTER_ARCH="x64" ;;
  aarch64) TREE_SITTER_ARCH="arm64" ;;
  *)       TREE_SITTER_ARCH="$(uname -m)" ;;
esac

ensure_nanolayer nanolayer_location "0.5.6"

# Install neovim from GitHub releases
$nanolayer_location \
  install \
  devcontainer-feature \
  "ghcr.io/devcontainers-extra/features/gh-release:1" \
  --option repo='neovim/neovim' \
  --option binaryNames='nvim' \
  --option version="$NEOVIM_VERSION" \
  --option assetRegex="nvim-linux-$(uname -m)\.tar\.gz$"

# Install ripgrep from GitHub releases
$nanolayer_location \
  install \
  devcontainer-feature \
  "ghcr.io/devcontainers-extra/features/gh-release:1" \
  --option repo='BurntSushi/ripgrep' \
  --option binaryNames='rg' \
  --option version="$RIPGREP_VERSION" \
  --option assetRegex="$(uname -m)-unknown-linux-.*\.tar\.gz$"

# Install delta from GitHub releases
$nanolayer_location \
  install \
  devcontainer-feature \
  "ghcr.io/devcontainers-extra/features/gh-release:1" \
  --option repo='dandavison/delta' \
  --option binaryNames='delta' \
  --option version="$DELTA_VERSION" \
  --option assetRegex="$(uname -m)-unknown-linux-.*\.tar\.gz$"

# Install fzf from GitHub releases
$nanolayer_location \
  install \
  devcontainer-feature \
  "ghcr.io/devcontainers-extra/features/gh-release:1" \
  --option repo='junegunn/fzf' \
  --option binaryNames='fzf' \
  --option version="$FZF_VERSION" \
  --option assetRegex="linux_${FZF_ARCH}\.tar\.gz$"

# Install ast-grep from GitHub releases
$nanolayer_location \
  install \
  devcontainer-feature \
  "ghcr.io/devcontainers-extra/features/gh-release:1" \
  --option repo='ast-grep/ast-grep' \
  --option binaryNames='sg' \
  --option version="$AST_GREP_VERSION" \
  --option assetRegex="app-$(uname -m)-unknown-linux-gnu\.zip$"

# Install lazygit from GitHub releases
$nanolayer_location \
  install \
  devcontainer-feature \
  "ghcr.io/devcontainers-extra/features/gh-release:1" \
  --option repo='jesseduffield/lazygit' \
  --option binaryNames='lazygit' \
  --option version="$LAZYGIT_VERSION" \
  --option assetRegex="linux_${LAZYGIT_ARCH}\.tar\.gz$"

# Install tree-sitter CLI from GitHub releases
$nanolayer_location \
  install \
  devcontainer-feature \
  "ghcr.io/devcontainers-extra/features/gh-release:1" \
  --option repo='tree-sitter/tree-sitter' \
  --option binaryNames='tree-sitter' \
  --option version="$TREE_SITTER_VERSION" \
  --option assetRegex="tree-sitter-cli-linux-${TREE_SITTER_ARCH}\.zip$"

# Install fd from GitHub releases
$nanolayer_location \
  install \
  devcontainer-feature \
  "ghcr.io/devcontainers-extra/features/gh-release:1" \
  --option repo='sharkdp/fd' \
  --option binaryNames='fd' \
  --option version="$FD_VERSION" \
  --option assetRegex="$(uname -m)-unknown-linux-.*\.tar\.gz$"

# Set up shell aliases for bash/zsh
cat > /etc/profile.d/neovim-pack-aliases.sh << 'EOF'
alias vim='nvim'
alias vi='nvim'
alias v='nvim'
alias lg='lazygit'
EOF

# Set up shell aliases for fish
mkdir -p /etc/fish/conf.d
cat > /etc/fish/conf.d/neovim-pack-aliases.fish << 'EOF'
alias vim='nvim'
alias vi='nvim'
alias v='nvim'
alias lg='lazygit'
EOF

echo "Done!"

#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2154
set -e

source ./library_scripts.sh

# Map devcontainer framework env vars (NEOVIMVERSION) to our vars (NEOVIM_VERSION).
# Framework strips underscores from camelCase option names → all-uppercase no-underscore.
NEOVIM_VERSION="${NEOVIMVERSION:-${NEOVIM_VERSION:-latest}}"
RIPGREP_VERSION="${RIPGREPVERSION:-${RIPGREP_VERSION:-latest}}"
DELTA_VERSION="${DELTAVERSION:-${DELTA_VERSION:-latest}}"
FZF_VERSION="${FZFVERSION:-${FZF_VERSION:-latest}}"
AST_GREP_VERSION="${ASTGREPVERSION:-${AST_GREP_VERSION:-latest}}"
LAZYGIT_VERSION="${LAZYGITVERSION:-${LAZYGIT_VERSION:-latest}}"
FD_VERSION="${FDVERSION:-${FD_VERSION:-latest}}"

MACHINE_ARCH="$(uname -m)"
LIBC_TYPE="$(detect_libc)"

# ── Arch mappings ─────────────────────────────────────────────────────────────
# Neovim uses arm64 (not aarch64)
case "$MACHINE_ARCH" in aarch64) NVIM_ARCH="arm64" ;; *) NVIM_ARCH="$MACHINE_ARCH" ;; esac

# fzf uses Go convention: amd64/arm64
case "$MACHINE_ARCH" in x86_64) FZF_ARCH="amd64" ;; aarch64) FZF_ARCH="arm64" ;; *) FZF_ARCH="$MACHINE_ARCH" ;; esac

# lazygit: x86_64 stays, aarch64 -> arm64
case "$MACHINE_ARCH" in aarch64) LAZYGIT_ARCH="arm64" ;; *) LAZYGIT_ARCH="$MACHINE_ARCH" ;; esac

# ── Resolve "latest" tags (zero API calls — uses HTTP redirect) ──────────────
resolve_if_latest() {
  local version="$1" repo="$2"
  if [ "$version" = "latest" ]; then
    resolve_latest_tag "$repo"
  else
    echo "$version"
  fi
}

NEOVIM_VERSION=$(resolve_if_latest "$NEOVIM_VERSION" "neovim/neovim")
RIPGREP_VERSION=$(resolve_if_latest "$RIPGREP_VERSION" "BurntSushi/ripgrep")
DELTA_VERSION=$(resolve_if_latest "$DELTA_VERSION" "dandavison/delta")
FZF_VERSION=$(resolve_if_latest "$FZF_VERSION" "junegunn/fzf")
AST_GREP_VERSION=$(resolve_if_latest "$AST_GREP_VERSION" "ast-grep/ast-grep")
LAZYGIT_VERSION=$(resolve_if_latest "$LAZYGIT_VERSION" "jesseduffield/lazygit")
FD_VERSION=$(resolve_if_latest "$FD_VERSION" "sharkdp/fd")

# ── Helper: strip leading 'v' from tag ───────────────────────────────────────
strip_v() { echo "${1#v}"; }

# ── Install tools via direct download (zero API calls) ───────────────────────

# Neovim: nvim-linux-{arm64|x86_64}.tar.gz (no version in filename)
# Neovim needs full tree install (bin/nvim + lib/nvim/ + share/nvim/runtime/)
install_gh_release "neovim/neovim" "$NEOVIM_VERSION" \
  "nvim-linux-${NVIM_ARCH}.tar.gz" "nvim" "true"

# ripgrep: ripgrep-{ver}-{arch}-unknown-linux-musl.tar.gz
# Note: ripgrep ships x86_64 as musl-only (no gnu). musl binaries work on glibc systems.
RG_VER=$(strip_v "$RIPGREP_VERSION")
install_gh_release "BurntSushi/ripgrep" "$RIPGREP_VERSION" \
  "ripgrep-${RG_VER}-${MACHINE_ARCH}-unknown-linux-musl.tar.gz" "rg"

# delta: delta-{ver}-{arch}-unknown-linux-gnu.tar.gz
DELTA_VER=$(strip_v "$DELTA_VERSION")
install_gh_release "dandavison/delta" "$DELTA_VERSION" \
  "delta-${DELTA_VER}-${MACHINE_ARCH}-unknown-linux-${LIBC_TYPE}.tar.gz" "delta"

# fzf: fzf-{ver}-linux_{amd64|arm64}.tar.gz
FZF_VER=$(strip_v "$FZF_VERSION")
install_gh_release "junegunn/fzf" "$FZF_VERSION" \
  "fzf-${FZF_VER}-linux_${FZF_ARCH}.tar.gz" "fzf"

# ast-grep: app-{arch}-unknown-linux-gnu.zip (no version in filename)
install_gh_release "ast-grep/ast-grep" "$AST_GREP_VERSION" \
  "app-${MACHINE_ARCH}-unknown-linux-gnu.zip" "ast-grep"

# lazygit: lazygit_{ver}_linux_{x86_64|arm64}.tar.gz
LAZYGIT_VER=$(strip_v "$LAZYGIT_VERSION")
install_gh_release "jesseduffield/lazygit" "$LAZYGIT_VERSION" \
  "lazygit_${LAZYGIT_VER}_Linux_${LAZYGIT_ARCH}.tar.gz" "lazygit"

# fd: fd-{tag}-{arch}-unknown-linux-{gnu|musl}.tar.gz (tag keeps v prefix)
install_gh_release "sharkdp/fd" "$FD_VERSION" \
  "fd-${FD_VERSION}-${MACHINE_ARCH}-unknown-linux-${LIBC_TYPE}.tar.gz" "fd"

# Install pip if requested
if [ "${INSTALLPIP}" = "true" ]; then
  # Find python3 - check PATH first, then common install locations
  PYTHON3=""
  if command -v python3 >/dev/null 2>&1; then
    PYTHON3="python3"
  elif [ -x /usr/local/python/current/bin/python3 ]; then
    PYTHON3="/usr/local/python/current/bin/python3"
  elif [ -x /usr/bin/python3 ]; then
    PYTHON3="/usr/bin/python3"
  fi

  # Install python3 via apt if not found
  if [ -z "$PYTHON3" ]; then
    echo "python3 not found, installing via apt..."
    apt-get update -y && apt-get install -y --no-install-recommends python3
    PYTHON3="python3"
  fi

  # Best-effort upgrade (may fail on externally-managed environments)
  $PYTHON3 -m pip install --break-system-packages --upgrade pip 2>/dev/null || true
  apt-get update -y && apt-get install -y --no-install-recommends python3-pip python3-venv
fi

# Install Node.js if requested (only use that still needs nanolayer)
if [ "${INSTALLNODE}" = "true" ]; then
  ensure_nanolayer nanolayer_location "0.5.6"
  $nanolayer_location \
    install \
    devcontainer-feature \
    "ghcr.io/devcontainers/features/node:2" \
    --option version='lts'
fi

# Set up shell aliases and Mason PATH for bash/zsh
cat >/etc/profile.d/neovim-pack.sh <<'EOF'
alias vim='nvim'
alias vi='nvim'
alias v='nvim'
alias lg='lazygit'
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"
EOF

# Set up shell aliases and Mason PATH for fish
mkdir -p /etc/fish/conf.d
cat >/etc/fish/conf.d/neovim-pack.fish <<'EOF'
alias vim='nvim'
alias vi='nvim'
alias v='nvim'
alias lg='lazygit'
fish_add_path -g $HOME/.local/share/nvim/mason/bin
EOF

echo "Done!"

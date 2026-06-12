#!/usr/bin/env bash
set -euo pipefail

# Neovim Pack: Install Neovim, ast-grep, fzf, and Prettier from GitHub releases

NEOVIM_VERSION=${NEOVIMVERSION:-latest}
ASTGREP_VERSION=${ASTGREPVERSION:-latest}
FZF_VERSION=${FZFVERSION:-latest}
PRETTIER_VERSION=${PRETTIERVERSION:-latest}

ARCH=$(uname -m)

# Map uname arch to GitHub release asset names
case "${ARCH}" in
  x86_64)
    ARCH_GH="x86_64"
    ARCH_FZF="amd64"
    ;;
  aarch64)
    ARCH_GH="aarch64"
    ARCH_FZF="arm64"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

echo "Detected architecture: $ARCH (GH: $ARCH_GH, fzf: $ARCH_FZF)"

# Helper: Resolve "latest" version tag
resolve_latest_version() {
  local repo=$1
  local response
  response=$(curl -s -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${repo}/releases/latest")
  
  if echo "$response" | grep -q "API rate limit exceeded"; then
    echo "Error: GitHub API rate limit exceeded"
    exit 1
  fi
  
  if echo "$response" | grep -q '"message": "Not Found"'; then
    echo "Error: No releases found for $repo"
    exit 1
  fi
  
  echo "$response" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4 | head -1
}

# Helper: Download binary from GitHub release
download_gh_release() {
  local repo=$1
  local version=$2
  local asset_name=$3
  local tmp_file=$4
  
  local url="https://github.com/${repo}/releases/download/${version}/${asset_name}"
  echo "Downloading from: $url"
  
  if ! curl -sSL "$url" -o "$tmp_file" 2>&1 | grep -v "100"; then
    echo "Error: Failed to download $asset_name"
    rm -f "$tmp_file"
    exit 1
  fi
}

# Helper: Install binary to /usr/local/bin
install_binary() {
  local tmp_path=$1
  local binary_name=$2
  local dest="/usr/local/bin/${binary_name}"
  
  # Handle different file types
  if [[ "$tmp_path" == *.tar.gz ]]; then
    tar -xzf "$tmp_path" -C /tmp/
    if [[ -f "/tmp/${binary_name}" ]]; then
      mv "/tmp/${binary_name}" "$dest"
    else
      echo "Error: $binary_name not found in tarball"
      exit 1
    fi
  elif [[ "$tmp_path" == *.AppImage ]]; then
    cp "$tmp_path" "$dest"
  elif [[ "$tmp_path" == *.zip ]]; then
    unzip -p "$tmp_path" "$binary_name" > "$dest" 2>/dev/null || {
      echo "Error: Failed to extract $binary_name from zip"
      exit 1
    }
  else
    # Plain binary
    cp "$tmp_path" "$dest"
  fi
  
  chmod +x "$dest"
  rm -f "$tmp_path"
}

# ============================================================================
# Install Neovim
# ============================================================================
echo ""
echo "=== Installing Neovim ==="

if [ "$NEOVIM_VERSION" = "latest" ]; then
  NEOVIM_VERSION=$(resolve_latest_version "neovim/neovim")
  echo "Resolved neovim latest to: $NEOVIM_VERSION"
fi

NEOVIM_ASSET="nvim-linux-${ARCH_GH}.AppImage"
download_gh_release "neovim/neovim" "$NEOVIM_VERSION" "$NEOVIM_ASSET" "/tmp/nvim.AppImage"
install_binary "/tmp/nvim.AppImage" "nvim"

if ! nvim --version | head -1; then
  echo "Error: Failed to verify Neovim installation"
  exit 1
fi
echo "✓ Neovim installed"

# ============================================================================
# Install ast-grep
# ============================================================================
echo ""
echo "=== Installing ast-grep ==="

if [ "$ASTGREP_VERSION" = "latest" ]; then
  ASTGREP_VERSION=$(resolve_latest_version "ast-grep/ast-grep")
  echo "Resolved ast-grep latest to: $ASTGREP_VERSION"
fi

# ast-grep asset name (no version in asset)
ASTGREP_ASSET="ast-grep-${ARCH_GH}-unknown-linux-gnu"
download_gh_release "ast-grep/ast-grep" "$ASTGREP_VERSION" "$ASTGREP_ASSET" "/tmp/sg"
install_binary "/tmp/sg" "sg"

if ! sg --version; then
  echo "Error: Failed to verify ast-grep installation"
  exit 1
fi
echo "✓ ast-grep installed"

# ============================================================================
# Install fzf
# ============================================================================
echo ""
echo "=== Installing fzf ==="

if [ "$FZF_VERSION" = "latest" ]; then
  FZF_VERSION=$(resolve_latest_version "junegunn/fzf")
  echo "Resolved fzf latest to: $FZF_VERSION"
fi

# fzf asset name includes version without 'v' prefix
FZF_CLEAN=${FZF_VERSION#v}
FZF_ASSET="fzf-${FZF_CLEAN}-linux_${ARCH_FZF}.tar.gz"
download_gh_release "junegunn/fzf" "$FZF_VERSION" "$FZF_ASSET" "/tmp/fzf.tar.gz"
install_binary "/tmp/fzf.tar.gz" "fzf"

if ! fzf --version; then
  echo "Error: Failed to verify fzf installation"
  exit 1
fi
echo "✓ fzf installed"

# ============================================================================
# Install Prettier
# ============================================================================
echo ""
echo "=== Installing Prettier ==="

if [ "$PRETTIER_VERSION" = "latest" ]; then
  PRETTIER_VERSION=$(resolve_latest_version "prettier/prettier")
  echo "Resolved prettier latest to: $PRETTIER_VERSION"
fi

# Prettier asset name includes version without 'v' prefix
PRETTIER_CLEAN=${PRETTIER_VERSION#v}
PRETTIER_ASSET="prettier-${PRETTIER_CLEAN}-node-v18-linux-x64"

# Try to download from GitHub releases
if download_gh_release "prettier/prettier" "$PRETTIER_VERSION" "$PRETTIER_ASSET" "/tmp/prettier-node.tar.gz" 2>&1; then
  tar -xzf "/tmp/prettier-node.tar.gz" -C /tmp/ || {
    echo "Warning: Could not extract prettier tarball, trying alternative method"
    rm -f "/tmp/prettier-node.tar.gz"
  }
fi

# Check if prettier was extracted
if [[ ! -f "/tmp/prettier/prettier.cjs" ]]; then
  # Fallback: try npm installation if available
  if command -v npm &>/dev/null; then
    echo "Installing Prettier via npm..."
    npm install -g "prettier@${PRETTIER_VERSION_CLEAN}" || {
      echo "Error: Failed to install Prettier"
      exit 1
    }
  else
    echo "Error: Could not find Prettier binary and npm not available"
    exit 1
  fi
else
  # Use Node.js wrapper if available, or create symlink
  if command -v node &>/dev/null; then
    cat > /usr/local/bin/prettier << 'PRETTIER_WRAPPER'
#!/usr/bin/env node
require('/tmp/prettier/prettier.cjs');
PRETTIER_WRAPPER
    chmod +x /usr/local/bin/prettier
  else
    cp "/tmp/prettier/prettier.cjs" /usr/local/bin/prettier
    chmod +x /usr/local/bin/prettier
  fi
fi

if ! prettier --version; then
  echo "Error: Failed to verify Prettier installation"
  exit 1
fi
echo "✓ Prettier installed"

# ============================================================================
# Final verification
# ============================================================================
echo ""
echo "=== Verifying all tools ==="
for cmd in nvim sg fzf prettier; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd not found in PATH"
    exit 1
  fi
  echo "✓ $cmd available"
done

echo ""
echo "=== All tools installed successfully ==="
nvim --version | head -1
sg --version
fzf --version
prettier --version

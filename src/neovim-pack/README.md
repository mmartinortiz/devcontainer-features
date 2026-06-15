# Neovim Pack

Install **Neovim** and essential CLI tools from GitHub releases in one feature. Designed for LazyVim-based devcontainer setups.

## What's Included

| Tool | Binary | Source |
|------|--------|--------|
| [Neovim](https://neovim.io/) | `nvim` | GitHub release |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | `rg` | GitHub release |
| [delta](https://github.com/dandavison/delta) | `delta` | GitHub release |
| [fzf](https://github.com/junegunn/fzf) | `fzf` | GitHub release |
| [ast-grep](https://ast-grep.github.io/) | `ast-grep` | GitHub release |
| [lazygit](https://github.com/jesseduffield/lazygit) | `lazygit` | GitHub release |
| [tree-sitter](https://github.com/tree-sitter/tree-sitter) | `tree-sitter` | GitHub release |
| [fd](https://github.com/sharkdp/fd) | `fd` | GitHub release |
| [shfmt](https://github.com/mvdan/sh) | `shfmt` | GitHub release |
| [Prettier](https://prettier.io/) | `prettier` | npm (installs Node.js if needed) |

Shell aliases are set up for all shells (bash, zsh, fish):

- `vim`, `vi`, `v` → `nvim`
- `lg` → `lazygit`

Mason's bin directory (`~/.local/share/nvim/mason/bin`) is added to PATH for all shells, so Mason-installed LSPs, formatters, and linters are available system-wide.

## Quick Start

Add to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/mmartinortiz/devcontainer-features/neovim-pack:1": {}
  }
}
```

## Version Selection

All tools default to `latest`. Pin specific versions as needed:

```json
{
  "features": {
    "ghcr.io/mmartinortiz/devcontainer-features/neovim-pack:1": {
      "neovimVersion": "v0.10.0",
      "ripgrepVersion": "15.1.0",
      "deltaVersion": "0.19.2",
      "fzfVersion": "v0.73.1",
      "astGrepVersion": "0.43.0",
      "lazygitVersion": "v0.62.2",
      "treeSitterVersion": "v0.26.9",
      "fdVersion": "v10.4.2",
      "shfmtVersion": "v3.13.1",
      "prettierVersion": "3.5.3"
    }
  }
}
```

Versions are resolved from GitHub releases API. If a version is unavailable, the feature fails loudly.

## Configuration: Mounting Host Dotfiles

This feature doesn't enforce config file mounts. You control where your configs come from via `devcontainer.json`.

### Recommended Mounts (Optional)

Mount your host LazyVim config and plugin data to persist across container rebuilds.

> **Note:** The mount target path depends on the user configured in your devcontainer. Microsoft base images typically use `vscode` as the default user. Adjust the target path to match your `remoteUser` (e.g., `/root` for root, `/home/vscode` for the vscode user).

```json
{
  "features": {
    "ghcr.io/mmartinortiz/devcontainer-features/neovim-pack:1": {}
  },
  "mounts": [
    "source=${localEnv:HOME}/.config/nvim,target=/home/vscode/.config/nvim,type=bind",
    "source=${localEnv:HOME}/.local/share/nvim,target=/home/vscode/.local/share/nvim,type=bind"
  ]
}
```

### Without Mounts

Config directories start empty. You can initialize configs inside the container.

## Troubleshooting

### "GitHub API rate limit exceeded"

The feature queries GitHub API to resolve `latest` versions. If rate-limited:

- Pin specific versions instead of `"latest"`
- Run feature again after rate limit resets (typically 1 hour for anonymous requests)

### Binary not found in PATH

Verify installation completed:

```bash
which nvim rg delta fzf ast-grep lazygit tree-sitter fd shfmt prettier
```

Check error logs during container build.

### Prettier installation failed

Prettier is installed via npm. If Node.js is not present in the base image, the feature installs it via apt automatically.

## Example devcontainer.json

```json
{
  "name": "Development",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/mmartinortiz/devcontainer-features/neovim-pack:1": {}
  },
  "mounts": [
    "source=${localEnv:HOME}/.config/nvim,target=/home/vscode/.config/nvim,type=bind",
    "source=${localEnv:HOME}/.local/share/nvim,target=/home/vscode/.local/share/nvim,type=bind"
  ]
}
```

## Supported Architectures

- **x86_64** (Intel/AMD 64-bit)
- **aarch64** (ARM 64-bit)

## Supported Base Images

Tested on Debian-based images:

- `ubuntu:22.04`
- `ubuntu:24.04`
- `debian:12`

Works on any Debian/Ubuntu-based image with `curl` available.

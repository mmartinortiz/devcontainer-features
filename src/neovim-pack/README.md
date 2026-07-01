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
| [fd](https://github.com/sharkdp/fd) | `fd` | GitHub release |

### Optional Tools

| Tool | Option | Source | Requirement |
|------|--------|--------|-------------|
| pip | `"installPip": true` | ensurepip / apt | none (installs python3 if needed) |
| [Node.js](https://nodejs.org/) | `"installNode": true` | [devcontainers/features/node](https://github.com/devcontainers/features/tree/main/src/node) | none (includes npm) |

> **Note:** pip is installed for Neovim/Mason tooling, not for general Python development. If python3 is not present in the base image, it will be installed via apt automatically. `python3-venv` is also installed if not already available, enabling virtual environment support for Mason and other tools.

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
      "fdVersion": "v10.4.2",
      "installPip": true,
      "installNode": true
    }
  }
}
```

Versions are resolved via GitHub releases (HTTP redirect, no API calls). If a version is unavailable, the feature fails loudly.

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

### "latest" version resolution fails

The feature resolves `latest` via an HTTP redirect from GitHub (`/releases/latest` → 302). No API calls are made. If resolution fails:

- Pin specific versions instead of `"latest"`
- Check network connectivity to `github.com`

### Binary not found in PATH

Verify installation completed:

```bash
which nvim rg delta fzf ast-grep lazygit fd
```

Check error logs during container build.

### pip installation failed

If python3 is not found, it is installed via apt automatically. If ensurepip also fails, pip is installed via `apt-get install python3-pip`. `python3-venv` is installed when not already present (needed by Mason for virtual environments). Check the container build logs for details.

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

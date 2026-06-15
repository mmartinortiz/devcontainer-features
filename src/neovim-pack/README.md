# Neovim Pack

Install **Neovim**, **ast-grep**, **fzf**, and **Prettier** from GitHub releases in one feature.

## What's Included

- **Neovim** (nvim): Hyperextensible Vim-based text editor
- **ast-grep** (sg): Fast and polyglot tool for code searching, linting, rewriting
- **fzf**: Fuzzy finder command-line tool
- **Prettier**: Code formatter supporting multiple languages

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

Control which version of each tool to install:

```json
{
  "features": {
    "ghcr.io/mmartinortiz/devcontainer-features/neovim-pack:1": {
      "neovimVersion": "latest",
      "astGrepVersion": "latest",
      "fzfVersion": "latest",
      "prettierVersion": "latest"
    }
  }
}
```

### Version Examples

- **Latest**: `"latest"` (default) — fetches current release
- **Specific version**: `"v0.10.0"` for Neovim, `"0.25.0"` for ast-grep, etc.

Versions are resolved from GitHub releases API. If a version is unavailable, the feature fails loudly.

## Configuration: Mounting Host Dotfiles

This feature doesn't enforce config file mounts. You control where your configs come from via `devcontainer.json`.

### Recommended Mounts (Optional)

Mount your host dotfiles to persist editor/tool configuration:

```json
{
  "features": {
    "ghcr.io/mmartinortiz/devcontainer-features/neovim-pack:1": {}
  },
  "mounts": [
    "source=${localEnv:HOME}/.config/nvim,target=/root/.config/nvim,type=bind",
    "source=${localEnv:HOME}/.config/fzf,target=/root/.config/fzf,type=bind",
    "source=${localEnv:HOME}/.local/share/nvim,target=/root/.local/share/nvim,type=bind"
  ]
}
```

### Without Mounts

The feature creates `/root/.config` directories for each tool, but they start empty. You can initialize configs inside the container.

## Troubleshooting

### "GitHub API rate limit exceeded"

The feature queries GitHub API to resolve `latest` versions. If rate-limited:

- Pin specific versions instead of `"latest"`
- Run feature again after rate limit resets (typically 1 hour for anonymous requests)

### Binary not found in PATH

Verify installation completed:

```bash
which nvim sg fzf prettier
```

Check error logs during container build.

### Prettier installation failed

If GitHub release asset unavailable, feature attempts npm fallback. Requires Node.js in base image.

## Example devcontainer.json

```json
{
  "name": "Development",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/mmartinortiz/devcontainer-features/neovim-pack:1": {
      "neovimVersion": "v0.10.0",
      "astGrepVersion": "0.25.0",
      "fzfVersion": "latest",
      "prettierVersion": "latest"
    }
  },
  "mounts": [
    "source=${localEnv:HOME}/.config/nvim,target=/root/.config/nvim,type=bind"
  ],
  "customizations": {
    "vscode": {
      "extensions": ["neovim.nvim"]
    }
  }
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

## More Information

- [Neovim](https://neovim.io/)
- [ast-grep](https://ast-grep.github.io/)
- [fzf](https://github.com/junegunn/fzf)
- [Prettier](https://prettier.io/)

# Devcontainer Features

A minimal collection of development tools packaged as DevContainer features, installable from GitHub releases.

## Features

### neovim-pack

Install **Neovim**, **ripgrep**, **delta**, **fzf**, **ast-grep**, **lazygit**, **tree-sitter**, **fd**, **shfmt**, and **Prettier** from GitHub releases in a single feature.

```json
{
  "features": {
    "ghcr.io/mmartinortiz/devcontainer-features/neovim-pack:1": {}
  }
}
```

**Features included:**

- Neovim (nvim) — Hyperextensible Vim-based text editor
- ripgrep (rg) — Fast regex search tool
- delta — Syntax-highlighting pager for git diffs
- fzf — Fuzzy finder for command line
- ast-grep (ast-grep) — Fast code search and rewriting tool
- lazygit — Terminal UI for git
- tree-sitter — Parser generator and incremental parsing library
- fd — Fast file finder
- shfmt — Shell script formatter
- Prettier — Code formatter (installed via npm)

[Read full documentation →](./src/neovim-pack/README.md)

## Quick Start

Add to your `devcontainer.json`:

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/mmartinortiz/devcontainer-features/neovim-pack:1": {
      "neovimVersion": "latest",
      "ripgrepVersion": "latest",
      "deltaVersion": "latest",
      "fzfVersion": "latest",
      "astGrepVersion": "latest",
      "lazygitVersion": "latest",
      "treeSitterVersion": "latest",
      "fdVersion": "latest",
      "shfmtVersion": "latest",
      "prettierVersion": "latest"
    }
  }
}
```

## Version Pinning

Control which version of each tool to install:

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

Default: `latest` (fetches current release)

## Supported Architectures

- `x86_64` (Intel/AMD 64-bit)
- `aarch64` (ARM 64-bit)

## Supported Base Images

Tested on Debian-based images:

- `ubuntu:22.04`
- `ubuntu:24.04`
- `debian:12`

Any Debian/Ubuntu-based image with `curl` available.

## Development

### Local Testing

```bash
./scripts/test-local.sh
```

This builds a test container and runs the feature installation.

### Validation

```bash
./scripts/validate.sh
```

Validates JSON schema and shell scripts.

### Repository Structure

```
src/
  └── neovim-pack/
      ├── devcontainer-feature.json      # Feature metadata
      ├── install.sh                     # Installation script
      ├── README.md                      # Feature documentation
      └── test/
          └── test.sh                    # Test script

scripts/
  ├── validate.sh                        # Validate repository
  └── test-local.sh                      # Local testing

test/
  ├── common.sh                          # Shared test utilities
  └── Dockerfile.test                    # Test image

.github/workflows/
  ├── test.yml                           # Run tests on PR/push
  ├── validate.yml                       # Validate on PR
  └── release.yml                        # Release on tag (v*)
```

## Release Process

1. Update feature version in `src/neovim-pack/devcontainer-feature.json`
2. Commit changes
3. Tag release: `git tag v1.0.0`
4. Push: `git push origin v1.0.0`
5. GitHub Actions builds and publishes to GHCR

Features are published as:

- `ghcr.io/mmartinortiz/devcontainer-features/neovim-pack:1` (major)
- `ghcr.io/mmartinortiz/devcontainer-features/neovim-pack:1.0.0` (full version)
- `ghcr.io/mmartinortiz/devcontainer-features/neovim-pack:latest`

## See Also

- [DevContainer Spec](https://containers.dev/)
- [Features Overview](https://containers.dev/implementors/features/)
- [DevContainer CLI](https://github.com/devcontainers/cli)

## License

MIT — See [LICENSE](./LICENSE)

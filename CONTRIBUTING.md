# Contributing

Contributions welcome! This guide explains how to modify or add features.

## Development Setup

1. Clone repo
2. Open in devcontainer (or manually install: git, curl, jq, shellcheck, docker)
3. Run local tests: `./scripts/test-local.sh`

## Testing Changes Locally

### Quick validation

```bash
./scripts/validate.sh
```

Checks JSON schema and shell script syntax.

### Full test (runs in Docker)

```bash
./scripts/test-local.sh
```

Builds a container and runs:
1. `src/neovim-pack/install.sh` — installs all tools
2. `src/neovim-pack/test/test.sh` — verifies tools work

## Modifying neovim-pack

### Edit installation script

File: `src/neovim-pack/install.sh`

**Key sections:**
- Architecture detection (x86_64 / aarch64)
- Tool-specific asset patterns (hard-coded per tool)
- Version resolution from GitHub API
- Binary download and extraction

**Important:**
- Fail loudly on errors (`set -euo pipefail`)
- Make scripts idempotent (safe to re-run)
- Test on multiple architectures if possible

### Add a new tool

1. Add new option to `src/neovim-pack/devcontainer-feature.json`:
   ```json
   "newToolVersion": {
     "type": "string",
     "default": "latest",
     "description": "New Tool version"
   }
   ```

2. Add installation logic to `src/neovim-pack/install.sh`:
   ```bash
   NEWTOOL_VERSION=${NEWTOOLVERSION:-latest}
   
   if [ "$NEWTOOL_VERSION" = "latest" ]; then
     NEWTOOL_VERSION=$(resolve_latest_version "owner/repo")
   fi
   
   download_and_install ...
   ```

3. Add verification to `src/neovim-pack/test/test.sh`:
   ```bash
   command -v newtool >/dev/null || exit 1
   newtool --version || exit 1
   ```

4. Update feature version in `devcontainer-feature.json` (bump minor)

5. Test locally: `./scripts/test-local.sh`

### Update feature documentation

File: `src/neovim-pack/README.md`

Keep documentation in sync with changes. Include:
- What's included
- Version options
- Configuration examples
- Troubleshooting tips

## Versioning

Feature versions are **independent** of tool versions.

**Semantic versioning:**
- `1.0.0` — initial release
- `1.1.0` — minor feature addition (new tool, new option)
- `1.0.1` — patch (bug fix, script improvement)

Bump version in `src/neovim-pack/devcontainer-feature.json` before releasing.

## Release Process

1. Make changes and test locally
2. Update version in `devcontainer-feature.json`
3. Commit: `git commit -am "Feature: description"`
4. Tag: `git tag v1.x.y`
5. Push: `git push origin main && git push origin v1.x.y`

GitHub Actions automatically:
- Validates and tests
- Builds and publishes to GHCR
- Creates release notes

After release, users reference:
```json
{
  "features": {
    "ghcr.io/mmartinortiz/devcontainer-features/neovim-pack:1": {}
  }
}
```

## Debugging

### Feature not installing

1. Check script syntax: `shellcheck src/neovim-pack/install.sh`
2. Run locally with debug: `bash -x src/neovim-pack/install.sh`
3. Check Docker build: `./scripts/test-local.sh`

### Binary not in PATH

Add verification to install script:
```bash
if ! command -v nvim &>/dev/null; then
  echo "nvim not found in PATH"
  exit 1
fi
```

### GitHub API rate limit

Feature resolves `latest` versions via API. If rate-limited:
- Pin specific versions for testing
- Implement local caching if needed

## Questions?

File an issue or discussion on GitHub.

# AGENTS.md

Devcontainer features mono-repo. Single feature: `neovim-pack` (nvim + ripgrep + delta).

## Commands

**Validate only** (fast):

```bash
./scripts/validate.sh
```

Checks JSON schema + shellcheck. No Docker needed.

**Full test** (builds container, runs install + tests):

```bash
./scripts/test-local.sh
```

Requires Docker. Tests `src/neovim-pack/install.sh` → `src/neovim-pack/test/test.sh`.

**Release** (push to GHCR):

```bash
git tag v1.x.y
git push origin main && git push origin v1.x.y
```

GitHub Actions auto-validates, tests, publishes to `ghcr.io/mmartinortiz/devcontainer-features/neovim-pack:MAJOR`.

## Key Files

| File                                        | Purpose                                                                                                                                                                                                 |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `src/neovim-pack/install.sh`                | **~44 lines.** Minimal wrapper. Sources `library_scripts.sh`, sets up nanolayer, delegates tool installation to gh-release feature (3 `nanolayer install gh-release` calls for neovim, ripgrep, delta). |
| `src/neovim-pack/library_scripts.sh`        | Shared helpers: `clean_download()` (curl/wget/apt-fallback), `ensure_nanolayer()` (downloads nanolayer from GH). ~173 lines.                                                                            |
| `src/neovim-pack/devcontainer-feature.json` | Feature metadata. **camelCase options** (neovimVersion, ripgrepVersion, deltaVersion + stale: astGrepVersion, fzfVersion, prettierVersion). Version **1.1.0**.                                          |
| `src/neovim-pack/test/test.sh`              | Currently empty.                                                                                                                                                                                        |
| `src/neovim-pack/README.md`                 | User docs: usage, version pinning, hybrid config mount guidance.                                                                                                                                        |

## Architecture (v1.1.0+)

**Delegates to gh-release feature.** install.sh orchestrates nanolayer, which invokes gh-release from devcontainers-extra (`ghcr.io/devcontainers-extra/features/gh-release:1`). gh-release handles: download, extract, binary placement in PATH, asset filtering.

**Installed tools (3):**

- **Neovim** (`neovim/neovim`): `--assetRegex "nvim-linux-$(uname -m)\.tar\.gz$"` — binary: `nvim`
- **ripgrep** (`BurntSushi/ripgrep`): `--assetRegex "$(uname -m)-unknown-linux-.*\.tar\.gz$"` — binary: `rg`
- **delta** (`dandavison/delta`): `--assetRegex "$(uname -m)-unknown-linux-.*\.tar\.gz$"` — binary: `delta`

**Version handling:**

- All default to `latest`
- Users can override via feature options (neovimVersion, ripgrepVersion, deltaVersion)

## Conventions

**Version envvar mapping:** camelCase option → UPPERCASE envvar. `neovimVersion` → `NEOVIM_VERSION`.

**Feature version independent of tool versions.** Semantic versioning: bump minor for new tool/arch changes, patch for version bumps.

**Fail loudly.** `set -e`. No silent failures.

**Idempotent.** Safe to re-run install.sh.

**Hybrid config mounts.** Feature doesn't enforce mounts. README documents recommended mounts (e.g., `~/.config/nvim` → `/root/.config/nvim`). User controls via devcontainer.json.

**Prefer GitHub releases.** New tools should be installed via `nanolayer install gh-release` using the `ghcr.io/devcontainers-extra/features/gh-release:1` feature. Avoid apt/npm/pip/snap when a GitHub release with prebuilt binaries exists. gh-release gives version pinning, cross-arch support, and no package manager dependencies.

## Common Gotchas

**GitHub API rate-limit (60/hr anonymous):** Tests may fail if running multiple times. Solution: use pinned versions.

**gh-release asset ambiguity:** Multiple matches error if assetRegex too loose. Use anchors: `\.tar\.gz$` not just `tar.gz`.

**Stale JSON options:** `devcontainer-feature.json` still lists astGrepVersion, fzfVersion, prettierVersion but install.sh no longer installs these tools. Clean up when convenient.

## Expand

To add tool to neovim-pack:

1. Add camelCase option to `devcontainer-feature.json`
2. Add default + env var to install.sh
3. Add `nanolayer install gh-release` call with correct repo, binaryNames, assetRegex
4. Prefer GitHub releases over package managers (npm/apt/pip)
5. Handle arch-specific quirks via `--assetRegex` if needed
6. Add binary check to `test/test.sh`
7. Bump feature minor version
8. Test: `./scripts/validate.sh && ./scripts/test-local.sh`

## Use Caveman Skill

All OpenCode sessions use caveman (full). Drop filler, keep technical substance.

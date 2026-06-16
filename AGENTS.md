# AGENTS.md

Devcontainer features mono-repo. Single feature: `neovim-pack` (nvim + rg + delta + fzf + ast-grep + lazygit + fd + optional pip/node).

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
| `src/neovim-pack/install.sh`                | ~140 lines. Sources `library_scripts.sh`, direct-downloads 7 tools via `install_gh_release` (zero API calls) + optional pip/node. Sets shell aliases + Mason PATH. |
| `src/neovim-pack/library_scripts.sh`        | Shared helpers: `clean_download()` (curl/wget/apt-fallback), `detect_libc()` (gnu/musl), `resolve_latest_tag()` (HTTP redirect, no API), `install_gh_release()` (download+extract+install binary), `ensure_nanolayer()` (only for Node.js). |
| `src/neovim-pack/devcontainer-feature.json` | Feature metadata. **camelCase options** (neovimVersion, ripgrepVersion, deltaVersion, fzfVersion, astGrepVersion, lazygitVersion, fdVersion, installPip, installNode). Version **1.10.0**. |
| `src/neovim-pack/test/test.sh`              | Currently empty. |
| `src/neovim-pack/README.md`                 | User docs: usage, version pinning, hybrid config mount guidance. |

## Architecture (v1.10.0)

**Direct download — zero GitHub API calls.** install.sh constructs direct download URLs for each tool's GitHub release asset. Version resolution for `latest` uses HTTP redirect trick (`/releases/latest` → 302 → `/releases/tag/{tag}`), not the API. Libc auto-detected (`gnu`/`musl`) via `detect_libc()`.

**Nanolayer only used for Node.js** (`ghcr.io/devcontainers/features/node:2` via `ensure_nanolayer`). Not loaded unless `installNode=true`.

**Installed tools (7 direct-download):**

- **Neovim** (`neovim/neovim`): `nvim-linux-{arm64|x86_64}.tar.gz` — binary: `nvim`
- **ripgrep** (`BurntSushi/ripgrep`): `ripgrep-{ver}-{arch}-unknown-linux-{gnu|musl}.tar.gz` — binary: `rg`
- **delta** (`dandavison/delta`): `delta-{ver}-{arch}-unknown-linux-{gnu|musl}.tar.gz` — binary: `delta`
- **fzf** (`junegunn/fzf`): `fzf-{ver}-linux_{amd64|arm64}.tar.gz` — binary: `fzf`
- **ast-grep** (`ast-grep/ast-grep`): `app-{arch}-unknown-linux-gnu.zip` — binary: `ast-grep`
- **lazygit** (`jesseduffield/lazygit`): `lazygit_{ver}_Linux_{x86_64|arm64}.tar.gz` — binary: `lazygit`
- **fd** (`sharkdp/fd`): `fd-{tag}-{arch}-unknown-linux-{gnu|musl}.tar.gz` — binary: `fd`

**Optional tools:**

- **pip**: installed via `python3 -m ensurepip` if `installPip` is `true`. Requires python3 in base image. Does not install python3.
- **Node.js**: installed via `ghcr.io/devcontainers/features/node:2` if `installNode` is `true`.

**Shell setup:**

- Aliases: `vim`/`vi`/`v` → `nvim`, `lg` → `lazygit` (bash, zsh, fish)
- Mason PATH: `~/.local/share/nvim/mason/bin` added to PATH (all shells)

**Version handling:**

- All default to `latest` in install.sh
- Users can override via feature options (camelCase in JSON)

## Conventions

**Version envvar mapping:** camelCase option → UPPERCASE envvar. `neovimVersion` → `NEOVIM_VERSION`.

**Feature version independent of tool versions.** Semantic versioning: bump minor for new tool/arch changes, patch for version bumps.

**Fail loudly.** `set -e`. No silent failures.

**Idempotent.** Safe to re-run install.sh.

**Hybrid config mounts.** Feature doesn't enforce mounts. README documents recommended mounts (e.g., `~/.config/nvim` → `/home/vscode/.config/nvim`). Mount target depends on devcontainer user. User controls via devcontainer.json.

**Prefer GitHub releases.** New tools should be installed via `install_gh_release` helper in `library_scripts.sh`. Construct direct download URL — avoid `nanolayer install gh-release` and the GitHub API. Avoid apt/npm/pip/snap when a GitHub release with prebuilt binaries exists.

## Common Gotchas

**GitHub API rate-limit (60/hr anonymous):** Tests may fail if running multiple times. Solution: use pinned versions.

**Arch mapping:** Three different conventions in use:
- `NVIM_ARCH`: `x86_64`/`arm64` — neovim uses `arm64` not `aarch64`
- `FZF_ARCH` (Go convention): `amd64`/`arm64` — used by fzf
- `LAZYGIT_ARCH`: `x86_64`/`arm64`

## Expand

To add tool to neovim-pack:

1. Add camelCase option to `devcontainer-feature.json`
2. Add default + env var to install.sh
3. Add `install_gh_release` call with correct repo, asset pattern, binary name
4. Prefer GitHub releases over package managers (npm/apt/pip)
5. Handle arch-specific quirks via arch mapping variables if needed
6. Add binary check to `test/test.sh`
7. Bump feature minor version
8. Test: `./scripts/validate.sh && ./scripts/test-local.sh`

## Use Caveman Skill

All OpenCode sessions use caveman (full). Drop filler, keep technical substance.

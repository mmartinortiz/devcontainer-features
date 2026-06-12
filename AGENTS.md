# AGENTS.md

Devcontainer features mono-repo. Single feature: `neovim-pack` (nvim + ast-grep + fzf + prettier).

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
GitHub Actions auto-validates, tests, publishes to `ghcr.io/manolo/devcontainer-features/neovim-pack:MAJOR`.

## Key Files

| File | Purpose |
|------|---------|
| `src/neovim-pack/install.sh` | Downloads + installs all 4 tools from GH releases. Hard-coded asset patterns per tool. **Arch detection** (x86_64/aarch64) in ~line 10. **Version resolution** via GH API (~line 50-60). Tool installs at ~line 100+. |
| `src/neovim-pack/devcontainer-feature.json` | Feature metadata. **camelCase options** (neovimVersion, astGrepVersion, fzfVersion, prettierVersion). Version bump here before release. |
| `src/neovim-pack/test/test.sh` | Verifies all 4 binaries exist + respond to `--version`. |
| `src/neovim-pack/README.md` | User docs: usage, version pinning, hybrid config mount guidance. |

## Conventions

**Version envvar mapping:** camelCase option → UPPERCASE envvar. `neovimVersion` → `NEOVIMVERSION`.

**Feature version independent of tool versions.** Feature 1.0.0 ≠ nvim 0.10.0. Semantic versioning: bump minor for new tool/option, patch for bug fix.

**Asset naming quirks:**
- Neovim: `nvim-linux-{x86_64|aarch64}.AppImage`
- ast-grep: `ast-grep-{x86_64|aarch64}-unknown-linux-gnu`
- fzf: `fzf-{VERSION}-linux_{amd64|arm64}.tar.gz` (note: amd64/arm64, not x86_64/aarch64)
- Prettier: GH release may not exist; falls back to npm install if available

**Fail loudly.** Install script uses `set -euo pipefail`. No silent failures. GitHub API rate-limit → explicit error.

**Idempotent.** Safe to re-run install.sh.

**Hybrid config mounts.** Feature doesn't enforce mounts. README documents recommended mounts (e.g., `~/.config/nvim` → `/root/.config/nvim`). User controls via devcontainer.json.

## Architecture Notes

Single monolithic feature. All tools in one `install.sh`. Test runs both install + verify in sequence.

CI runs on every PR/push (validate + test). Release workflow triggers on `v*` tag.

Base image: ubuntu:22.04 (Debian-based). Requires curl + tar + jq + npm (optional, for prettier fallback).

## Common Gotchas

**fzf asset name uses `amd64`/`arm64`, not `x86_64`/`aarch64`.** Map at top of install.sh.

**Prettier GH release asset naming varies.** Try hardcoded pattern first; npm fallback. Document expected asset name.

**`resolve_latest_version()` queries GH API directly.** Auth not required for public repos but rate-limited (60 req/hr anonymous). Tests may fail under rate limit; pin versions.

**Option value case matters.** `"latest"` string vs unquoted. Test with explicit values.

## Expand

To add tool to neovim-pack:
1. Add camelCase option to `devcontainer-feature.json`
2. Map UPPERCASE envvar + resolve latest in `install.sh`
3. Add download + install logic (hard-code asset pattern)
4. Add binary + version check to `test/test.sh`
5. Bump feature minor version
6. Test: `./scripts/test-local.sh`

## Use Caveman Skill

All OpenCode sessions use caveman (full). Drop filler, keep technical substance. See `/var/home/manolo/.agents/skills/caveman/SKILL.md`.

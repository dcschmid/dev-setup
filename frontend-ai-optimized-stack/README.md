# Frontend AI Optimized Stack v3.13.4 — Fedora 44 · Manual Codex · YOLO-Auto OMP Profiles

**Target:** Framework Laptop 16 / Fedora Workstation, with three separate coding agents:

| Agent | Working | Private | Login / switching |
|---|---|---|---|
| Claude Code | `claude-working` | `claude-private` | Existing `cswap` setup unchanged |
| Codex CLI | `codex-working` | `codex-private` | **Native Codex, NO automatic switching** |
| YOLO-Auto via Oh My Pi | `omp-working` (`yolo-working`) | `omp-private` (`yolo-private`) | Native OMP Yolo provider, own named profiles |

- **TinySearch** and **TinyContext** for all three agents in both profiles.
- Claude, Codex and OMP use **the same TinyContext project database** for the same Git repository **and the same profile**. Git worktrees share the database.
- Private Blender MCP `mcp-for-blender@2.2.0` remains available to all three private launchers; **never Working**.
- The two old managed Blender **skills** are removed: `mm-blender-asset-pipeline`, `mm-blender-defold-handoff`. The Blender MCP and its addon are not removed.
- No installation of codex-switch or cxswap, and **no Codex auto-switch service**. Both old tools and their login stores are preserved for optional manual cleanup later.
- The existing Claude `cswap` rotation is unchanged.

## Upgrade from v3.12.5 (or v3.12.4)

```bash
./install-profiles.sh
./setup-global-mcps.sh --check
./setup-yolo-omp.sh --check
./verify-profiles.sh
```

The installer snapshots managed assets/settings under `~/.frontend-ai-stack-backups/` with restrictive permissions. It never copies Codex `auth.json`, Claude `.credentials.json` or OMP login stores; **existing MCP/config files may themselves include secrets**, so treat backups as sensitive. Run `./rollback-profiles.sh` to undo stack-managed files; it does not restart old Codex rotation or remove OMP logins.

### Codex: deliberately manual

```bash
codex-private
codex-working
# If Codex Working has no login, sign in there via:
codex-working login
# To change account in one profile, use native Codex sign-in explicitly.
mm-codex-manual-doctor
```

Working keeps a dedicated `CODEX_HOME` for history, skills and login. Private continues using the ordinary `~/.codex` home. The two Plus accounts are **not automatically rotated**. The native CLIs may need separate sign-ins; there is no automatic credential file linking or token copying.

### YOLO-Auto: native OMP provider

**OMP CLI installs automatically** with `./install-profiles.sh` (or with
`./setup-yolo-omp.sh` when called separately). If Oh My Pi is missing,
`setup-omp-cli.sh` downloads and executes the official HTTPS installer using
`--binary`; the vendor checks the binary SHA-256. Already working OMP installations
are kept unchanged. This requires network access only for a missing OMP CLI.

```bash
./install-profiles.sh
./setup-omp-cli.sh --check
omp --version
./setup-yolo-omp.sh --check
```

This uses the vendor's installer from https://omp.sh/install, which is
remote executable code. For security review, inspect the upstream installer
before running `./install-profiles.sh`. To retry installation separately:
`./setup-omp-cli.sh --install`. OMP is installed to `~/.local/bin`, without
requiring Bun, system-wide packages or `sudo`. If the path was missing in Kitty,
the installer adds a small idempotent PATH block to `~/.zshrc`; start a new shell.
Credentials and named profiles are not changed by the OMP CLI install.

Now start each profile and use the **interactive** `/login yolo-auto` command (never paste keys into a shell command stored in history):

```bash
omp-working
# inside OMP: /login yolo-auto
# restart, then:
omp-private
# inside OMP: /login yolo-auto
```

Default model: `yolo-auto/qwen3.8-27b`; choose a different entitled model with `/model` if appropriate. **A paid Yolo-Auto subscription/key is required for inference.** The installer doesn't download models, make authenticated remote API requests, or store any keys. Use `omp models yolo-auto` to check discovery after login. Docs: <https://yolo-auto.com/docs#agent-oh-my-pi>.

Native OMP profiles:

```
~/.omp/profiles/working/agent/{config.yml,mcp.json,skills/}
~/.omp/profiles/private/agent/{config.yml,mcp.json,skills/}
```

Both are isolated from Claude/Codex/Gemini/OpenCode imported capability discovery. Working explicitly denies Blender by name; Private defines Blender MCP. Skills are symlinks to our profile-specific stack-owned package directory; unrelated existing OMP profile files are not overwritten. To audit isolation: `mm-yolo-doctor` and `./setup-yolo-omp.sh --check`.

**Important limitation:** User/repository-owned project `.omp/` configuration may still add other skills/tools. Treat project-controlled MCP configuration as trusted source and inspect on first use. Local profile separation does **not** separate remote Yolo- or Codex-account privacy/terms; apply employer policies before sending company code.

## OMP improvements in v3.13.2

The installer adds a dedicated **OMP-only** `mm-omp-code-workflow` skill to both named OMP profiles. It guides the built-in LSP/task/worktree tools, verified handoffs through TinyContext and safe optional extensions. It is **not linked into Claude Code or Codex**. No extra MCP servers or background services are installed.

Read [the OMP / Skill update review](docs/UPDATES_OMP_SKILLS_2026-10-29.md) for the current feature recommendations, optional plan-first extension and GitHub MCP v2 migration caution.

## Extra integrations worth considering (opt-in, not bundled)

1. [Official Yolo-Auto plan-first Todo extension](https://github.com/yolo-auto-org/yolo-auto-omp) for `/model yolo-auto/yolo`. Install into **each intended named profile's** `agent/extensions/` only after reviewing the TypeScript source. We do not execute arbitrary remote TypeScript during Stack install.
2. OMP already has native **MCP**, **LSP** and **task/subagent** capabilities. Prefer those built-ins; do not add a second MCP adapter or another memory backend while TinyContext is working.
3. Keep TinySearch as the common search MCP instead of adding redundant third-party web-search extensions by default.

See [docs/YOLO_OMP.md](docs/YOLO_OMP.md) for troubleshooting, credentials, and precise profile isolation.

## Diagnostics

```bash
./verify-profiles.sh
mm-yolo-doctor
mm-codex-manual-doctor
mm-claude-swap-doctor
MM_AGENT_PROFILE=working mm-project-memory-doctor
MM_AGENT_PROFILE=private mm-project-memory-doctor
```

### New in v3.13.2 — advanced OMP workflows

The new workflow layer is installed with `./install-profiles.sh` and preserved
between Working/Private by native OMP profiles. See
`docs/OMP_ADVANCED_FEATURES.md` for configuration, optional YOLO Todo
Discipline staging, safe desktop/browser toggles and completions.

```bash
./setup-yolo-omp.sh --check
./setup-omp-features.sh --check
./setup-omp-completions.sh --install
./setup-yolo-todo.sh --stage      # review before enabling
```

TinyContext remains the only project memory store; native OMP `learn` is not
available with `memory.backend: off`, but controlled `manage_skill` is enabled.
No Codex automatic rotation or bundled Blender skills have been reintroduced.

## Zed Delta removal (v3.13.4)

Unlike the normal **Zed editor**, Zed **Delta** is no longer part of this stack.
During installation, recognized `~/.local/delta.app`, its `~/.local/bin/delta` link,
verified Delta desktop entries, Claude's official `delta@zed-industries` plugin
and Zed Delta-specific MCP registrations for Claude/Codex/OMP are removed or moved
into private, recoverable backups. The unrelated **mcpdelta** product is untouched.

```bash
./remove-zed-delta.sh --scan     # no changes
./remove-zed-delta.sh --apply    # targeted cleanup, with backup
./remove-zed-delta.sh --check    # return nonzero if Delta still recognized
```

See `docs/ZED_DELTA_REMOVAL.md` for project-specific notes and recovery.

**New OMP launchers**: `omp-working` and `omp-private` are fully supported;
`yolo-working` / `yolo-private` remain identical compatibility commands.

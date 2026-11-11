# MCP profile scopes — Fedora / Framework 16 (v3.12.3)

The scope boundary is **Claude/Codex Working vs Private**, not "all tools everywhere".

| Agent profile | TinySearch | TinyContext (`mm-tinycontext`) | Blender MCP 2.2.7 |
|---|---|---|---|
| `claude-working` | yes | yes (Working DB) | **no** |
| `claude-private` | yes | yes (Private DB) | **yes**, via `--mcp-config` |
| `codex-working` | yes | yes (Working DB) | **no** |
| `codex-private` | yes | yes (Private DB) | **yes**, via `-c mcp_servers.blender=...` |

## Installation

```bash
./install-profiles.sh
./setup-global-mcps.sh
./setup-global-mcps.sh --check
./verify-profiles.sh
```

TinySearch is registered once per CLI as the user MCP `tinysearch` with:

```bash
uvx --python 3.12 --from 'tinysuite-search[server]' tinysearch
```

TinyContext uses our **existing** `mm-tinycontext` MCP registration and is not registered twice:

```bash
~/.local/bin/mm-tinycontext-mcp
```

The TinyContext launcher receives `MM_AGENT_PROFILE=working` or `private` from the profile wrappers. It retains existing private databases in `~/.local/share/tinycontext/projects/` and stores Working memories separately in `~/.local/share/tinycontext/projects-working/`. Embedding model files can be shared; SQLite memories cannot. Plain `claude` or `codex` launches have no guaranteed profile selection; **use the named wrappers**.

### Project memory shared between Claude and Codex

Within the same repository **and** profile, both CLIs use the *same* database,
not a copied/synchronized second database. The managed `mm-tinycontext-mcp`
launcher uses `mm-tinycontext-path` to resolve the primary Git worktree via
`git rev-parse --git-common-dir`, so related Git worktrees also share memory.
`MM_TINYCONTEXT_PROJECT_ROOT` is bound by the CLI wrappers at startup, which
prevents the MCP's working directory from silently changing the chosen project.
No database is created by the read-only checks below:

```bash
cd /path/to/project
MM_AGENT_PROFILE=private tinycontext-project info
MM_AGENT_PROFILE=private mm-project-memory-doctor
MM_AGENT_PROFILE=working mm-project-memory-doctor
```

The same repository in Working and Private has **different databases** by design.
The `project-memory` skill guides both agents to save short decisions and recall
handoffs. Chat transcripts do not sync automatically, and persistent memories
are untrusted reference context, not executable instructions. Personal/profile
memories are scoped only to a whole TinyContext database; project decisions
should normally use episodic memories.

The v3.12.1 main-worktree private DB filenames are preserved. Pre-existing
per-worktree DBs are *not* automatically merged. Back them up and review before
any manual migration. For non-Git directories, the physical directory is used
as the identity; start both agents in that same directory. Project-local MCP
registrations named `mm-tinycontext` may override the global registration;
review `.mcp.json` and `.codex/config.toml` if the agents disagree.

**Blender must not be registered globally** (for example `claude mcp add --scope user blender ...` or `codex mcp add blender ...`) because this would also expose Blender tools to Working. This package now handles the common v3.12.2 failure safely:

1. `./install-profiles.sh` first validates the existing user configs.
2. Only entries named `blender` that run the known `uvx mcp-for-blender@2.2.0` (legacy) or `@2.2.7` (current) server are eligible for automatic migration; both original user config files are saved first.
3. Only that one Blender MCP is removed from the global tables. All unrelated MCP registrations and authentication files remain untouched.
4. The private launcher overlay is generated and the shared TinySuite MCPs are registered after the stack helpers are installed.

Run a read-only migration inspection with:

```bash
python3 scripts/migrate_global_blender.py --preflight
```

In the standard case, the update takes just:

```bash
./install-profiles.sh
./setup-global-mcps.sh --check
./verify-profiles.sh
```

If the script reports **unknown/custom global Blender**, it stops without modifying your configs. Inspect the actual registration and backup the files before choosing whether to remove it yourself:

```bash
claude mcp get blender
codex mcp get blender
mkdir -p "$HOME/claude-codex-mcp-backup"
cp -a ~/.claude.json "$HOME/claude-codex-mcp-backup/claude.json"
cp -a ~/.codex/config.toml "$HOME/claude-codex-mcp-backup/codex-config.toml"
# ONLY if the Blender entry is genuinely user-global and should be private:
claude mcp remove blender --scope user
codex mcp remove blender
./install-profiles.sh
```

Do **not** remove a project-specific Blender server if it is needed by that project's own setup; review `.mcp.json` and `.codex/config.toml` separately. The migration script never touches project MCPs, TinyContext databases or account credentials. The automatic backup directory is printed on success and is stored under `~/.frontend-ai-stack-backups/`. Existing CLI sessions should be restarted so they pick up the changed MCP scope.

The **private** Blender overlay file is generated at `~/.local/share/frontend-ai-stack/mcp/private-blender.json`. `claude-private` supplies it with `--mcp-config`. `codex-private` passes an equivalent invocation-only TOML override. Neither writes Blender to either user's global MCP tables. The Codex `-c` override isn't supported for every subcommand (for example `resume`): use a new private interactive session or verify support before resuming.

The Blender add-on is separate:

```bash
./setup-private-gamedev-mcp.sh
```

If Blender is a Flatpak, the helper installs the `mcp-for-blender@2.2.7` add-on into the detected Blender profile. Blender uses localhost `127.0.0.1:9876`; `BLENDER_MCP_SAFE_MODE=1` and telemetry disabled are set in the private MCP definitions. This scope division controls **which CLI sessions receive tools**, not OS-level isolation of a local socket: any local program with socket access may be able to connect.

## Verify actual session tools

Open a fresh `claude-working`, `claude-private`, `codex-working`, `codex-private` session and inspect `/mcp` in each. Working should have TinySearch and `mm-tinycontext`, **not blender**. Private should have all three. The verification script checks our config files but cannot rule out an unrelated repo's project-level `.mcp.json` or `.codex/config.toml` reintroducing Blender. In working projects, inspect those too.

Old Riff Racers `.mcp.json` / `.codex/config.toml` Blender 2.1.9 entries may override the new version. The helper performs a read-only scan by default and only backs up/removes known old definitions on explicit request:

```bash
python3 scripts/migrate_legacy_project_blender.py /path/to/riff-racers
python3 scripts/migrate_legacy_project_blender.py --apply /path/to/riff-racers
```

## TinySuite runtime checks

```bash
uvx --python 3.12 --from 'tinysuite-search[server]' tinysearch doctor
uvx --python 3.12 --from 'tinysuite-search[server]' tinysearch setup
uvx --python 3.12 --from 'tinysuite-context[server]' tinycontext doctor
```

TinySearch makes external web requests, and optional page scraping may download Chromium and a local embedding bundle. TinyContext may download its own ONNX embedding model on first use. None of these downloads is performed by the installer. Follow work data-handling policies; profile-aware storage does not make an unrestricted MCP safe for confidential content automatically.

Sources: [TinySearch](https://tinysuite.dev/docs/tinysearch/), [TinyContext](https://tinysuite.dev/docs/tinycontext/), [Claude CLI](https://code.claude.com/docs/en/cli-reference), [Codex CLI](https://developers.openai.com/codex/cli/reference), [MCP for Blender](https://www.mcp-for-blender.com/docs/installation).

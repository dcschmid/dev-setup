# Zed Delta removal — Fedora v3.13.4

Zed **Delta** (`delta.dev`) is a separate collaborative application from the
normal **Zed editor** (`zed`). The setup does **not** uninstall the Zed editor.
It also does not uninstall the unrelated `mcpdelta` product.

The upstream Zed Delta Linux installer places the app in `~/.local/delta.app`
and a symlink in `~/.local/bin/delta`; its Claude Code integration installs
`delta@zed-industries` from the `zed-industries/delta-claude` marketplace.

## Default upgrade behavior

`./install-profiles.sh` uses `scripts/cleanup_zed_delta.py` to discover and
remove only recognized app artifacts, official plugin and MCP registrations.
Backup location is printed at the end of the installation. The app is **moved**
into `BACKUP/zed-delta/uninstalled-app/` (not permanently deleted), config
files are copied into `BACKUP/zed-delta/config/`. This may consume disk space
until you choose to delete the backups.

The scanner checks:
- Global Claude Code `~/.claude.json` and personal/project `.mcp.json`,
  `.claude/settings*.json` (project discovery under `~/dev`).
- Codex `~/.codex/config.toml`, Working `CODEX_HOME` and `~/dev` project configs.
- OMP named profile MCP JSON files.
- Official Zed Delta app/CLI and Claude plugin.

To scan additional projects outside `~/dev`:

```bash
MM_DELTA_PROJECT_ROOTS="$HOME/dev:$HOME/other-repositories" ./remove-zed-delta.sh --apply
```

## Commands

```bash
./remove-zed-delta.sh --scan     # non-destructive
./remove-zed-delta.sh --apply    # backs up files; removes detected Delta
./remove-zed-delta.sh --check    # 0 means nothing detected
```

If the official Claude CLI plugin uninstall fails or Claude isn't installed,
re-run `claude plugin uninstall delta@zed-industries --scope user`.
If Delta remains installed in project/local scope, navigate to that repository
and run `claude plugin uninstall delta@zed-industries --scope project` or
`--scope local` as appropriate. The script removes matching enablement
settings and MCPs, but intentionally does not modify unknown plugin caches.

**Very important:** A Zed Delta MCP can only be removed automatically when
its server name and command/URL identify Zed Delta. Generic names such as
`delta` with unknown commands are left untouched for manual review.

## Restore

This is an intentional uninstall, so the normal stack rollback does not
automatically restore Delta. To restore individual config files, copy the
backed-up file under `BACKUP/zed-delta/config/` to its original path after
checking it contains no newer changes. To restore the app, move the app folder
and symlink from `BACKUP/zed-delta/uninstalled-app/` to their previous
locations. If the official Claude plugin had been uninstalled, re-install it
with the vendor's documented plugin command when wanted.

No Claude auth files, Codex OAuth tokens, OMP user secrets, Git projects,
TinyContext SQLite files or normal Zed editor installations are deleted.

Official documentation:
- https://delta.dev/docs/installation
- https://delta.dev/docs/cli/claude-code
- https://code.claude.com/docs/en/discover-plugins

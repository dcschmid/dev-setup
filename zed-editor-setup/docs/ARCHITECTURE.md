# Architecture and integration boundaries

```text
Fedora 44 / Framework 16 / Wayland
  ├─ Zed Stable (official Linux installation script)
  │   ├─ Frontend: Astro extension; TypeScript/TSX; Tailwind; Emmet
  │   ├─ Games: Defold extension + Lua extension
  │   ├─ Tasks: ~/.config/zed/tasks.json → ~/.local/bin/zed-dev
  │   ├─ ACP Registry: Claude Agent and Codex (added separately in Zed)
  │   └─ Terminal threads: claude / codex / yolo-working / yolo-private
  └─ Existing own stack (NOT modified)
      ├─ Claude Code + cswap
      ├─ Codex CLI (direct, without cxswap/codex-switch)
      ├─ OMP / YOLO-Auto (working, private)
      │   └─ Qwen provider as already configured separately
      ├─ TinySearch + TinyContext; Blender MCP private only
      ├─ Node / Corepack / pkg manager / direnv / zsh
      └─ Kitty Workspace Pack / Git signatures / Defold 1.14
```

## Important separation

**Zed agent vs ACP agent vs terminal thread** are different paths and do not have identical configuration responsibilities. ACP agents usually take over their own model logins/tools; terminal threads run with the native CLI configuration. This package deliberately configures **no** Zed LLM providers, no tokens, and no additional Zed MCP servers.

Global task in the Zed editor: `~/.config/zed/tasks.json`. Project-local settings: `.zed/settings.json` and `.zed/tasks.json` in the respective repo, added **manually** if needed. The package never touches repos or agent dotfiles.

## What the installer script replaces

It writes only these files (if changes are needed):

```text
~/.config/zed/settings.json
~/.config/zed/tasks.json
~/.local/bin/zed-dev
```

Previous files are secured in a private transactional backup. Your own other tasks and unaddressed `settings` keys are preserved. **No** `.zshrc`, no git config, no `~/.claude`, `~/.codex`, `~/.pi`, no systemd unit, and no shell/Kitty configuration is overwritten.

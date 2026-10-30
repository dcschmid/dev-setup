# dev-setup

Personal, locally run development setup for a **Framework Laptop 16 on Fedora 44 (KDE Plasma or GNOME on Wayland)**. Three self-contained packages, each with its own installer, docs, and changelog. Everything is deliberately small, safe, and idempotent: it configures what it owns and leaves the rest of the system untouched.

| Package | What it does |
|---|---|
| [`frontend-ai-optimized-stack/`](frontend-ai-optimized-stack/) | Three coding agents (Claude Code, Codex CLI, YOLO-Auto via Oh My Pi) as **working** and **private** profiles, with shared TinySearch/TinyContext and a private Blender MCP. |
| [`kitty-terminal-setup/`](kitty-terminal-setup/) | A lean Kitty/Zsh workspace: Catppuccin Mocha, Powerline tabs, persistent session state with rotating backups, and a curated toolset (fzf, zoxide, direnv, Atuin, eza, bat, delta, lazygit). |
| [`zed-editor-setup/`](zed-editor-setup/) | A small, safe Zed editor configuration for Astro/Next.js/TypeScript/Defold, with ACP/terminal agent tasks and an optional Delta add-on. |

## Layout

```text
dev-setup/
├── frontend-ai-optimized-stack/   # agent profiles, MCPs, skills, OMP workflows
├── kitty-terminal-setup/          # Kitty + Zsh workspace pack
└── zed-editor-setup/              # Zed editor devkit
```

Each package is independent — install only what you need.

## Conventions

- **No `sudo`** for the package installers; they write to user directories (`~/.config`, `~/.local`, `~/.omp`, …).
- **Idempotent**: re-running an installer does not create extra backups or duplicate state.
- **Backups first**: existing configs are merged and backed up before changes; a rollback path is provided.
- **Secrets stay out of the repo**: generated secret files (e.g. `secrets.zsh`) are git-ignored and created at runtime with `0600` permissions. Only `.example` templates are committed.
- **No automatic agent runs**: the packages configure and launch tools on demand; they never start agents by themselves.

## Getting started

Pick a package and follow its README:

- [`frontend-ai-optimized-stack/README.md`](frontend-ai-optimized-stack/README.md)
- [`kitty-terminal-setup/README.md`](kitty-terminal-setup/README.md)
- [`zed-editor-setup/README.md`](zed-editor-setup/README.md)

## Notes

- All documentation in this repository is in **English**.
- The setup targets Fedora 44 / Framework 16; other distros may work but are not the primary target.

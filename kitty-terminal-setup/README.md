# Kitty Workspace Pack v1.6.0 — Fedora / Framework 16

A deliberately lean, locally run Kitty/Zsh setup for your **Framework Laptop 16 with Fedora 44 (KDE Plasma or GNOME on Wayland)**.

## What appears at startup

Only on the first start or after a deliberate reset:

```text
Unified Frontend 1    ~/dev/gitlab/unified-frontend
Unified Frontend 2    ~/dev/gitlab/unified-frontend
```

After that, **you** create, close, and rename your tabs and windows. Kitty restores the last saved state each time. **No old Melody-Mind project launchers or predefined OMP/DEV/TEST tabs.**

The visible **Kitty Workspace** launcher uses `--single-instance --instance-group=kitty-workspace` so that repeated invocations land in the same Kitty instance as much as possible (new OS windows are possible in the process). Separately started, independent Kitty processes can still store different states; use the same launcher for this workspace.

The state contains tabs, titles, directories, and window structure, **not** running shell programs (no automatic restart of `pnpm dev`, Claude, or Codex).

## Installation / upgrade

Unpack and start from a normal terminal:

```bash
unzip kitty-workspace-pack-v1.6.0.zip
cd kitty-workspace-pack-v1.6.0
./install.sh
./shell-doctor.sh
./state-status.py
```

**Recommended if you already have almost all tools on Fedora:**

```bash
./install.sh --config-only
```

The config-only mode changes the settings managed by the package but installs **no software** and runs **no upgrades/downloads**. It leaves existing personal Kitty states untouched.

`./install.sh` asks about missing packages, installs the base via `dnf`, and does **not** update Kitty automatically. `--yes` accepts the normal missing dependencies, but **no automatic Kitty update** and no optional Lazygit.

## Current versions and sources (October 30, 2026)

| Component | Verified | Behavior of this package |
|---|---|---|
| Kitty upstream | **0.49.2** | Check; no unasked update |
| Fedora 44 Kitty RPM | **0.47.1** in the Fedora package overview | The DNF version stays the default if it is installed |
| nvm | **v0.40.8** | Installation **only on explicit request** |
| Atuin | Fedora 44 in the package overview: **18.12.1** | Older vs. newer init flags are taken into account |

For Kitty:

```bash
./update-kitty.sh --check       # version check only
./update-kitty.sh --dnf         # explicitly update the Fedora packages
./update-kitty.sh --official    # explicitly install upstream into ~/.local/kitty.app
```

The official installation is **optional**; Fedora and upstream binaries should not be swapped unnoticed.

## Persistent state — now with backups

- A session snapshot is requested roughly every 10 seconds and after relevant Kitty events.
- Before overwriting, the new watcher script checks the generated session in a **temporary file**. An invalid snapshot does not replace the last valid one.
- Additionally, the previous state is backed up roughly every 15 minutes; up to twelve rotating auto-backups.
- The Quick Access kitten uses its **own Kitty configuration file without the autosave watcher**, so its short-lived terminal does not overwrite the main state.
- The log contains only error types, no session contents/commands.

```text
~/.config/kitty/last-state.kitty-session
~/.local/state/kitty-workspace-pack/autosave-backups/
~/.local/state/kitty-workspace-pack/autosave-error.log
```

Save manually: `Ctrl+Space, S`.

Check status:

```bash
./state-status.py
```

**Important:** A real Kitty test on your Fedora/Wayland system is still needed; the watcher was tested here with mocks, not live on your Framework. See `PERSISTENT-STATE.md`.

## Removed old startup tabs / reset

If you brought over two identifiable Melody-Mind startup tabs from an old v1.5 state, **close Kitty completely**, then:

```bash
./migrate-kitty-state.py
```

Nothing is changed for unclear sessions. The previous state is backed up before a successful migration.

If you deliberately want to **discard all self-created tabs**, close Kitty and:

```bash
./reset-kitty-state.sh
```

The script backs up the old file and then resets only to the two Unified Frontend tabs.

## Missing Node / pnpm from your last doctor output

Our Zsh profile activates the Oh-My-Zsh NVM plugin, **but does not install NVM, Node, or pnpm**. So that `node`, `npm`, and `pnpm` work again after a Fedora reinstall:

```bash
./setup-node.sh --check
./setup-node.sh --install-nvm       # optional, with a prompt
./setup-node.sh --install-project   # only with an existing .nvmrc, with a prompt
```

`NODE-SETUP.md` explains the version from `.nvmrc`, `package.json`, Corepack, and pnpm. **Conda, Rust, uv, Claude, Codex, OMP (Oh My Pi), and Lazygit remain optional.** The new doctor no longer presents these as equivalent errors.

## Included features

Kitty Catppuccin Mocha, Powerline tabs, JetBrains Mono (optional), Zsh/Oh My Zsh, Git/gitfast, safe NVM `.nvmrc` switching, fzf, zoxide, direnv, Atuin local with AI binding disabled, eza, bat, delta, optional lazygit TUI, and safe Git worktree helpers. Plus Kitty `diff`, `icat`, `choose-files`, Quick Access, and notifications for long background commands.

The default shell of your Linux account is **not** changed. The package does not run agents automatically.

## Documentation guide

- `PERSISTENT-STATE.md`: autosave, backups, test, migration, and reset
- `NODE-SETUP.md`: NVM, Node, pnpm, and Corepack on Fedora
- `TOOLS-GUIDE.md`: the most important tools and how they work
- `KEYBOARD-SHORTCUTS.md`: all keybindings
- `CLI-POLISH-WORKTREES.md`: Git worktrees, eza, bat, delta, lazygit
- `KITTY-KITTENS.md`, `ZSH-EXTRAS.md`, `VISUAL-QOL.md`: detailed references
- `CHANGELOG.md`: full version history

## Uninstall

```bash
./uninstall.sh
```

**Deliberately preserves** the personal saved session, backups, secrets, self-created sessions, tools, and the existing login shell.

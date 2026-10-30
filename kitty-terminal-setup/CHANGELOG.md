# Changelog

## v1.6.0 — Fedora / Framework Maintenance & Safety (2026-10-30)

- Verified current upstream Kitty 0.49.2 and Fedora 44 package information from official docs.
- Installer now prefers `dnf` for first-time Kitty installation on Fedora; updates are opt-in, not automatic.
- Added `--config-only` for safe reapplication without package downloads or updates.
- Added read-only `update-kitty.sh --check` plus explicit `--dnf` / `--official` operations.
- Added new `setup-node.sh` and `NODE-SETUP.md`: diagnose NVM/Node/pnpm missing on a clean Fedora machine, with explicit opt-in installation and `.nvmrc` handling.
- Rebuilt shell doctor to distinguish required configuration checks from recommended tools and optional coding tools.
- Guarded autosave with staged-file verification and atomic replacement; invalid snapshots retain the previous state.
- Added twelve rotating periodic snapshots, generic error log and `state-status.py`.
- Isolated Quick Access into `quick-access-kitty.conf` without main workspace startup session or autosave watcher.
- Made manual Save shortcut XDG-aware instead of hardcoding `~/.config`.
- The visible Kitty Workspace launcher now uses single-instance grouping to reduce competing Kitty state writers.
- Improved Atuin initialization compatibility with older Fedora-package builds; AI bindings disabled where supported.
- Updated documentation for Fedora KDE/Wayland (also works on GNOME), removed outdated starter-tab duplication and inactive project examples.
- Added `tests.py` with offline watcher and installer/reinstaller/uninstaller tests; existing user tabs are preserved.
- Retained exactly two Unified Frontend baseline tabs. No Melody Mind project startup.

## v1.5.2 — Fedora / Framework 16 cleanup

- Updated first-run and reset baseline to 2x Unified Frontend only.
- Removed old Melody Mind launchers rather than creating compatibility redirects.
- Updated file picker and docs to avoid the deleted project.
- Added opt-in saved-state migration that backs up first and preserves user-created tabs.
- Prefer official Kitty binary when explicitly installed alongside Fedora RPM version.
- Prefer Fedora DNF packages including Atuin.
- Disabled unreliable Wayland window position restore; no changes to tab persistence.
- Added Fedora/GNOME checks and on-device persistence verification instructions.
- Upstream Kitty 0.49.2 versus Fedora 44 packaged Kitty 0.47.1 noted in docs.


## v1.5.1 — Startup Migration Hotfix

- Fixed startup failure from stale Melody Mind / Unified Frontend launchers.
- Added visible `Kitty Workspace` desktop launcher.
- Added hidden compatibility redirects for the two old desktop IDs.
- Installer removes known legacy project-session references from `kitty.conf`.
- Installer repairs `.desktop` launchers that still invoke retired session files.
- Added `repair-v1.5-startup.sh`.
- Shell Doctor checks the persistent state and stale legacy launcher references.
- Persistent-state behavior itself is unchanged.

## v1.5.0 — Persistent State Edition

- Updated baseline for Kitty 0.49.2.
- Removed the old project-session switching model.
- Removed pack-managed Melody Mind / Unified Frontend session files and project desktop launchers.
- New first-run baseline: 2 Melody Mind tabs + 2 Unified Frontend tabs in one normal Kitty state.
- Added automatic state saving every ~10 seconds using a global Kitty watcher.
- Added final state save on confirmed normal quit.
- Added automatic restore through `startup_session last-state.kitty-session`.
- Foreground processes are deliberately not replayed on restore.
- Added manual save on `Ctrl+Space, S`.
- Added `reset-kitty-state.sh`.
- Added `update-kitty.sh`, including an explicit `--official` path for distros that lag behind.
- Added `PERSISTENT-STATE.md`.
- Removed old project session leader shortcuts M/U/P/B/X.
- Preserved all Zsh/NVM/Atuin/Git/eza/bat/delta/lazygit/worktree tooling.

## v1.4.1 — Final Docs Edition

- Added `TOOLS-GUIDE.md`.
- Explained Kitty sessions and scratch workspaces.
- Explained Oh My Zsh, Git aliases and gitfast.
- Added a detailed Git worktree mental model and safe workflows.
- Explained delta, optional lazygit, eza, bat, fzf, zoxide, Atuin, NVM and direnv.
- Explained Kitty choose-files, diff, image viewer and quick-access terminal.
- Added an everyday workflow and a "which tool should I use?" table.
- Added a documentation map to README.

## v1.4.0 — CLI Polish & Worktrees

- Added eza with safe GNU ls fallback.
- Added bat without overriding `cat`.
- Added Debian/Ubuntu `batcat` compatibility symlink.
- Added git-delta with a separate reversible Git include file.
- Added optional lazygit installation.
- Upstream lazygit binary downloads are verified with the release checksums file.
- Added `lg` alias when lazygit exists.
- Added safe Git worktree helper.
- Added `gwl`, `gwnew`, `gwcd`, `gwrm`, and `gwprune`.
- Worktrees are created beside the main repo in `<repo>-worktrees/`.
- Worktree removal refuses dirty, main, and current worktrees and never uses force.
- Expanded shell doctor and documentation.
- Added `CLI-POLISH-WORKTREES.md`.

## v1.3.2 — Visual & Quality-of-Life

- Added optional JetBrains Mono detection/installation with safe monospace fallback.
- Added `mouse_hide_wait -3.0` to hide the pointer while typing.
- Added `notify_on_cmd_finish invisible 20.0` for long background commands.
- Added 16 MB separate scrollback pager history.
- Added `Ctrl+Space, H` to browse the full scrollback buffer.
- Confirmed/retained rounded Powerline tabs.
- Added `VISUAL-QOL.md`.
- Extended shell doctor with font and visual/QoL checks.

## v1.3.1 — NVM Auto Switch

- Added safe Zsh `.nvmrc` project auto-switching without surprise downloads.
- NVM is loaded at shell start so switching works immediately in fresh Kitty tabs.
- Kept Oh My Zsh native NVM autoload disabled because it auto-installs missing versions.
- Added automatic return to the NVM default version when leaving an `.nvmrc` project.
- Missing `.nvmrc` Node versions are reported but never downloaded automatically on `cd`.
- Added `ensure-nvmrc.sh` to inspect or create project `.nvmrc` files.
- Expanded shell doctor and documentation for NVM project-version automation.

## v1.3.0 — Developer Extras

- Added Oh My Zsh `gitfast`, `aliases`, `fzf`, `zoxide`, `zsh-interactive-cd`, and `direnv`.
- Added package-manager installation for fzf, zoxide, direnv, ripgrep, and fd.
- Added Atuin with local-first defaults.
- Atuin auto-sync is disabled.
- Atuin update checks are disabled.
- Atuin AI is disabled in both configuration and Zsh key bindings.
- Atuin uses Git workspace history mode by default.
- Atuin keeps the normal Up arrow untouched while owning `Ctrl+R`.
- Added optional safe history-import helper.
- Added Catppuccin-style fzf UI.
- Added Kitty choose-files shortcut and configuration.
- Added Kitty quick access terminal configuration and launcher.
- Added Kitty diff, image, grep, SSH and transfer shell helpers.
- Added native Kitty ripgrep hyperlinks when supported.
- Added Git/Zsh, Kitty kittens and Zsh extras cheat sheets.
- Expanded shell doctor for all new tools.
- Ensured `zsh-syntax-highlighting` is sourced last, after Atuin initialization.

## v1.2.0 — Locked Tabs + Oh My Zsh

- Locked Kitty tab ordering with `drag_threshold 0`.
- Unmapped Kitty's default `Ctrl+Shift+.` / `Ctrl+Shift+,` tab-move shortcuts.
- Added Zsh installation with package-manager detection.
- Added Oh My Zsh without changing the system login shell.
- Kitty uses Zsh only after Zsh is confirmed installed.
- Added compact `kitty-mocha` Oh My Zsh theme.
- Migrated useful PATH entries from the existing Bash setup.
- Added NVM lazy loading and `claude` lazy trigger.
- Added Miniconda Zsh initialization.
- Added `zsh-autosuggestions` and `zsh-syntax-highlighting`.
- Added shared 0600 secrets workflow; API key values are never copied from Bash.
- Added `setup-shell-secrets.sh`.
- Added `shell-doctor.sh`.
- Added optional `set-default-shell.sh` and `restore-bash-shell.sh`.
- Added safer `collect-shell-review-v2.sh`.
- Updated README and keyboard cheat sheet.

## v1.1.3 — Fresh Workspace + Tab Rename

- Added `Ctrl+Space, W` to open a fresh independent Kitty OS window for ad-hoc work.
- The fresh window deliberately does not join the currently active project session.
- Added `Ctrl+Space, N` to rename the current tab interactively.
- Documented the intended scratch flow: fresh workspace → create/rename tabs → save with `Ctrl+Space, S`.
- Updated the keyboard cheat sheet and installer summary.

## v1.1.2 — Scratch Sessions

- `Ctrl+Space, S` now saves only the currently focused Kitty OS window as a new named session.
- Scratch saves use `~/.local/share/kitty/sessions` as their base directory.
- Added `Ctrl+Space, V` to update the currently active saved session in place.
- Scratch saves intentionally do **not** use `--use-foreground-process`, preventing installer/test/shell commands from being automatically re-run on restore.
- Documented the recommended `.kitty-session` filename suffix so saved scratch sessions appear in `Ctrl+Space, P`.
- Added a safe save → close → restore workflow for ad-hoc terminal work.

## v1.1.1 — Clean Session Tabs

- Added `tab_bar_filter session:~ or session:^$`.
- Tabs from inactive project sessions are hidden from the tab bar while their processes continue running.
- Unsessioned/scratch tabs remain visible by design.
- Documented the optional strict mode `tab_bar_filter session:~` for users who want only project tabs visible.
- No shortcut changes from v1.1.0.

## v1.1.0 — Polished

- Added subtle `0.97` background opacity.
- Added a small cursor trail and beam cursor.
- Increased laptop padding slightly.
- Increased scrollback to 20,000 lines.
- Enabled Kitty shell integration while keeping project tab titles stable.
- Added `Ctrl+Space, O` to browse the last command output.
- Added `Ctrl+Space, C` to copy the last command output.
- Added `Ctrl+Space, K` for the Kitty Command Palette.
- Added `Ctrl+Space, R` to reload the configuration without an F-key.
- Added `Ctrl+Space, T` for Kitty's interactive theme picker.
- Added `Ctrl+Space, L` for URL hints.
- Added `Ctrl+Space, F` for file/path hints.
- Added `KEYBOARD-SHORTCUTS.md` to the package.
- Kept the four-tab `OMP / DEV / TEST / GIT` workflow unchanged.
- Kept automatic process/agent startup disabled.

## v1.0.2

- Added Catppuccin Mocha.
- Added compact Powerline tabs.
- Added `Ctrl+Space, X` to close the current project session.

## v1.0.1

- Replaced laptop-unfriendly F7 project shortcuts with the `Ctrl+Space` leader.

## v1.0.0

- Initial project-session pack for Melody Mind and Unified Frontend.

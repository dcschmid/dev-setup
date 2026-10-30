# Persistent Kitty State — v1.6.0

Kitty starts with the file `~/.config/kitty/last-state.kitty-session` (or the corresponding location under a different `XDG_CONFIG_HOME`). **Only on the first start** is the template with 2× Unified Frontend applied.

## What is restored

Window structure, tabs, their names, working directories, and layout information, insofar as Kitty stores them. On Wayland, the compositor determines the actual placement on the monitor; screen coordinates cannot be guaranteed.

**Not** restored: running shell processes or the contents of the interactive shell, editor buffers, running web servers, and coding agents. These are not automatically restarted for security reasons. `--use-foreground-process` is not used.

## How autosave works

`watcher state-autosave.py` enables a global Kitty watcher. It triggers a save into a temporary file roughly every 10 seconds and on tab/focus/title changes.

Only if this contains a plausible session with `new_tab` and `launch` does it atomically replace the previous `last-state.kitty-session`. An error leaves the previous file in place and a generic hint in:

```text
~/.local/state/kitty-workspace-pack/autosave-error.log
```

The last up-to-twelve time-staggered copies are under:

```text
~/.local/state/kitty-workspace-pack/autosave-backups/
```

Quick Access uses `quick-access-kitty.conf` without a watcher and without `startup_session`. This prevents a transient mini-terminal from overwriting the actual session.

## Practical test on Fedora / Wayland

1. Start `Kitty Workspace` and open a new test tab with `Ctrl+Shift+T`.
2. In this test tab, change into an existing directory and rename the tab (`Ctrl+Space, N`).
3. Wait at least 15 seconds and check the timestamp and tab count outside of Kitty with `./state-status.py`.
4. Close Kitty normally and start `Kitty Workspace` again. Check tab titles, tab count, and directory.
5. Test `Ctrl+Space, S` (manual save) and the Quick Access terminal separately. Quick Access must not overwrite the main state.

**This live check is necessary on your Framework.** Our automated watcher test does not replace a real run on Fedora/KDE-Wayland.

## Repair, migration, and reset

Never edit the live session manually while Kitty is running: the watcher could overwrite it.

```bash
./migrate-kitty-state.py    # only remove known old starter tabs
./reset-kitty-state.sh      # discard all saved tabs; backup before reset
./state-status.py           # read-only status check
```

For the historical error caused by old launchers there is `repair-v1.5-startup.sh`. Always use the visible **Kitty Workspace** launcher instead of older `kitty --session melody-mind...` starters.

## Multiple instances

The pack launcher uses `kitty --single-instance --instance-group=kitty-workspace` so that regular new windows belong to the same Kitty process. A differently started, independent Kitty instance with the same config can still use the same session file. Avoid parallel independent instances for the persistent workspace.

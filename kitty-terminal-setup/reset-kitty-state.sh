#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KITTY_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
STATE_FILE="$KITTY_CONFIG_DIR/last-state.kitty-session"
DEFAULT_FILE="$SCRIPT_DIR/state/default-state.kitty-session"
BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/kitty-workspace-pack/state-backups"

if pgrep -x kitty >/dev/null 2>&1; then
  cat >&2 <<'EOF'
Kitty is currently running.
Close the normal Kitty instance first, otherwise the autosave watcher could
immediately overwrite the reset state again.
EOF
  exit 1
fi

mkdir -p "$KITTY_CONFIG_DIR" "$BACKUP_DIR"
if [[ -f "$STATE_FILE" ]]; then
  cp -a "$STATE_FILE" "$BACKUP_DIR/last-state-$(date +%Y%m%d-%H%M%S).kitty-session"
fi
cp "$DEFAULT_FILE" "$STATE_FILE"
if [[ ! -d "$HOME/dev/gitlab/unified-frontend" ]]; then
  printf 'WARN: Unified Frontend checkout not found; reset tabs will start in HOME.\n' >&2
  sed -i 's|^cd ~/dev/gitlab/unified-frontend$|cd ~|' "$STATE_FILE"
fi
printf 'Reset complete. Next Kitty start will open:\n'
printf '  Unified Frontend 1\n  Unified Frontend 2\n'

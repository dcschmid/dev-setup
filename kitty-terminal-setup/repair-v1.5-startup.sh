#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KITTY_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
KITTY_CONFIG="$KITTY_CONFIG_DIR/kitty.conf"
MANAGED_CONFIG="$KITTY_CONFIG_DIR/local-workspaces.conf"
LIVE_STATE="$KITTY_CONFIG_DIR/last-state.kitty-session"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
AUTOSTART_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/kitty-workspace-pack/migration-backups/$(date +%Y%m%d-%H%M%S)"

mkdir -p "$KITTY_CONFIG_DIR" "$APP_DIR" "$BACKUP_DIR"

find_kitty() {
  if command -v kitty >/dev/null 2>&1; then
    command -v kitty
  elif [[ -x "$HOME/.local/kitty.app/bin/kitty" ]]; then
    printf '%s\n' "$HOME/.local/kitty.app/bin/kitty"
  else
    return 1
  fi
}

KITTY_BIN="$(find_kitty 2>/dev/null || true)"
[[ -n "$KITTY_BIN" ]] || { echo "Kitty was not found." >&2; exit 1; }

backup_file() {
  local src="$1"
  [[ -f "$src" ]] || return 0
  local safe
  safe="$(printf '%s' "$src" | sed "s|^$HOME/||; s|/|__|g")"
  cp -a "$src" "$BACKUP_DIR/$safe"
}

sanitize_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  grep -Eq 'melody-mind\.kitty-session|unified-frontend\.kitty-session' "$file" 2>/dev/null || return 0

  backup_file "$file"
  local tmp
  tmp="$(mktemp)"

  if [[ "$file" == *.desktop ]]; then
    awk -v kitty="$KITTY_BIN" '
      /^Exec=/ && ($0 ~ /melody-mind\.kitty-session/ || $0 ~ /unified-frontend\.kitty-session/) {
        print "Exec=" kitty
        next
      }
      {print}
    ' "$file" > "$tmp"
  else
    awk '
      /melody-mind\.kitty-session/ {next}
      /unified-frontend\.kitty-session/ {next}
      {print}
    ' "$file" > "$tmp"
  fi

  cat "$tmp" > "$file"
  rm -f "$tmp"
  printf 'Repaired: %s\n' "$file"
}

sanitize_file "$KITTY_CONFIG"

for dir in "$APP_DIR" "$AUTOSTART_DIR"; do
  [[ -d "$dir" ]] || continue
  while IFS= read -r -d '' file; do
    sanitize_file "$file"
  done < <(find "$dir" -maxdepth 1 -type f -name '*.desktop' -print0 2>/dev/null)
done

cat > "$APP_DIR/kitty-workspace.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Kitty Workspace
Comment=Open the persistent Kitty workspace
Exec=$KITTY_BIN --single-instance --instance-group=kitty-workspace
Icon=kitty
Terminal=false
Categories=Development;System;TerminalEmulator;
StartupNotify=true
DESKTOP
chmod 0644 "$APP_DIR/kitty-workspace.desktop"

# Retire legacy launcher IDs rather than restoring the deleted projects.
rm -f "$APP_DIR/kitty-melody-mind.desktop" "$APP_DIR/kitty-unified-frontend.desktop"

if [[ ! -f "$LIVE_STATE" && -f "$SCRIPT_DIR/state/default-state.kitty-session" ]]; then
  cp "$SCRIPT_DIR/state/default-state.kitty-session" "$LIVE_STATE"
  printf 'Created persistent baseline: %s\n' "$LIVE_STATE"
fi

if [[ -f "$MANAGED_CONFIG" ]]; then
  if grep -Eq '^[[:space:]]*startup_session[[:space:]]+' "$MANAGED_CONFIG"; then
    sed -i -E 's|^[[:space:]]*startup_session[[:space:]]+.*$|startup_session last-state.kitty-session|' "$MANAGED_CONFIG"
  else
    printf '\nstartup_session last-state.kitty-session\n' >> "$MANAGED_CONFIG"
  fi
fi

command -v update-desktop-database >/dev/null 2>&1 && \
  update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true

cat <<EOF

Repair complete.

Use:
  Kitty Workspace

Emergency direct start:
  $KITTY_BIN --session "$LIVE_STATE"

Old project launchers were removed. Pin "Kitty Workspace" in GNOME instead.

Backup:
  $BACKUP_DIR
EOF

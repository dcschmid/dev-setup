#!/usr/bin/env bash
set -euo pipefail

PACK_NAME="kitty-workspace-pack"
KITTY_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
KITTY_CONFIG="$KITTY_CONFIG_DIR/kitty.conf"
MANAGED_CONFIG="$KITTY_CONFIG_DIR/local-workspaces.conf"
MANAGED_THEME="$KITTY_CONFIG_DIR/themes/catppuccin-mocha.conf"
CHOOSE_FILES_CONF="$KITTY_CONFIG_DIR/choose-files.conf"
QUICK_ACCESS_CONF="$KITTY_CONFIG_DIR/quick-access-terminal.conf"
AUTOSAVE_WATCHER="$KITTY_CONFIG_DIR/state-autosave.py"
LIVE_STATE="$KITTY_CONFIG_DIR/last-state.kitty-session"

SESSION_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/kitty/sessions"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
LOCAL_BIN="$HOME/.local/bin"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/$PACK_NAME"
GIT_INCLUDE="${XDG_CONFIG_HOME:-$HOME/.config}/git/kitty-workspace.inc"

KW_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty-workspace"
KW_ZSH_CONFIG="$KW_CONFIG_DIR/zsh/kitty-workspace.zsh"
ZSHRC="$HOME/.zshrc"
OMZ_THEME="$HOME/.oh-my-zsh/custom/themes/kitty-mocha.zsh-theme"

printf 'Removing Kitty Workspace Pack managed files...\n'

rm -f "$MANAGED_CONFIG" "$MANAGED_THEME"
rm -f "$CHOOSE_FILES_CONF" "$QUICK_ACCESS_CONF" "${XDG_CONFIG_HOME:-$HOME/.config}/kitty/quick-access-kitty.conf" "$AUTOSAVE_WATCHER"
rm -f "$SESSION_DIR/melody-mind.kitty-session"
rm -f "$SESSION_DIR/unified-frontend.kitty-session"
rm -f "$APP_DIR/kitty-melody-mind.desktop"
rm -f "$APP_DIR/kitty-unified-frontend.desktop"
rm -f "$APP_DIR/kitty-workspace.desktop"
rm -f "$APP_DIR/kitty-quick-access.desktop"
rm -f "$LOCAL_BIN/kitty-quick-access"
rm -f "$LOCAL_BIN/git-worktree-helper"
rm -f "$KW_ZSH_CONFIG"
rm -f "$OMZ_THEME"


if command -v git >/dev/null 2>&1; then
  # Remove only this pack's include entry; leave all other Git config intact.
  git config --global --fixed-value --unset-all include.path "$GIT_INCLUDE" >/dev/null 2>&1 || true
fi
rm -f "$GIT_INCLUDE"

if [[ -f "$KITTY_CONFIG" ]]; then
  tmp="$(mktemp)"
  awk '
    $0 == "# Kitty Workspace Pack" {next}
    $0 == "include local-workspaces.conf" {next}
    {print}
  ' "$KITTY_CONFIG" > "$tmp"
  cat "$tmp" > "$KITTY_CONFIG"
  rm -f "$tmp"
fi

if [[ -f "$ZSHRC" ]]; then
  tmp="$(mktemp)"
  awk '
    $0 == "# Kitty Workspace Pack — managed Zsh entry point" {next}
    $0 == "# Kitty Workspace Pack" {next}
    index($0, "kitty-workspace/zsh/kitty-workspace.zsh") {next}
    {print}
  ' "$ZSHRC" > "$tmp"
  cat "$tmp" > "$ZSHRC"
  rm -f "$tmp"
fi

command -v update-desktop-database >/dev/null 2>&1 && \
  update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true

cat <<'MSG'

Removed the pack's managed Kitty/Zsh files.

Intentionally NOT removed:
- Kitty itself
- Oh My Zsh
- zsh-autosuggestions / zsh-syntax-highlighting repositories
- fzf / zoxide / direnv / ripgrep / fd system packages
- eza / bat / delta / lazygit binaries or packages
- Atuin binary or local history database
- your shared secrets file
- your persistent last-state.kitty-session
- any personal/custom Kitty session files
- your system login shell
MSG

if [[ -f "$STATE_DIR/install-info" ]]; then
  backup="$(awk -F= '$1=="backup_dir" {sub(/^backup_dir=/, ""); print}' "$STATE_DIR/install-info" || true)"
  if [[ -n "$backup" && -d "$backup" ]]; then
    printf '\nBackup still available at:\n  %s\n' "$backup"
  fi
fi

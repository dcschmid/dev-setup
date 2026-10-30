#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty-workspace"
SECRETS="$CONFIG_DIR/secrets.zsh"
BASHRC="$HOME/.bashrc"
STAMP="$(date +%Y%m%d-%H%M%S)"

cat <<'MSG'
Kitty Workspace Pack — Shared Secrets Setup

IMPORTANT:
- Rotate the old Lemonade / YOLO Auto credentials FIRST.
- Enter only the newly rotated values below.
- Input is hidden.
- This helper stores them in a 0600 file shared by Bash and Zsh.
MSG

mkdir -p "$CONFIG_DIR"

read -rsp "New LEMONADE_API_KEY (leave empty to skip): " lemonade
printf '\n'
read -rsp "New YOLO_AUTO_API_KEY (leave empty to skip): " yolo
printf '\n'

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

{
  echo "# Shared shell secrets — generated $(date -Iseconds)"
  echo "# Permissions: 0600"
  [[ -n "$lemonade" ]] && printf 'export LEMONADE_API_KEY=%q\n' "$lemonade"
  [[ -n "$yolo" ]] && printf 'export YOLO_AUTO_API_KEY=%q\n' "$yolo"
} > "$tmp"

install -m 0600 "$tmp" "$SECRETS"

# Back up and remove old inline copies from Bash, without ever printing values.
if [[ -f "$BASHRC" ]]; then
  cp -a "$BASHRC" "$BASHRC.kitty-workspace-secrets-backup-$STAMP"
  sed -i \
    -e '/^[[:space:]]*export[[:space:]]\+LEMONADE_API_KEY=/d' \
    -e '/^[[:space:]]*export[[:space:]]\+YOLO_AUTO_API_KEY=/d' \
    "$BASHRC"

  if ! grep -Fq 'kitty-workspace/secrets.zsh' "$BASHRC"; then
    cat >> "$BASHRC" <<'BASHBLOCK'

# Kitty Workspace Pack — shared shell secrets
_KW_SECRETS="${XDG_CONFIG_HOME:-$HOME/.config}/kitty-workspace/secrets.zsh"
[[ -r "$_KW_SECRETS" ]] && . "$_KW_SECRETS"
unset _KW_SECRETS
BASHBLOCK
  fi
fi

unset lemonade yolo

printf '\nSaved securely to:\n  %s\n' "$SECRETS"
printf 'Permissions: '
stat -c '%a' "$SECRETS" 2>/dev/null || true
printf '\nBash backup (if ~/.bashrc existed): ~/.bashrc.kitty-workspace-secrets-backup-%s\n' "$STAMP"
printf '\nOpen a new Bash/Zsh tab after rotating the server-side keys.\n'

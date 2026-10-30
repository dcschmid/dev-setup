#!/usr/bin/env bash
set -euo pipefail

if ! command -v atuin >/dev/null 2>&1 && [[ ! -x "$HOME/.atuin/bin/atuin" ]]; then
  echo "Atuin is not installed." >&2
  exit 1
fi

ATUIN_BIN="$(command -v atuin 2>/dev/null || printf '%s' "$HOME/.atuin/bin/atuin")"

cat <<'MSG'
Atuin history import

This imports existing shell history into Atuin.
Your original Bash/Zsh history files are left untouched.

Because shell history can contain old sensitive commands, this step is NOT
performed automatically by Kitty Workspace Pack.
MSG

printf '\nImport existing shell history now? [y/N] '
read -r answer

case "$answer" in
  [Yy]|[Yy][Ee][Ss])
    "$ATUIN_BIN" import auto
    echo
    echo "Import complete."
    ;;
  *)
    echo "No history imported."
    ;;
esac

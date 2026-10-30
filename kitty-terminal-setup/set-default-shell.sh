#!/usr/bin/env bash
set -euo pipefail

if ! command -v zsh >/dev/null 2>&1; then
  echo "Zsh is not installed." >&2
  exit 1
fi

ZSH_BIN="$(command -v zsh)"
printf 'Current login shell: %s\n' "${SHELL:-unknown}"
printf 'Requested login shell: %s\n\n' "$ZSH_BIN"
printf 'This is OPTIONAL. Kitty already uses Zsh without changing your system login shell.\n'
printf 'Change the login shell now? [y/N] '
read -r answer
case "$answer" in
  [Yy]|[Yy][Ee][Ss])
    chsh -s "$ZSH_BIN"
    printf '\nLogin shell changed. Log out and back in for it to take effect.\n'
    ;;
  *)
    printf 'No change made.\n'
    ;;
esac

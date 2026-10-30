#!/usr/bin/env bash
set -euo pipefail

BASH_BIN="$(command -v bash)"
printf 'Current login shell: %s\n' "${SHELL:-unknown}"
printf 'Requested login shell: %s\n\n' "$BASH_BIN"
printf 'Switch the login shell back to Bash? [y/N] '
read -r answer
case "$answer" in
  [Yy]|[Yy][Ee][Ss])
    chsh -s "$BASH_BIN"
    printf '\nLogin shell changed back to Bash. Log out and back in for it to take effect.\n'
    ;;
  *)
    printf 'No change made.\n'
    ;;
esac

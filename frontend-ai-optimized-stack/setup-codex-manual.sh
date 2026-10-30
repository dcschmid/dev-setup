#!/usr/bin/env bash
# Stop only the old stack-managed cxswap daemon; no token or login changes.
set -euo pipefail
mode="${1:-}"
[[ "$mode" == '' || "$mode" == '--preflight' ]] || { echo 'Usage: ./setup-codex-manual.sh [--preflight]' >&2; exit 2; }
unit="$HOME/.config/systemd/user/codex-swap-auto.service"
loaded=''
if command -v systemctl >/dev/null 2>&1; then
  loaded="$(systemctl --user cat codex-swap-auto.service 2>/dev/null || true)"
fi
if [[ -n "$loaded" && "$loaded" != *'# Managed by Frontend AI Stack v3.12.0'* ]]; then
  echo 'ERROR: Found a non-stack managed codex-swap-auto.service; disable it manually.' >&2
  exit 1
fi
if [[ -e "$unit" ]] && ! grep -q '^# Managed by Frontend AI Stack v3.12.0$' "$unit"; then
  echo 'ERROR: Refusing to alter a user-owned systemd unit.' >&2; exit 1
fi
if [[ "$mode" == '--preflight' ]]; then
  echo 'PASS: Codex swap unit preflight'; exit 0
fi
if [[ -e "$unit" || -n "$loaded" ]] && command -v systemctl >/dev/null 2>&1; then
  systemctl --user disable --now codex-swap-auto.service
  systemctl --user daemon-reload
fi
if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active --quiet codex-swap-auto.service; then
  echo 'ERROR: Codex auto-rotation service remains active.' >&2; exit 1
fi
echo 'PASS: Codex automatic rotation is disabled (cxswap/codex-switch account data retained).'
echo 'Use codex-private / codex-working. Run native codex login for each separate CODEX_HOME as needed.'

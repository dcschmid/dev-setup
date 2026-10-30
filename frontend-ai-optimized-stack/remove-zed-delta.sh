#!/usr/bin/env bash
set -euo pipefail
umask 077
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "${1:---scan}" in
  --scan) exec python3 "$ROOT/scripts/cleanup_zed_delta.py" ;;
  --check) exec python3 "$ROOT/scripts/cleanup_zed_delta.py" --check ;;
  --apply)
    stamp="$(date +%Y%m%d-%H%M%S)-$$"
    backup="$HOME/.frontend-ai-stack-backups/${stamp}-zed-delta-removal"
    exec python3 "$ROOT/scripts/cleanup_zed_delta.py" --apply --backup-dir "$backup"
    ;;
  *) echo 'Usage: ./remove-zed-delta.sh [--scan|--check|--apply]' >&2; exit 2 ;;
esac

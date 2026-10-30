#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
install_zed=false
forward=()
for arg in "$@"; do
  case "$arg" in
    --install-zed) install_zed=true ;;
    *) forward+=("$arg") ;;
  esac
done
if [[ ${EUID} -eq 0 ]]; then
  echo 'Do not run with sudo; Zed and this devkit are installed into your user home.' >&2
  exit 1
fi
if ! command -v python3 >/dev/null; then
  echo 'python3 not found; install Python 3 via Fedora first.' >&2
  exit 1
fi
if $install_zed && [[ " ${forward[*]} " != *' --dry-run '* ]]; then
  if ! command -v zed >/dev/null 2>&1; then
    echo 'Downloading official Zed stable install script to a temporary file.'
    echo 'Official source: https://zed.dev/docs/installation'
    command -v curl >/dev/null 2>&1 || { echo 'curl missing' >&2; exit 1; }
    temp=$(mktemp)
    trap 'rm -f "$temp"' EXIT
    curl --fail --show-error --silent --location --proto '=https' --tlsv1.2 https://zed.dev/install.sh -o "$temp"
    sh "$temp"
  else
    echo 'Zed already found in PATH; skipping binary installation.'
  fi
fi
python3 "$ROOT/scripts/manage_config.py" "${forward[@]}"
echo
echo 'Next: start/restart Zed, wait for extensions, then use Ctrl+Shift+P → task: spawn.'
echo 'Check system prerequisites with: ./scripts/check.sh'

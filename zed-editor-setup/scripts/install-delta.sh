#!/usr/bin/env bash
# Optional Delta app from Zed Industries. Does not install the Claude plugin or enable sync.
set -euo pipefail
usage() {
  cat <<'HELP'
Usage: ./scripts/install-delta.sh --dry-run | --install | --status | --update

--dry-run  Show instructions; no downloads or changes
--install  Download the official https://delta.dev/install.sh to a temp file and run it
--status   Check for the app and CLI; make no changes
--update   Use the existing official Delta CLI to update Delta

This is Delta from Zed Industries, NOT the unrelated git-delta pager.
HELP
}
[[ ${EUID} -ne 0 ]] || { echo 'Do not run as root/sudo.' >&2; exit 1; }
[[ $# -eq 1 ]] || { usage; exit 2; }
case "$1" in
  --dry-run)
    cat <<'HELP'
Optional Delta install:
  Official source: https://delta.dev/docs/installation
  App location:    ~/.local/delta.app
  CLI:             ~/.local/bin/delta
  Login required:  Zed account and Delta Early Access Agreement.
  No Claude Code plugin or automatic syncing will be configured.
Run: ./scripts/install-delta.sh --install
HELP
    ;;
  --status)
    [[ -d "$HOME/.local/delta.app" ]] && echo '[OK] Delta application directory found' || echo '[--] Delta application not installed'
    if command -v delta >/dev/null 2>&1; then
      echo "CLI on PATH: $(command -v delta)"
      echo 'Check this is Delta by Zed Industries, not git-delta.'
    else
      echo '[--] delta CLI not on PATH'
    fi
    ;;
  --install)
    command -v curl >/dev/null || { echo 'curl not installed' >&2; exit 1; }
    command -v python3 >/dev/null || { echo 'python3 not installed' >&2; exit 1; }
    # Do not silently collide with a custom ~/.local/bin/delta, often git-delta.
    dest="$HOME/.local/bin/delta"
    if [[ -e "$dest" || -L "$dest" ]]; then
      resolved=$(readlink -f "$dest" || true)
      if [[ "$resolved" != "$HOME/.local/delta.app/"* ]]; then
        echo "Path collision: $dest points to ${resolved:-unknown}." >&2
        echo 'Resolve it first; git-delta is a separate tool.' >&2
        exit 1
      fi
    fi
    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT
    echo 'Fetching the official Delta installation script; review source if desired:'
    echo 'https://delta.dev/install.sh'
    curl --fail --show-error --silent --location --proto '=https' --tlsv1.2 \
      https://delta.dev/install.sh -o "$tmp"
    sh "$tmp"
    echo 'Installed Delta? Start with delta (requires Zed login).'
    ;;
  --update)
    [[ -d "$HOME/.local/delta.app" ]] || { echo 'Delta app not installed' >&2; exit 1; }
    command -v delta >/dev/null || { echo 'Delta CLI not on PATH' >&2; exit 1; }
    delta update
    ;;
  -h|--help) usage ;;
  *) usage; exit 2 ;;
esac

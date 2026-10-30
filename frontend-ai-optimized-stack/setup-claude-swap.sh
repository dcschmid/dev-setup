#!/usr/bin/env bash
set -euo pipefail

VERSION="${MM_CLAUDE_SWAP_VERSION:-v0.26.0}"
WORK_ACCOUNT="${MM_CLAUDE_WORK_ACCOUNT:-}"
THRESHOLD="${MM_CLAUDE_SWAP_THRESHOLD:-90}"
STRATEGY="${MM_CLAUDE_PRIVATE_STRATEGY:-best}"
ENABLE_SERVICE="${MM_CLAUDE_SWAP_ENABLE_SERVICE:-1}"

usage(){ cat <<'EOF'
Usage: setup-claude-swap.sh [--work-account ALIAS] [--threshold N] [--strategy best|next-available|consume-first] [--no-service]

Before running this helper, add each Claude account with `cswap add` (or let this
helper install cswap first, then add them and rerun). Give the company account an
alias such as `work`; private accounts remain enabled for auto-rotation.
EOF
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --work-account) WORK_ACCOUNT="$2"; shift 2;;
    --threshold) THRESHOLD="$2"; shift 2;;
    --strategy) STRATEGY="$2"; shift 2;;
    --no-service) ENABLE_SERVICE=0; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2;;
  esac
done

command -v uv >/dev/null 2>&1 || { echo 'ERROR: uv is required to install claude-swap.' >&2; exit 1; }

if ! command -v cswap >/dev/null 2>&1; then
  echo "Installing claude-swap $VERSION from the official GitHub repository..."
  uv tool install "git+https://github.com/realiti4/claude-swap.git@${VERSION}"
else
  echo "claude-swap already installed: $(command -v cswap)"
fi
hash -r
command -v cswap >/dev/null 2>&1 || { echo 'ERROR: cswap is still not in PATH.' >&2; exit 1; }

# Configure stable autoswitch defaults. These commands are intentionally best-effort
# so the helper remains compatible with older cswap configs during upgrades.
cswap config set autoswitch.threshold "$THRESHOLD" >/dev/null 2>&1 || true
cswap config set autoswitch.strategy "$STRATEGY" >/dev/null 2>&1 || true

if cswap list >/dev/null 2>&1; then
  if [[ -n "$WORK_ACCOUNT" ]] && cswap disable "$WORK_ACCOUNT" >/dev/null 2>&1; then
    echo "Working account '$WORK_ACCOUNT' disabled from private auto-rotation."
  elif [[ -n "$WORK_ACCOUNT" ]]; then
    echo "WARN: could not disable '$WORK_ACCOUNT'. Add/alias the work account first, then run: cswap disable $WORK_ACCOUNT" >&2
  fi
else
  echo 'INFO: no stored accounts yet. Add them with `cswap add`, alias the company account, then rerun this helper.'
fi

if [[ "$ENABLE_SERVICE" == 1 ]]; then
  if command -v systemctl >/dev/null 2>&1; then
    CSWAP="$(command -v cswap)"
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$HOME/.config/systemd/user/claude-swap-auto.service" <<EOF
[Unit]
Description=Claude Swap automatic private account rotation
After=default.target

[Service]
Type=simple
ExecStart=$CSWAP auto --threshold $THRESHOLD --strategy $STRATEGY
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable --now claude-swap-auto.service
    echo 'Enabled user service: claude-swap-auto.service'
  else
    echo 'WARN: systemctl not available. Run `cswap auto` in a persistent terminal instead.' >&2
  fi
fi

echo
echo 'Recommended account layout:'
echo '  private account(s): enabled -> participate in cswap auto'
[[ -n "$WORK_ACCOUNT" ]] && echo "  working account:    alias '$WORK_ACCOUNT', disabled -> explicit claude-working only" || true
echo
echo 'Add accounts without /logout:'
echo '  1) log into Claude Code with an account'
echo '  2) cswap add'
echo '  3) repeat for the next account'
[[ -n "$WORK_ACCOUNT" ]] && { echo "  4) cswap alias <slot> $WORK_ACCOUNT"; echo "  5) cswap disable $WORK_ACCOUNT"; } || true
echo
echo 'Then use: claude-private  /  claude-working'

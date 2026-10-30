#!/usr/bin/env bash
# Install only the official OMP CLI binary if missing. Never modify credentials.
set -euo pipefail
umask 077
INSTALL_DIR="$HOME/.local/bin"
OMP_BIN="$INSTALL_DIR/omp"
OFFICIAL_URL="https://omp.sh/install"

usage() { echo "Usage: $0 --install|--check"; }

resolve_omp() {
  if command -v omp >/dev/null 2>&1; then
    command -v omp
  elif [[ -x "$OMP_BIN" ]]; then
    printf '%s\n' "$OMP_BIN"
  else
    return 1
  fi
}

check_omp() {
  local candidate
  candidate="$(resolve_omp)" || { echo 'FAIL  Oh My Pi CLI not found' >&2; return 1; }
  if ! "$candidate" --version >/dev/null 2>&1; then
    echo "FAIL  Oh My Pi CLI cannot start: $candidate" >&2
    return 1
  fi
  echo "PASS  Oh My Pi CLI: $candidate ($("$candidate" --version))"
}

ensure_zsh_path() {
  # Interactive Kitty/Zsh sessions should see ~/.local/bin without manual exports.
  # Only change the rc when the installed CLI is located in ~/.local/bin AND the
  # directory is currently missing from PATH. Never overwrite existing settings.
  [[ -x "$OMP_BIN" ]] || return 0
  case ":$PATH:" in *":$INSTALL_DIR:"*) return 0 ;; esac
  local rc="$HOME/.zshrc"
  local marker='# BEGIN FRONTEND-AI-STACK LOCAL BIN PATH'
  if ! grep -Fqx "$marker" "$rc" 2>/dev/null; then
    touch "$rc"
    cat >> "$rc" <<'BLOCK'

# BEGIN FRONTEND-AI-STACK LOCAL BIN PATH
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
# END FRONTEND-AI-STACK LOCAL BIN PATH
BLOCK
    echo 'INFO  Added ~/.local/bin to ~/.zshrc for future Kitty/Zsh sessions.'
  fi
  echo 'INFO  Open a new shell (or run: exec zsh) to pick up the PATH change.'
}

case "${1:---install}" in
  --check)
    [[ $# -eq 1 ]] || { usage >&2; exit 2; }
    check_omp
    ;;
  --install)
    [[ $# -le 1 ]] || { usage >&2; exit 2; }
    if candidate="$(resolve_omp)" && "$candidate" --version >/dev/null 2>&1; then
      echo "INFO  Existing OMP installation kept: $candidate"
      check_omp
      ensure_zsh_path
      exit 0
    fi
    if [[ -e "$OMP_BIN" || -L "$OMP_BIN" ]]; then
      echo "ERROR: $OMP_BIN exists but is unusable; refusing to overwrite it automatically." >&2
      exit 1
    fi
    if command -v omp >/dev/null 2>&1; then
      echo 'ERROR: Existing omp in PATH cannot start. Please repair it first.' >&2
      exit 1
    fi
    command -v curl >/dev/null 2>&1 || { echo 'ERROR: curl missing (install: sudo dnf install curl)' >&2; exit 1; }
    command -v sha256sum >/dev/null 2>&1 || { echo 'ERROR: sha256sum missing' >&2; exit 1; }
    mkdir -p "$INSTALL_DIR"
    temp="$(mktemp "${TMPDIR:-/tmp}/frontend-ai-omp-installer.XXXXXXXX.sh")"
    trap 'rm -f "$temp"' EXIT
    echo "INFO  Downloading the official Oh My Pi installer from $OFFICIAL_URL"
    echo 'INFO  The vendor installer checks the downloaded binary SHA-256 before installation.'
    curl -fsSL --retry 2 --connect-timeout 15 --max-time 90 "$OFFICIAL_URL" -o "$temp"
    [[ -s "$temp" ]] || { echo 'ERROR: empty OMP installer; nothing executed' >&2; exit 1; }
    chmod 0600 "$temp"
    # Force binary mode to avoid implicitly installing Bun or global npm packages.
    PI_INSTALL_DIR="$INSTALL_DIR" sh "$temp" --binary
    [[ -x "$OMP_BIN" ]] || { echo "ERROR: installation did not create executable $OMP_BIN" >&2; exit 1; }
    "$OMP_BIN" --version >/dev/null || { echo 'ERROR: installed OMP binary failed startup check' >&2; exit 1; }
    check_omp
    ensure_zsh_path
    ;;
  *) usage >&2; exit 2 ;;
esac

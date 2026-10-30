#!/usr/bin/env bash
set -euo pipefail
ROOT_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/frontend-ai-stack"
SRC="$ROOT_CONF/omp-completions.zsh"
BEGIN='# BEGIN FRONTEND-AI-STACK OMP COMPLETIONS'
END='# END FRONTEND-AI-STACK OMP COMPLETIONS'
case "${1:-}" in
  --install)
    umask 077
    mkdir -p "$ROOT_CONF"
    printf '%s\n' 'if command -v omp >/dev/null 2>&1; then' '  eval "$(omp completions zsh)"' 'fi' > "$SRC"
    touch "$HOME/.zshrc"
    if ! grep -Fqx "$BEGIN" "$HOME/.zshrc"; then
      printf '\n%s\nsource "%s"\n%s\n' "$BEGIN" "$SRC" "$END" >> "$HOME/.zshrc"
    fi
    echo "PASS  OMP zsh completions installed. Open a new Kitty/Zsh shell."
    ;;
  --check)
    [[ -f "$SRC" ]] && grep -Fqx "$BEGIN" "$HOME/.zshrc" 2>/dev/null && echo 'PASS  OMP zsh completions' || { echo 'INFO  OMP completions not yet enabled'; exit 1; }
    ;;
  *) echo "Usage: $0 --install|--check"; exit 2;;
esac

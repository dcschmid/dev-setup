#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-$HOME/shell-migration-review.txt}"
SENSITIVE='API[_-]?KEY|TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIAL|AUTHORIZATION|BEARER|PRIVATE[_-]?KEY|ACCESS[_-]?KEY|CLIENT[_-]?SECRET'

redact_file() {
  local f="$1"
  awk -v re="$SENSITIVE" '
    {
      upper=toupper($0)
      if (upper ~ re) {
        printf "%6d  [REDACTED: sensitive-looking line]\n", NR
      } else {
        printf "%6d  %s\n", NR, $0
      }
    }
  ' "$f"
}

{
  echo "# Shell migration review"
  echo "Generated: $(date -Iseconds)"
  echo "Current SHELL: ${SHELL:-unknown}"
  echo
  echo "## PATH entries"
  tr ':' '\n' <<< "${PATH:-}" | awk 'NF && !seen[$0]++'
  echo
  for f in "$HOME/.bashrc" "$HOME/.bash_aliases" "$HOME/.bash_functions" "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile" "$HOME/.zshrc"; do
    [[ -f "$f" ]] || continue
    echo
    echo "## $f"
    redact_file "$f"
  done
} > "$OUT"

chmod 0600 "$OUT"
echo "Created: $OUT"
echo "Review it before sharing. Sensitive-looking lines are removed."

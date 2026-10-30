#!/usr/bin/env bash
set -euo pipefail
# Never run downloaded TypeScript or install from unreviewed mutable HEAD.
# Stage for source inspection and require the user to supply its exact hash.
SOURCE='https://raw.githubusercontent.com/yolo-auto-org/yolo-auto-omp/main/yolo-todo-discipline.ts'
STAGED="${XDG_CACHE_HOME:-$HOME/.cache}/frontend-ai-stack/yolo-todo-discipline.ts"
usage(){ echo "Usage: $0 --stage | --enable <64-char SHA256> | --disable | --check"; }
mode="${1:-}"
case "$mode" in
  --stage)
    command -v curl >/dev/null || { echo 'curl missing' >&2; exit 1; }
    umask 077
    mkdir -p "$(dirname "$STAGED")"
    tmp="$(mktemp "${STAGED}.XXXXXXXX")"
    trap 'rm -f "$tmp"' EXIT
    curl --proto '=https' --tlsv1.2 -fLsS --connect-timeout 12 --max-time 60 "$SOURCE" -o "$tmp"
    [[ -s "$tmp" ]] && [[ $(wc -c < "$tmp") -le 65536 ]] || { echo 'Extension empty or too large' >&2; exit 1; }
    mv -f "$tmp" "$STAGED"
    printf 'STAGED %s\n' "$STAGED"
    sha256sum "$STAGED"
    echo 'Review the source with your editor, then use --enable with the SHA256 shown above.'
    ;;
  --enable)
    expected="${2:-}"
    [[ "$expected" =~ ^[a-fA-F0-9]{64}$ ]] || { usage; exit 2; }
    [[ -f "$STAGED" && ! -L "$STAGED" ]] || { echo 'Stage extension first' >&2; exit 1; }
    actual="$(sha256sum "$STAGED" | cut -d' ' -f1)"
    [[ "$actual" == "${expected,,}" ]] || { echo 'SHA256 mismatch; refusing activation' >&2; exit 1; }
    for profile in working private; do
      dst="$HOME/.omp/profiles/$profile/agent/extensions/yolo-todo-discipline.ts"
      mkdir -p "$(dirname "$dst")"
      if [[ -e "$dst" && ! -L "$dst" ]] && ! cmp -s "$dst" "$STAGED"; then
        echo "Existing extension differs: $dst; not overwriting" >&2; exit 1
      fi
      [[ ! -L "$dst" ]] || { echo "Symlink at $dst; manual inspection required" >&2; exit 1; }
    done
    for profile in working private; do
      dst="$HOME/.omp/profiles/$profile/agent/extensions/yolo-todo-discipline.ts"
      install -m 0600 "$STAGED" "$dst"
      printf "%s\n" "$actual" > "$(dirname "$dst")/.mm-yolo-todo.sha256"
      chmod 0600 "$(dirname "$dst")/.mm-yolo-todo.sha256"
      echo "PASS  $profile todo discipline ($actual)"
    done
    echo 'Restart OMP sessions to load the extension. It gates only model yolo-auto/yolo.'
    ;;
  --disable)
    for profile in working private; do
      dir="$HOME/.omp/profiles/$profile/agent/extensions"
      dst="$dir/yolo-todo-discipline.ts"
      marker="$dir/.mm-yolo-todo.sha256"
      if [[ ! -f "$dst" ]]; then echo "INFO  $profile: already disabled"; continue; fi
      if [[ ! -f "$marker" || -L "$dst" ]]; then echo "WARN  $profile: not managed; refusing deletion"; continue; fi
      expected="$(cat "$marker")"; actual="$(sha256sum "$dst" | cut -d' ' -f1)"
      if [[ "$expected" != "$actual" ]]; then echo "WARN  $profile: extension modified; refusing deletion"; continue; fi
      rm -- "$dst" "$marker"
      echo "PASS  $profile: disabled"
    done
    ;;
  --check)
    for profile in working private; do
      dst="$HOME/.omp/profiles/$profile/agent/extensions/yolo-todo-discipline.ts"
      if [[ -f "$dst" ]]; then sha256sum "$dst"; else echo "INFO  $profile: not activated"; fi
    done
    ;;
  *) usage; exit 2;;
esac

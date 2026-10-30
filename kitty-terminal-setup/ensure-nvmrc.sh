#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-$PWD}"

if [[ ! -d "$TARGET" ]]; then
  echo "Directory not found: $TARGET" >&2
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"
NVMRC="$TARGET/.nvmrc"
PACKAGE_JSON="$TARGET/package.json"

echo "NVM project check"
echo "Project: $TARGET"
echo

if [[ -f "$NVMRC" ]]; then
  echo "Existing .nvmrc:"
  printf '  %s\n' "$(tr -d '\r\n' < "$NVMRC")"
  exit 0
fi

if [[ -f "$PACKAGE_JSON" ]] && command -v node >/dev/null 2>&1; then
  NODE_HINT="$(node - "$PACKAGE_JSON" <<'NODE' 2>/dev/null || true
const fs = require('fs');
const f = process.argv[2];
try {
  const p = JSON.parse(fs.readFileSync(f, 'utf8'));
  if (p.engines && typeof p.engines.node === 'string') console.log(p.engines.node);
} catch {}
NODE
)"
  if [[ -n "${NODE_HINT:-}" ]]; then
    echo "package.json engines.node:"
    echo "  $NODE_HINT"
    echo
  fi
fi

if ! command -v node >/dev/null 2>&1; then
  echo "No .nvmrc found and Node is not currently available."
  exit 0
fi

CURRENT="$(node -v | sed 's/^v//')"
echo "Current Node:"
echo "  $CURRENT"
echo
printf 'Create .nvmrc with %s? [y/N] ' "$CURRENT"
read -r answer
case "$answer" in
  [Yy]|[Yy][Ee][Ss])
    printf '%s\n' "$CURRENT" > "$NVMRC"
    echo "Created: $NVMRC"
    ;;
  *)
    echo "No file created."
    ;;
esac

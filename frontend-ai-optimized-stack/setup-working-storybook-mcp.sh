#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${1:-$PWD}"
ROOT="$(cd "$ROOT" && pwd)"
[[ -f "$ROOT/package.json" ]] || { echo 'ERROR: run this in a working frontend repository (package.json missing).' >&2; exit 1; }
PORT="${STORYBOOK_PORT:-6006}"
URL="http://127.0.0.1:$PORT/mcp"
PAYLOAD="$(python3 - "$URL" <<'PY'
import json,sys
print(json.dumps({'url':sys.argv[1]},separators=(',',':')))
PY
)"
# Portable project MCP for Claude discovery.
python3 "$SCRIPT_DIR/scripts/merge_project_mcp.py" "$ROOT/.mcp.json" storybook http "$PAYLOAD"
# Codex project config.
python3 "$SCRIPT_DIR/scripts/patch_codex_project_mcp.py" "$ROOT/.codex/config.toml" storybook "$PAYLOAD"

INFO="$(python3 - "$ROOT/package.json" <<'PY'
import json,sys
p=json.load(open(sys.argv[1])); d={}
for k in ('dependencies','devDependencies','peerDependencies'): d.update(p.get(k) or {})
print(d.get('@storybook/addon-mcp',''))
print(d.get('storybook',''))
PY
)"
ADDON="$(printf '%s\n' "$INFO" | sed -n '1p')"
SB="$(printf '%s\n' "$INFO" | sed -n '2p')"
if [[ -n "$ADDON" ]]; then echo "PASS: @storybook/addon-mcp declared ($ADDON)."; else
  echo 'WARN: @storybook/addon-mcp not detected. For Storybook 10.6+, install with:'
  echo '      npx storybook add @storybook/addon-mcp'
fi
[[ -n "$SB" ]] && echo "INFO: Storybook declared as $SB"
if grep -RqsE 'componentsManifest[[:space:]]*:[[:space:]]*true' "$ROOT/.storybook" 2>/dev/null; then
  echo 'PASS: Storybook componentsManifest appears enabled.'
else
  echo 'WARN: componentsManifest: true was not detected under .storybook/.'
  echo '      For Storybook MCP docs/component metadata, enable it in .storybook/main.*:'
  echo '      features: { componentsManifest: true }'
fi
cat <<EOF
PASS: project-local Storybook MCP configured for Claude (.mcp.json) and Codex (.codex/config.toml).
Endpoint: $URL

Claude Code may ask you to approve the project .mcp.json; use /mcp to inspect it.
Workspace/repository Storybook skills remain higher priority than package Working fallbacks.
EOF

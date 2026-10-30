#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${1:-$PWD}"
SERVER_DIR="${2:-${DEFOLD_MCP_DIR:-}}"
[[ -n "$SERVER_DIR" ]] || { echo 'Usage: setup-private-defold-community-mcp.sh [project] <built-defold-mcp-dir>' >&2; echo 'The directory must contain dist/index.js from Fulviuus/defold-mcp.' >&2; exit 2; }
PROJECT="$(cd "$PROJECT" && pwd)"
SERVER_DIR="$(cd "$SERVER_DIR" && pwd)"
ENTRY="$SERVER_DIR/dist/index.js"
[[ -f "$ENTRY" ]] || { echo "ERROR: $ENTRY not found. Build the reviewed checkout first with npm install && npm run build." >&2; exit 1; }
command -v node >/dev/null || { echo 'ERROR: node is required.' >&2; exit 1; }
PAYLOAD="$(python3 - "$ENTRY" "$PROJECT" <<'PY'
import json,sys
entry,project=sys.argv[1:]
print(json.dumps({'command':'node','args':[entry],'env':{'DEFOLD_PROJECT_PATH':project}},separators=(',',':')))
PY
)"
python3 "$ROOT_DIR/scripts/merge_project_mcp.py" "$PROJECT/.mcp.json" defold-mcp stdio "$PAYLOAD"
python3 "$ROOT_DIR/scripts/patch_codex_project_mcp.py" "$PROJECT/.codex/config.toml" defold-mcp "$PAYLOAD"
cat <<EOF
PASS: optional community Defold MCP configured project-locally.
Server checkout: $SERVER_DIR
Project:         $PROJECT

This server is third-party and is not audited by the Defold Foundation. Keep the checkout pinned/reviewed,
and prefer official Defold automation for core workflows when possible.
EOF

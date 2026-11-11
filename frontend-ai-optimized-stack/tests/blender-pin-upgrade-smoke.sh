#!/usr/bin/env bash
# The OMP configurator upgrades its own previous Blender pin in place and still refuses an unknown differing entry.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export HOME="$T/home" MM_UVX_PATH=/usr/bin/uvx MM_STACK_DATA_HOME="$T/data"
mkdir -p "$HOME/.omp/profiles/private/agent" "$HOME/.omp/profiles/working/agent" "$HOME/.local/bin"
MCP="$HOME/.omp/profiles/private/agent/mcp.json"
write() { # $1 = args JSON for the blender server
python3 - "$MCP" "$1" <<'PY'
import json, sys
env = {'BLENDER_HOST': '127.0.0.1', 'BLENDER_PORT': '9876', 'BLENDER_MCP_SAFE_MODE': '1', 'DISABLE_TELEMETRY': 'true'}
obj = {'keep': True, 'mcpServers': {'blender': {'command': '/usr/bin/uvx', 'args': json.loads(sys.argv[2]), 'env': env}}}
open(sys.argv[1], 'w').write(json.dumps(obj, indent=2) + '\n')
PY
}
# 1) previous pin: preflight must accept it (upgrade path), apply-time merge must not fail
write '["mcp-for-blender@2.2.0"]'
python3 "$ROOT/scripts/configure_yolo_omp.py" --preflight > "$T/out1" 2>&1 || { cat "$T/out1"; exit 1; }
grep -q 'PASS  preflight private' "$T/out1"
# 2) an unknown differing entry is still refused
write '["mcp-for-blender@9.9.9"]'
if python3 "$ROOT/scripts/configure_yolo_omp.py" --preflight > "$T/out2" 2>&1; then echo 'FAIL unknown blender pin was accepted'; exit 1; fi
grep -q 'will not overwrite your server' "$T/out2"
# 3) the generated defaults carry the current pin
grep -q "mcp-for-blender@2.2.7" "$ROOT/scripts/configure_yolo_omp.py" "$ROOT/payload/bin/codex-private" "$ROOT/setup-global-mcps.sh"
! grep -q "mcp-for-blender@2.2.0'\],\s*'env'" "$ROOT/scripts/configure_yolo_omp.py"
echo 'PASS blender pin upgrade: previous pin upgraded in place, unknown pin refused, defaults at 2.2.7'

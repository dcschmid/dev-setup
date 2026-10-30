#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export HOME="$T/home"
mkdir -p "$HOME/.codex"
cat > "$HOME/.claude.json" <<'JSON'
{"model":"keep","mcpServers":{"blender":{"command":"/usr/bin/uvx","args":["mcp-for-blender@2.2.0"],"env":{"BLENDER_MCP_SAFE_MODE":"1"}},"custom":{"command":"bash","args":["-lc","hello"]}}}
JSON
cat > "$HOME/.codex/config.toml" <<'TOML'
model = "keep"
[mcp_servers."custom"]
command = "bash"
args = ["-lc", "hello"]
[mcp_servers.blender]
command = "uvx"
args = ["mcp-for-blender@2.2.0"]
enabled = true
[mcp_servers.blender.env]
BLENDER_HOST = "127.0.0.1"
[features]
new_tools = true
TOML
cp "$HOME/.claude.json" "$T/original-claude"
cp "$HOME/.codex/config.toml" "$T/original-codex"
python3 "$ROOT/scripts/migrate_global_blender.py" --preflight >/dev/null
cmp -s "$HOME/.claude.json" "$T/original-claude"
cmp -s "$HOME/.codex/config.toml" "$T/original-codex"
python3 "$ROOT/scripts/migrate_global_blender.py" --apply > "$T/migration"
python3 "$ROOT/scripts/check_blender_scope.py" >/dev/null
python3 - <<'PY'
import json,tomllib
from pathlib import Path
h=Path.home()
c=json.loads((h/'.claude.json').read_text())
t=tomllib.loads((h/'.codex/config.toml').read_text())
assert c['model']=='keep' and 'blender' not in c['mcpServers'] and 'custom' in c['mcpServers']
assert t['model']=='keep' and t['features']['new_tools'] is True
assert 'blender' not in t['mcp_servers'] and 'custom' in t['mcp_servers']
PY
grep -q '^BACKUP global Blender configs:' "$T/migration"
find "$HOME/.frontend-ai-stack-backups" -name claude.json -type f | grep -q .
find "$HOME/.frontend-ai-stack-backups" -name codex-config.toml -type f | grep -q .
python3 "$ROOT/scripts/migrate_global_blender.py" --apply | grep -q 'no global Blender'
# Unrecognized entries must NEVER be touched, even when --apply is passed.
cat > "$HOME/.claude.json" <<'JSON'
{"mcpServers":{"blender":{"command":"bash","args":["custom-blender-server"]}}}
JSON
cp "$HOME/.claude.json" "$T/unknown-before"
if python3 "$ROOT/scripts/migrate_global_blender.py" --apply 2> "$T/rejected"; then
  echo 'FAIL unknown global Blender config was accepted' >&2; exit 1
fi
cmp -s "$HOME/.claude.json" "$T/unknown-before"
grep -q 'not a recognized' "$T/rejected"
# Corrupt JSON should likewise never be rewritten.
printf '{broken\n' > "$HOME/.claude.json"
cp "$HOME/.claude.json" "$T/corrupt-before"
if python3 "$ROOT/scripts/migrate_global_blender.py" --apply >/dev/null 2>&1; then
  echo 'FAIL corrupt config was accepted' >&2; exit 1
fi
cmp -s "$HOME/.claude.json" "$T/corrupt-before"
echo 'PASS known Blender MCP migration, backup, unrelated config preserved, unknown/corrupt configs rejected'

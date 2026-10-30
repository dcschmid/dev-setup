#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/repo/.storybook" "$TMP/repo/.codex" "$TMP/mockbin" "$TMP/defold/dist" "$TMP/home"
cat > "$TMP/repo/package.json" <<'JSON'
{"devDependencies":{"storybook":"^10.6.1","@storybook/addon-mcp":"^10.6.1"}}
JSON
cat > "$TMP/repo/.storybook/main.ts" <<'TS'
export default { features: { componentsManifest: true } };
TS
cat > "$TMP/repo/.mcp.json" <<'JSON'
{
  "mcpServers": {
    "unrelated": {"type":"stdio","command":"echo","args":["hello"]},
    "blender": {"type":"stdio","command":"old-blender","args":[]},
    "mcp-for-blender": {"type":"stdio","command":"old-mcp-for-blender","args":[]},
    "blender-ai-mcp": {"type":"stdio","command":"old-blender-ai-mcp","args":[]}
  }
}
JSON
cat > "$TMP/repo/.codex/config.toml" <<'TOML'
model = "keep-me"
[mcp_servers."unrelated"]
command = "echo"
args = ["hello"]
[mcp_servers."blender"]
command = "old-blender"
[mcp_servers."mcp-for-blender"]
command = "old-mcp-for-blender"
[mcp_servers."blender-ai-mcp"]
command = "old-blender-ai-mcp"
TOML

"$ROOT/setup-working-storybook-mcp.sh" "$TMP/repo" > "$TMP/story.out"
grep -q 'PASS: Storybook componentsManifest' "$TMP/story.out"
grep -q '"storybook"' "$TMP/repo/.mcp.json"
grep -q 'model = "keep-me"' "$TMP/repo/.codex/config.toml"
grep -q '^\[mcp_servers\."unrelated"\]$' "$TMP/repo/.codex/config.toml"
grep -q '^\[mcp_servers\."storybook"\]$' "$TMP/repo/.codex/config.toml"
"$ROOT/setup-working-storybook-mcp.sh" "$TMP/repo" >/dev/null
[[ $(grep -c '^\[mcp_servers\."storybook"\]$' "$TMP/repo/.codex/config.toml") -eq 1 ]]

cat > "$TMP/mockbin/uvx" <<'UVX'
#!/usr/bin/env bash
printf '%s|%s\n' "${BLENDERMCP_ADDONS_DIR:-}" "$*" >> "${UVX_LOG:?}"
exit 0
UVX
cat > "$TMP/mockbin/flatpak" <<'FLATPAK'
#!/usr/bin/env bash
if [[ "$1" == info && "${2:-}" == --show-version ]]; then
  echo '5.2.0'; exit 0
fi
if [[ "$1" == info && "${2:-}" == --show-permissions ]]; then
  printf '[Context]\nshared=network;ipc;\n'; exit 0
fi
if [[ "$1" == info ]]; then exit 0; fi
if [[ "$1" == run ]]; then echo 'Blender 5.2.0'; exit 0; fi
exit 1
FLATPAK
chmod +x "$TMP/mockbin/uvx" "$TMP/mockbin/flatpak"

HOME="$TMP/home" UVX_LOG="$TMP/uvx.log" PATH="$TMP/mockbin:$PATH" \
  "$ROOT/setup-private-gamedev-mcp.sh" "$TMP/repo" > "$TMP/blender.out"
EXPECTED="$TMP/home/.var/app/org.blender.Blender/config/blender/5.2/scripts/addons"
grep -Fq "$EXPECTED|--python 3.11 mcp-for-blender@2.2.0 install-addon" "$TMP/uvx.log"
[[ -d "$EXPECTED" ]]
# Existing project MCP configuration must stay intact; no implicit migration.
grep -q 'old-blender' "$TMP/repo/.mcp.json"
grep -q 'old-mcp-for-blender' "$TMP/repo/.mcp.json"
grep -q 'model = "keep-me"' "$TMP/repo/.codex/config.toml"
grep -q '^\[mcp_servers\."unrelated"\]$' "$TMP/repo/.codex/config.toml"

printf 'console.log("mock")\n' > "$TMP/defold/dist/index.js"
"$ROOT/setup-private-defold-community-mcp.sh" "$TMP/repo" "$TMP/defold" > "$TMP/defold.out"
grep -q '"defold-mcp"' "$TMP/repo/.mcp.json"
grep -q '^\[mcp_servers\."defold-mcp"\]$' "$TMP/repo/.codex/config.toml"
grep -q 'third-party' "$TMP/defold.out"

python3 - "$TMP/repo/.mcp.json" "$TMP/repo/.codex/config.toml" <<'PY'
import json,sys
from pathlib import Path
json.loads(Path(sys.argv[1]).read_text())
try:
    import tomllib
except ImportError:
    raise SystemExit(0)
tomllib.loads(Path(sys.argv[2]).read_text())
PY

echo 'PASS project MCP helpers keep project config, install private Blender 2.2.0 addon, preserve Defold/Storybook, valid JSON/TOML'

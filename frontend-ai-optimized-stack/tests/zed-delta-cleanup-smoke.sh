#!/usr/bin/env bash
set -euo pipefail
S="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export HOME="$T/home" PATH="$T/mockbin:/usr/bin:/bin"
mkdir -p "$HOME/.local/delta.app/bin" "$HOME/.local/bin" "$HOME/.local/share/applications" \
  "$HOME/.claude/plugins" "$HOME/.codex" "$HOME/.omp/profiles/private/agent" \
  "$HOME/.omp/profiles/working/agent" "$HOME/.config/zed" "$HOME/dev/test-project/.claude" "$T/mockbin"
cat > "$HOME/.local/delta.app/bin/delta" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$HOME/.local/delta.app/bin/delta"
ln -s "$HOME/.local/delta.app/bin/delta" "$HOME/.local/bin/delta"
printf '#!/bin/sh\nexit 0\n' > "$HOME/.local/bin/zed"; chmod +x "$HOME/.local/bin/zed"
cat > "$HOME/.local/share/applications/delta.desktop" <<EOF
[Desktop Entry]
Name=Delta
Exec=$HOME/.local/delta.app/bin/delta
EOF
cat > "$HOME/.claude.json" <<'EOF'
{"mcpServers":{"zed-delta":{"command":"/tmp/delta"},"tinysearch":{"command":"uvx"},"mcpdelta":{"command":"mcpdelta"}},"projects":{"/foo":{"mcpServers":{"delta":{"command":"/home/test/.local/delta.app/bin/delta"},"blender":{"command":"uvx"}}}}}
EOF
cat > "$HOME/.claude/settings.json" <<'EOF'
{"enabledPlugins":{"delta@zed-industries":true,"other-plugin@other":true}}
EOF
cat > "$HOME/.codex/config.toml" <<'EOF'
model = "gpt-6"
[mcp_servers.delta]
command = "delta"
[mcp_servers.delta.env]
ZED_DELTA = "1"
[mcp_servers.tinycontext]
command = "memory"
EOF
cat > "$HOME/.omp/profiles/private/agent/mcp.json" <<'EOF'
{"mcpServers":{"delta":{"command":"delta","args":["mcp"]},"blender":{"command":"uvx","args":["mcp-for-blender@2.2.0"]}}}
EOF
cat > "$HOME/.omp/profiles/working/agent/mcp.json" <<'EOF'
{"mcpServers":{"tinysearch":{"command":"uvx"}}}
EOF
cat > "$HOME/dev/test-project/.claude/settings.json" <<'EOF'
{"enabledPlugins":{"delta@zed-industries":true,"other@vendor":true}}
EOF
cat > "$HOME/.claude/plugins/installed_plugins.json" <<'EOF'
{"version":2,"plugins":{"delta@zed-industries":[{"scope":"user"}],"other-plugin@other":[{"scope":"user"}]}}
EOF
cat > "$T/mockbin/claude" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == 'plugin uninstall delta@zed-industries --scope user' ]]; then
  python3 - "$HOME/.claude/plugins/installed_plugins.json" <<'PY'
import json,sys
p=sys.argv[1];x=json.load(open(p));x['plugins'].pop('delta@zed-industries',None);open(p,'w').write(json.dumps(x))
PY
  exit 0
fi
exit 1
EOF
chmod +x "$T/mockbin/claude"
python3 "$S/scripts/cleanup_zed_delta.py" | grep -q 'FOUND'
if python3 "$S/scripts/cleanup_zed_delta.py" --check >/dev/null 2>&1; then echo 'unexpected no-Delta'; exit 1; fi
python3 "$S/scripts/cleanup_zed_delta.py" --apply --backup-dir "$HOME/.frontend-ai-stack-backups/test" > "$T/result"
python3 "$S/scripts/cleanup_zed_delta.py" --check
[[ ! -d "$HOME/.local/delta.app" && ! -e "$HOME/.local/bin/delta" && ! -L "$HOME/.local/bin/delta" ]]
[[ -x "$HOME/.local/bin/zed" ]]
[[ -d "$HOME/.frontend-ai-stack-backups/test/uninstalled-app/.local/delta.app" ]]
[[ ! -e "$HOME/.local/share/applications/delta.desktop" ]]
python3 - <<'PY'
import json,os
from pathlib import Path
h=Path.home()
c=json.loads((h/'.claude.json').read_text()); assert list(c['mcpServers'])==['tinysearch','mcpdelta']; assert 'blender' in c['projects']['/foo']['mcpServers']
c=json.loads((h/'.claude/settings.json').read_text());assert list(c['enabledPlugins']) == ['other-plugin@other']
c=json.loads((h/'dev/test-project/.claude/settings.json').read_text());assert list(c['enabledPlugins']) == ['other@vendor']
c=json.loads((h/'.omp/profiles/private/agent/mcp.json').read_text());assert list(c['mcpServers']) == ['blender']
s=(h/'.codex/config.toml').read_text();assert '[mcp_servers.delta]' not in s and '[mcp_servers.delta.env]' not in s and '[mcp_servers.tinycontext]' in s and 'gpt-6' in s
c=json.loads((h/'.claude/plugins/installed_plugins.json').read_text());assert 'delta@zed-industries' not in c['plugins']
PY
# Idempotency: no unintended changes once cleaned
python3 "$S/scripts/cleanup_zed_delta.py" --apply --backup-dir "$HOME/.frontend-ai-stack-backups/test" >/dev/null
# Unrelated mcpdelta explicitly stays.
[[ $(python3 - <<'PY'
import json;from pathlib import Path
print('mcpdelta' in json.loads((Path.home()/'.claude.json').read_text())['mcpServers'])
PY
) == True ]]
# Unknown delta name with unrelated command must survive.
printf '%s\n' '{"mcpServers":{"delta":{"command":"my-other-service"}}}' > "$HOME/.claude.json"
python3 "$S/scripts/cleanup_zed_delta.py" --apply --backup-dir "$HOME/.frontend-ai-stack-backups/test2" >/dev/null
grep -q 'my-other-service' "$HOME/.claude.json"
echo 'PASS Delta removal: vendor app/CLI, Claude plugin, Claude/Codex/OMP MCPs, project config, backups, no false positives'

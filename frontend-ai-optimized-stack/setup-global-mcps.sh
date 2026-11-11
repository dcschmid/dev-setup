#!/usr/bin/env bash
# Shared global user MCPs: TinySearch and TinyContext; Blender is PRIVATE-only.
# Existing, non-matching user entries are deliberately not overwritten.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UVX="$(command -v uvx || true)"
[[ -n "$UVX" ]] || { echo 'ERROR: uvx missing (Fedora: sudo dnf install uv).' >&2; exit 1; }
[[ -x "$HOME/.local/bin/mm-tinycontext-mcp" ]] || {
  echo 'ERROR: TinyContext launcher missing. Run ./install-profiles.sh first.' >&2; exit 1;
}
mode="${1:-}"
[[ "$mode" == '' || "$mode" == '--check' ]] || { echo 'Usage: ./setup-global-mcps.sh [--check]' >&2; exit 2; }
if [[ "$mode" != '--check' ]]; then
  python3 "$ROOT/scripts/migrate_global_blender.py" --apply || exit $?
fi
python3 "$ROOT/scripts/check_blender_scope.py" || { echo "ERROR: Blender still globally visible. See docs/GLOBAL_MCPS.md" >&2; exit 1; }
# Use absolute command path so GUI and non-interactive agent launches find uvx.
# The Blender package is deliberately pinned to the requested release.
SEARCH_ARGS=(--python 3.12 --from 'tinysuite-search[server]' tinysearch)

# Probe actual config files, not only `mcp get`: the latter can see project-local
# entries and would incorrectly treat them as a globally registered server.
entry_status() {
  python3 - "$1" "$2" "$3" "$UVX" "$HOME/.local/bin/mm-tinycontext-mcp" <<'PY'
import json, sys
from pathlib import Path
client, name, expected, uvx, memory_launcher = sys.argv[1:]
path = Path.home()/('.claude.json' if client == 'claude' else '.codex/config.toml')
try:
    if not path.exists(): raise FileNotFoundError
    if client == 'claude':
        obj=json.loads(path.read_text())
        servers=obj.get('mcpServers', {})
    else:
        import tomllib
        obj=tomllib.loads(path.read_text())
        servers=obj.get('mcp_servers', {})
    node=servers.get(name)
    if node is None:
        print('missing'); sys.exit()
    if not isinstance(node, dict): print('conflict'); sys.exit()
    if expected == 'tinysearch':
        args=['--python','3.12','--from','tinysuite-search[server]','tinysearch'];desired_env={}
    else:
        args=[]; desired_env={}
    good = (node.get('command') == (memory_launcher if expected=='memory' else uvx)
            and node.get('args',[]) == args
            and all(str(node.get('env',{}).get(k)) == v for k,v in desired_env.items()))
    print('match' if good else 'conflict')
except FileNotFoundError: print('missing')
except (ValueError, OSError) as ex:
    print('invalid')
PY
}
# Private Claude sessions load this overlay; Working sessions never do.
PRIVATE_MCP="${MM_STACK_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/frontend-ai-stack}/mcp/private-blender.json"
if [[ "$mode" != '--check' ]]; then
  mkdir -p "$(dirname "$PRIVATE_MCP")"
  python3 - "$PRIVATE_MCP" "$UVX" <<'BLENDER_JSON_PY'
import json,sys
from pathlib import Path
out={'mcpServers':{'blender':{'command':sys.argv[2],
 'args':['mcp-for-blender@2.2.7'],
 'env':{'BLENDER_HOST':'127.0.0.1','BLENDER_PORT':'9876','BLENDER_MCP_SAFE_MODE':'1','DISABLE_TELEMETRY':'true'}}}}
Path(sys.argv[1]).write_text(json.dumps(out,indent=2)+'\n')
BLENDER_JSON_PY
fi
python3 - "$PRIVATE_MCP" "$UVX" <<'VERIFY_JSON_PY'
import json,sys
from pathlib import Path
try: server=json.loads(Path(sys.argv[1]).read_text())['mcpServers']['blender']
except (OSError, ValueError, KeyError, TypeError): sys.exit('FAIL private Blender config missing')
assert server['command']==sys.argv[2] and server['args']==['mcp-for-blender@2.2.7']
assert server['env'].get('BLENDER_HOST')=='127.0.0.1' and server['env'].get('BLENDER_MCP_SAFE_MODE')=='1'
print('PASS Blender configured for private launcher only')
VERIFY_JSON_PY
result=0
register() {
  local client="$1" name="$2" kind="$3" status
  status="$(entry_status "$client" "$name" "$kind")"
  if [[ "$status" == match ]]; then
    echo "PASS  $client/$name registered globally"
    return
  fi
  if [[ "$status" == conflict || "$status" == invalid ]]; then
    echo "WARN  $client/$name: $status configuration; left untouched. See docs/GLOBAL_MCPS.md" >&2
    result=1; return
  fi
  if [[ "$mode" == '--check' ]]; then
    echo "FAIL  $client/$name global registration missing" >&2; result=1; return
  fi
  if [[ "$client" == claude ]]; then
    local args=(mcp add --scope user "$name")
    if [[ "$kind" == tinysearch ]]; then
      args+=(-- "$UVX" "${SEARCH_ARGS[@]}")
    else
      args+=(-- "$HOME/.local/bin/mm-tinycontext-mcp")
    fi
    # The real Claude CLI may require -e entries before --scope to delimit a variadic arg.
    if ! claude "${args[@]}"; then echo "FAIL  failed to add Claude $name" >&2; result=1; return; fi
  else
    local args=(mcp add "$name")
    if [[ "$kind" == tinysearch ]]; then
      args+=(-- "$UVX" "${SEARCH_ARGS[@]}")
    else
      args+=(-- "$HOME/.local/bin/mm-tinycontext-mcp")
    fi
    if ! codex "${args[@]}"; then echo "FAIL  failed to add Codex $name" >&2; result=1; return; fi
  fi
  status="$(entry_status "$client" "$name" "$kind")"
  if [[ "$status" == match ]]; then
    echo "PASS  $client/$name registered globally"
  else
    echo "WARN  $client/$name: CLI returned success but global config could not be verified ($status)." >&2
    result=1
  fi
}
any=0
for cli in claude codex; do
  if ! command -v "$cli" >/dev/null 2>&1; then
    echo "INFO  $cli not installed yet; re-run ./setup-global-mcps.sh after installing it"
    continue
  fi
  any=1
  register "$cli" tinysearch tinysearch
  # Kept under its established stack name: DO NOT create a duplicate second memory DB.
  register "$cli" mm-tinycontext memory
done
[[ "$any" -eq 1 ]] || echo 'INFO  Neither Claude nor Codex installed; skipped MCP registration.'
if [[ "$mode" != '--check' ]]; then
  cat <<'HELP'
INFO  Private-only Blender overlay does not install the Blender add-on. Install it once with:
      ./setup-private-gamedev-mcp.sh
INFO  Restart the CLI sessions. Check `claude mcp list` / `codex mcp list` and /mcp.
INFO  Existing project-local Blender MCP entries can reach Working; see docs/GLOBAL_MCPS.md.
HELP
fi
exit "$result"

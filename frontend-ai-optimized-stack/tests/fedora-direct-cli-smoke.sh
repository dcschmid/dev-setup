#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/home/.local/bin" "$T/mockbin" "$T/home/.codex" "$T/home/.claude" "$T/home/.codex-swap"
cat > "$T/mockbin/codex" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == '--version' ]]; then echo 'codex 0.166.0'; exit 0; fi
if [[ "${1:-}" == mcp && "${2:-}" == add ]]; then
  python3 - "$HOME/.codex/config.toml" "${3}" "${@:5}" <<'PYC'
import json,sys
from pathlib import Path
p=Path(sys.argv[1]);name=sys.argv[2];cmd=sys.argv[3];args=sys.argv[4:]
with p.open('a') as f:
 f.write(f'\n[mcp_servers."{name}"]\ncommand = {json.dumps(cmd)}\nargs = {json.dumps(args)}\n')
PYC
  exit 0
fi
echo "${CODEX_HOME:-DEFAULT}|$*" >> "$HOME/codex-called"
exit 0
EOF
cat > "$T/mockbin/claude" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == mcp && "${2:-}" == get ]]; then
 python3 - "${3:-}" <<'PYC'
import json,sys
from pathlib import Path
p=Path.home()/'.claude.json'
sys.exit(0 if p.exists() and sys.argv[1] in json.loads(p.read_text()).get('mcpServers',{}) else 1)
PYC
 exit $?
fi
if [[ "${1:-}" == mcp && "${2:-}" == add ]]; then
 python3 - "$@" <<'PYC'
import json,sys
from pathlib import Path
args=sys.argv[1:];i=args.index('--');name=next(a for a in args[2:i] if a not in ('--scope','user'));cmd=args[i+1]; argv=args[i+2:]
p=Path.home()/'.claude.json';o=json.loads(p.read_text()) if p.exists() else {}
o.setdefault('mcpServers',{})[name]={'command':cmd,'args':argv}
p.write_text(json.dumps(o))
PYC
 exit $?
fi
echo "$*" >> "$HOME/claude-called"
exit 0
EOF
cat > "$T/mockbin/cswap" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  list) if [[ "${2:-}" == '--json' ]]; then echo '{"accounts":[],"activeAccountNumber":null}'; fi;;
  auto) echo '{"event":"no-switch","reason":"all-exhausted"}'; exit 3;;
esac
exit 0
EOF
cat > "$T/mockbin/cxswap" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HOME/cxswap-called"
# CLI contract: --strategy is recognized only by switch, never by auto.
if [[ "${1:-}" == auto && " $* " == *' --strategy '* ]]; then echo 'unrecognized arguments: --strategy' >&2; exit 2; fi
case "${1:-}" in
 list) echo '1. codex-1  5h: 10%  1w: 22%'; echo '2. codex-2  5h: 12% 1w: 20%';;
 status) echo 'codex-1';;
 auto) echo '{"event":"no-switch","reason":"already-best"}'; exit 2;;
esac
EOF
cat > "$T/mockbin/codex-switch" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HOME/codex-switch-called"
printf '%s|%s|%s\n' "${CODEX_HOME:-DEFAULT}" "${MM_AGENT_PROFILE:-MISSING}" "$*" >> "$HOME/codex-switch-context"
case "${1:-}" in
  doctor) echo 'codex-switch doctor: PASS';;
  list) echo 'codex-1 codex-2';;
  --version) echo 'codex-switch 0.3.2';;
esac
exit 0
EOF
cat > "$T/mockbin/systemctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HOME/systemctl-called"
case "$*" in
  *' cat codex-swap-auto.service'*)
    [[ -f "$HOME/.config/systemd/user/codex-swap-auto.service" ]] && cat "$HOME/.config/systemd/user/codex-swap-auto.service"
    exit 0 ;;
  *'is-active'*'codex-swap-auto.service'*)
    [[ -f "$HOME/cxswap-service-active" ]] && exit 0 || exit 3 ;;
  *'disable --now codex-swap-auto.service'*)
    rm -f "$HOME/cxswap-service-active" ;;
esac
exit 0
EOF
cat > "$T/mockbin/uvx" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$TINYCONTEXT_MEMORY_DB_PATH" >> "$HOME/tiny-mock-dbs" 2>/dev/null || true
exit 0
EOF
for c in codex claude cswap cxswap codex-switch systemctl uvx; do chmod +x "$T/mockbin/$c"; done
printf 'AUTH_SENTINEL\n' > "$T/home/.codex/auth.json"
printf 'CLAUDE_SENTINEL\n' > "$T/home/.claude/.credentials.json"
printf 'CXSWAP_SENTINEL\n' > "$T/home/.codex-swap/store.json"
cat > "$T/mockbin/omp" <<'EOF'
#!/usr/bin/env bash
printf '%s|%s|%s|%s\n' "${MM_AGENT_PROFILE:-NONE}" "${OMP_PROFILE:-NONE}" "${MM_TINYCONTEXT_PROJECT_ROOT:-NONE}" "$*" >> "$HOME/omp-called"
exit 0
EOF
chmod +x "$T/mockbin/omp"
printf 'AUTH_SENTINEL\n' > "$T/home/.codex/auth.json"
printf 'CLAUDE_SENTINEL\n' > "$T/home/.claude/.credentials.json"
printf 'CXSWAP_SENTINEL\n' > "$T/home/.codex-swap/store.json"
printf 'LEGACY_ACTIVE\n' > "$T/home/cxswap-service-active"
mkdir -p "$T/home/.config/systemd/user"
printf '# Managed by Frontend AI Stack v3.12.0\n' > "$T/home/.config/systemd/user/codex-swap-auto.service"
cat > "$T/home/.codex/config.toml" <<'TOML'
model = "keep-me"
[mcp_servers."blender"]
command = "uvx"
args = ["mcp-for-blender@2.2.0"]
TOML
cat > "$T/home/.claude.json" <<'JSON'
{"keepSetting":true,"mcpServers":{"blender":{"command":"uvx","args":["mcp-for-blender@2.2.0"]},"external":{"command":"echo","args":["keep"]}}}
JSON
mkdir -p "$T/home/.codex/skills/user-owned"
printf 'CUSTOM\n' > "$T/home/.codex/skills/user-owned/SKILL.md"
export HOME="$T/home" XDG_CONFIG_HOME="$T/home/.config" PATH="$T/home/.local/bin:$T/mockbin:/usr/bin:/bin"
"$ROOT/install-profiles.sh" > "$T/install-output"
"$ROOT/verify-profiles.sh" > "$T/verify-output" || { cat "$T/verify-output"; exit 1; }
grep -q 'VERIFICATION_PASS v3.13.4' "$T/verify-output"
grep -q 'disable --now codex-swap-auto.service' "$HOME/systemctl-called"
[[ ! -f "$HOME/cxswap-service-active" ]]
[[ "$(cat "$HOME/.codex/auth.json")" == AUTH_SENTINEL ]]
[[ "$(cat "$HOME/.claude/.credentials.json")" == CLAUDE_SENTINEL ]]
[[ "$(cat "$HOME/.codex-swap/store.json")" == CXSWAP_SENTINEL ]]
[[ -f "$HOME/.codex/skills/user-owned/SKILL.md" ]]
[[ ! -d "$HOME/.local/share/frontend-ai-stack/skills/private/mm-blender-asset-pipeline" ]]
[[ ! -d "$HOME/.local/share/frontend-ai-stack/skills/private/mm-blender-defold-handoff" ]]
for profile in working private; do
  conf="$HOME/.omp/profiles/$profile/agent/config.yml"
  mcp="$HOME/.omp/profiles/$profile/agent/mcp.json"
  [[ -f "$conf" && -f "$mcp" ]]
  grep -q 'disabledProviders:' "$conf"
  grep -q 'mm-tinycontext' "$mcp"
  grep -q 'tinysearch' "$mcp"
done
python3 - "$HOME" <<'PYTH'
import json,sys
from pathlib import Path
h=Path(sys.argv[1]);w=json.loads((h/'.omp/profiles/working/agent/mcp.json').read_text());p=json.loads((h/'.omp/profiles/private/agent/mcp.json').read_text())
assert 'blender' not in w['mcpServers'] and 'blender' in w['disabledServers']
assert 'blender' in p['mcpServers'] and p['mcpServers']['blender']['args']==['mcp-for-blender@2.2.0']
assert w['mcpServers']['mm-tinycontext']==p['mcpServers']['mm-tinycontext']
assert w['mcpServers']['tinysearch']==p['mcpServers']['tinysearch']
PYTH
"$HOME/.local/bin/codex-private" --version
"$HOME/.local/bin/codex-working" --version
"$HOME/.local/bin/codex-working" login
"$HOME/.local/bin/yolo-private" --version
"$HOME/.local/bin/yolo-working" --version
"$HOME/.local/bin/omp-working" --version
"$HOME/.local/bin/omp-private" --version
[[ -L "$HOME/.omp/profiles/working/agent/skills/project-memory" ]]
[[ -L "$HOME/.omp/profiles/private/agent/skills/mm-gamedev-core" ]]
# OMP-only skill is present in both named OMP profiles, never in Claude/Codex.
for profile in working private; do
  [[ -L "$HOME/.omp/profiles/$profile/agent/skills/mm-omp-code-workflow" ]]
done
[[ ! -e "$HOME/.claude/skills/mm-omp-code-workflow" ]]
[[ ! -e "$HOME/.codex/skills/mm-omp-code-workflow" ]]
[[ ! -e "$HOME/.local/share/frontend-ai-stack/codex-working-home/skills/mm-omp-code-workflow" ]]
grep -q '^private|private|' "$HOME/omp-called"
grep -q '^working|working|' "$HOME/omp-called"
! grep -Eq 'codex-switch run|cxswap auto|cxswap switch' "$HOME/.local/bin/codex-private" "$HOME/.local/bin/codex-working"
! grep -q 'mcp_servers.blender' "$HOME/codex-called" || [[ "$(grep -c 'mcp_servers.blender' "$HOME/codex-called")" -eq 1 ]]
# Same project, separated TinyContext based on profile.
MM_AGENT_PROFILE=private "$HOME/.local/bin/mm-tinycontext-path" db > "$T/private-db"
MM_AGENT_PROFILE=working "$HOME/.local/bin/mm-tinycontext-path" db > "$T/working-db"
[[ "$(cat "$T/private-db")" != "$(cat "$T/working-db")" ]]
# No login credentials in stack backups (including the nested Codex Working home).
backup="$(cat "$HOME/.frontend-ai-stack-last-backup")"
! grep -Rql 'AUTH_SENTINEL\|CLAUDE_SENTINEL\|CXSWAP_SENTINEL' "$backup"
# Idempotent on rerun.
"$ROOT/setup-yolo-omp.sh" > /dev/null
"$ROOT/setup-yolo-omp.sh" --check > /dev/null
# Roll back managed settings without deleting the credentials.
"$ROOT/rollback-profiles.sh" > "$T/rollback-output"
[[ ! -e "$HOME/.omp/profiles/working/agent/skills/mm-omp-code-workflow" ]]
[[ ! -e "$HOME/.omp/profiles/private/agent/skills/mm-omp-code-workflow" ]]
[[ "$(cat "$HOME/.codex/auth.json")" == AUTH_SENTINEL ]]
[[ "$(cat "$HOME/.claude/.credentials.json")" == CLAUDE_SENTINEL ]]
[[ "$(cat "$HOME/.codex-swap/store.json")" == CXSWAP_SENTINEL ]]
echo 'PASS Fedora manual-Codex + YOLO/OMP profiles smoke'

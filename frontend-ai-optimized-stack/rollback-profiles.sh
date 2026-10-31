#!/usr/bin/env bash
set -euo pipefail
BACKUP="${1:-$(cat "$HOME/.frontend-ai-stack-last-backup" 2>/dev/null || true)}"
[[ -n "$BACKUP" && -d "$BACKUP/state" ]] || { echo 'Usage: rollback-profiles.sh <backup-directory>' >&2; exit 2; }
STACK_ROOT="${MM_STACK_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/frontend-ai-stack}"
restore(){
  local path="$1" key="$2"
  if [[ -e "$BACKUP/state/$key" || -L "$BACKUP/state/$key" ]]; then
    rm -rf -- "$path"; mkdir -p "$(dirname "$path")"; cp -a "$BACKUP/state/$key" "$path"
  elif [[ -e "$BACKUP/state/$key.__MISSING__" ]]; then rm -rf -- "$path";
  else echo "WARN missing backup entry: $key" >&2; fi
}
# Remove only managed links into the canonical stack skills. Preserve independent user entries.
for client in codex claude; do
  dir="$HOME/.$client/skills"
  manifest="$dir/.mm-managed-package-links-v392.json"
  if [[ -f "$manifest" ]]; then
    python3 - "$manifest" "$dir" "$STACK_ROOT/skills" <<'PY'
import json,sys
from pathlib import Path
try: obj=json.loads(Path(sys.argv[1]).read_text())
except Exception: obj={}
root=Path(sys.argv[3]).resolve()
for row in obj.get('links',[]):
    if not isinstance(row,dict):continue
    name=row.get('dir_name','')
    if not name or '/' in name or name in ('.','..'): continue
    p=Path(sys.argv[2])/name
    if p.is_symlink():
        try: p.resolve(strict=False).relative_to(root)
        except ValueError: continue
        p.unlink()
PY
  fi
done
# Restore profile-owned files and original managed symlink state only.
for profile in private working; do
  agent="$HOME/.omp/profiles/$profile/agent"
  manifest="$agent/.mm-yolo-skill-links.json"
  if [[ -f "$manifest" ]]; then
    python3 - "$manifest" "$agent/skills" "$STACK_ROOT/skills" <<'PYS'
import json,sys
from pathlib import Path
try: items=json.loads(Path(sys.argv[1]).read_text()).get('links', [])
except (ValueError, OSError): items=[]
for name in items:
    if not isinstance(name,str) or '/' in name or name in ('.','..'): continue
    p=Path(sys.argv[2])/name
    if p.is_symlink():
        try: p.resolve(strict=False).relative_to(Path(sys.argv[3]).resolve())
        except ValueError: continue
        p.unlink()
PYS
  fi
  for name in config.yml mcp.json .mm-yolo-skill-links.json .mm-omp-features.json; do
    restore "$agent/$name" "yolo/$profile/$name"
  done
  for name in .mm-managed-package-links-v392.json .mm-active-profile; do
    if [[ -e "$BACKUP/state/yolo/$profile/skills/$name" || -e "$BACKUP/state/yolo/$profile/skills/$name.__MISSING__" ]]; then
      restore "$agent/skills/$name" "yolo/$profile/skills/$name"
    fi
  done
  mkdir -p "$agent/skills"
  for old in "$BACKUP/yolo-links/$profile/"*; do
    [[ -L "$old" ]] || continue
    dst="$agent/skills/$(basename "$old")"
    [[ -e "$dst" || -L "$dst" ]] || cp -a "$old" "$dst"
  done
done
restore "$STACK_ROOT/skills" stack-skills
restore "$STACK_ROOT/mcp/private-blender.json" stack-private-blender
restore "$HOME/.codex/config.toml" codex-config
restore "$HOME/.claude.json" claude-config
if [[ -e "$BACKUP/state/stack-rules" || -e "$BACKUP/state/stack-rules.__MISSING__" ]]; then
  restore "$STACK_ROOT/rules" stack-rules
  restore "$STACK_ROOT/source-root" stack-source-root
  restore "$HOME/.codex/AGENTS.md" codex-rules
  restore "${MM_CODEX_WORKING_HOME:-$STACK_ROOT/codex-working-home}/config.toml" working-config
  restore "${MM_CODEX_WORKING_HOME:-$STACK_ROOT/codex-working-home}/AGENTS.md" working-rules
fi
for client in codex claude; do
  dir="$HOME/.$client/skills"; mkdir -p "$dir"
  for f in .mm-managed-package-links-v392.json .mm-managed-profile-links .mm-active-profile; do
    restore "$dir/$f" "metadata/$client/$f"
  done
  for l in "$BACKUP/links/$client"/*; do [[ -L "$l" ]] && { [[ -e "$dir/$(basename "$l")" || -L "$dir/$(basename "$l")" ]] || cp -a "$l" "$dir/"; } || true; done
done
WORK_SKILLS="${MM_CODEX_WORKING_HOME:-$STACK_ROOT/codex-working-home}/skills"
mkdir -p "$WORK_SKILLS"
if [[ -f "$WORK_SKILLS/.mm-managed-package-links-v392.json" ]]; then
  python3 - "$WORK_SKILLS/.mm-managed-package-links-v392.json" "$WORK_SKILLS" "$STACK_ROOT/skills" <<'PYS'
import json,sys
from pathlib import Path
try: links=json.loads(Path(sys.argv[1]).read_text()).get('links', [])
except (ValueError, OSError): links=[]
for entry in links:
    if not isinstance(entry,dict): continue
    name=entry.get('dir_name','')
    if '/' in name or name in ('', '.', '..'): continue
    dst=Path(sys.argv[2])/name
    if dst.is_symlink():
        try: dst.resolve(strict=False).relative_to(Path(sys.argv[3]).resolve())
        except ValueError: continue
        dst.unlink()
PYS
fi
for file in .mm-managed-package-links-v392.json .mm-managed-profile-links .mm-active-profile; do
  restore "$WORK_SKILLS/$file" "metadata/codex-working/$file"
done
for link in "$BACKUP/links/codex-working/"*; do
  [[ -L "$link" ]] || continue
  dst="$WORK_SKILLS/$(basename "$link")"
  [[ -e "$dst" || -L "$dst" ]] || cp -a "$link" "$dst"
done
for b in "$BACKUP/state/bin/"*; do
  [[ -e "$b" || -L "$b" ]] || continue
  name="$(basename "$b")"; name="${name%.__MISSING__}"
  restore "$HOME/.local/bin/$name" "bin/$name"
done
echo "PASS: v3.15.0 installer rollback restored from $BACKUP"
echo 'Note: this rollback does not restore Zed Delta or its plugin automatically (see docs/ZED_DELTA_REMOVAL.md), modify logins, remove OMP, or undo the optional ~/.zshrc PATH snippet.'

#!/usr/bin/env python3
"""Remove only confirmed v3.12.0-managed project Blender MCP overrides.

Other/custom Blender MCP entries remain untouched. Use --apply to make changes.
"""
import json
import re
import sys
from datetime import datetime
from pathlib import Path
import tomllib

if len(sys.argv) not in (2, 3) or (len(sys.argv)==3 and sys.argv[1]!='--apply'):
    raise SystemExit('Usage: python3 scripts/migrate_legacy_project_blender.py [--apply] PROJECT_DIR')
apply=len(sys.argv)==3
root=Path(sys.argv[-1]).expanduser().resolve()
if not root.is_dir():raise SystemExit(f'Not a directory: {root}')
STAMP=datetime.now().strftime('%Y%m%d-%H%M%S')
legacy=('mcp-for-blender==2.1.9', 'mcp-for-blender@2.1.9')
def is_legacy(node):
    return (isinstance(node,dict) and node.get('command') in ('uvx',str(Path.home()/'.local/bin/uvx'))
            and any(v in node.get('args',[]) for v in legacy)
            and node.get('env',{}).get('BLENDER_MCP_SAFE_MODE')=='1')
path=root/'.mcp.json'
if path.exists():
    obj=json.loads(path.read_text())
    servers=obj.get('mcpServers',{})
    to_remove=[k for k,v in servers.items() if k in ('blender','mcp-for-blender','blender-ai-mcp') and is_legacy(v)]
    if to_remove:
        print(f'{path}: legacy entries {to_remove} — '+('removing' if apply else 'dry-run'))
        if apply:
            path.with_name(path.name+'.backup-'+STAMP).write_bytes(path.read_bytes())
            for k in to_remove:del servers[k]
            path.write_text(json.dumps(obj, indent=2)+'\n')
path=root/'.codex/config.toml'
if path.exists():
    original=path.read_text()
    obj=tomllib.loads(original)
    servers=obj.get('mcp_servers',{})
    names=[k for k,v in servers.items() if k in ('blender','mcp-for-blender','blender-ai-mcp') and is_legacy(v)]
    if names:
        print(f'{path}: legacy entries {names} — '+('removing' if apply else 'dry-run'))
        if apply:
            path.with_name(path.name+'.backup-'+STAMP).write_bytes(path.read_bytes())
            lines=original.splitlines(keepends=True)
            out=[]; skip=False
            for line in lines:
                m=re.match(r'^\s*\[([^\]]+)\]', line)
                if m:
                    name=m.group(1)
                    skip=any(name.startswith(f'mcp_servers.{json.dumps(n)}') or name.startswith('mcp_servers.'+n) for n in names)
                if not skip: out.append(line)
            result=''.join(out)
            tomllib.loads(result)
            path.write_text(result)
print('PASS: other MCP entries and project files remain untouched.')

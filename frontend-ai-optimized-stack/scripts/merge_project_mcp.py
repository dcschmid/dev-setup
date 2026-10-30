#!/usr/bin/env python3
import json, sys
from pathlib import Path

if len(sys.argv) != 5:
    raise SystemExit('usage: merge_project_mcp.py FILE NAME TYPE PAYLOAD_JSON')
path=Path(sys.argv[1]); name=sys.argv[2]; typ=sys.argv[3]; payload=json.loads(sys.argv[4])
obj={}
if path.exists():
    try: obj=json.loads(path.read_text())
    except Exception as e: raise SystemExit(f'invalid {path}: {e}')
if not isinstance(obj, dict): raise SystemExit(f'{path}: top level must be an object')
servers=obj.setdefault('mcpServers', {})
if not isinstance(servers, dict): raise SystemExit(f'{path}: mcpServers must be an object')
payload['type']=typ
servers[name]=payload
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(obj, indent=2) + '\n')

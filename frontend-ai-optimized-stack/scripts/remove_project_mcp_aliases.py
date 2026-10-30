#!/usr/bin/env python3
import json, re, sys
from pathlib import Path

if len(sys.argv) < 4:
    raise SystemExit('usage: remove_project_mcp_aliases.py MCP_JSON CODEX_TOML NAME [NAME ...]')
json_path=Path(sys.argv[1]); toml_path=Path(sys.argv[2]); names=sys.argv[3:]

if json_path.exists():
    obj=json.loads(json_path.read_text())
    if isinstance(obj, dict):
        servers=obj.get('mcpServers')
        if isinstance(servers, dict):
            for name in names:
                servers.pop(name, None)
        json_path.write_text(json.dumps(obj, indent=2) + '\n')

if toml_path.exists():
    text=toml_path.read_text()
    for name in names:
        q=json.dumps(name)
        pat=re.compile(r'(?ms)^\[mcp_servers\.' + re.escape(q) + r'\]\n.*?(?=^\[(?!mcp_servers\.' + re.escape(q) + r'(?:\.|\]))|\Z)')
        text=pat.sub('', text).rstrip()+('\n' if text.strip() else '')
    toml_path.write_text(text)

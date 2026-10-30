#!/usr/bin/env python3
"""Fail if Blender MCP is registered globally: would leak into Working."""
import json, sys
from pathlib import Path
home=Path.home();issues=[]
try:
 data=json.loads((home/'.claude.json').read_text())
 if 'blender' in data.get('mcpServers',{}): issues.append('Claude ~/.claude.json: mcpServers.blender')
except FileNotFoundError: pass
except (OSError,ValueError): issues.append('Claude config cannot be read')
try:
 import tomllib
 data=tomllib.loads((home/'.codex/config.toml').read_text())
 if 'blender' in data.get('mcp_servers',{}): issues.append('Codex ~/.codex/config.toml: mcp_servers.blender')
except FileNotFoundError: pass
except (OSError,ValueError): issues.append('Codex config cannot be read')
if issues:
 for item in issues: print('FAIL globally visible Blender: '+item, file=sys.stderr)
 sys.exit(1)
print('PASS no global Blender MCP')

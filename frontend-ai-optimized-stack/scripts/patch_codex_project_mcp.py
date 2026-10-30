#!/usr/bin/env python3
import json, re, sys
from pathlib import Path

if len(sys.argv) != 4:
    raise SystemExit('usage: patch_codex_project_mcp.py FILE NAME PAYLOAD_JSON')
path=Path(sys.argv[1]); name=sys.argv[2]; data=json.loads(sys.argv[3])
text=path.read_text() if path.exists() else ''
# Remove only the exact managed server table and its child tables, leaving unrelated config untouched.
pat=re.compile(r'(?ms)^\[mcp_servers\.' + re.escape(json.dumps(name)) + r'\]\n.*?(?=^\[(?!mcp_servers\.' + re.escape(json.dumps(name)) + r'(?:\.|\]))|\Z)')
text=pat.sub('', text).rstrip()+('\n\n' if text.strip() else '')

def toml_string(s): return json.dumps(str(s), ensure_ascii=False)
def toml_array(xs): return '[' + ', '.join(toml_string(x) for x in xs) + ']'
def toml_inline(d): return '{ ' + ', '.join(f'{k} = {toml_string(v)}' for k,v in d.items()) + ' }'
lines=[f'[mcp_servers.{json.dumps(name)}]']
if 'command' in data: lines.append('command = ' + toml_string(data['command']))
if 'args' in data: lines.append('args = ' + toml_array(data['args']))
if 'url' in data: lines.append('url = ' + toml_string(data['url']))
if 'env' in data and data['env']: lines.append('env = ' + toml_inline(data['env']))
if 'startup_timeout_sec' in data: lines.append('startup_timeout_sec = ' + str(data['startup_timeout_sec']))
if 'tool_timeout_sec' in data: lines.append('tool_timeout_sec = ' + str(data['tool_timeout_sec']))
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(text + '\n'.join(lines) + '\n')

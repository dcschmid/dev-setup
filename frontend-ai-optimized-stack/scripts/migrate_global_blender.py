#!/usr/bin/env python3
"""Migrate ONLY a recognized global Blender 2.2.0 stdio MCP registration.

Claude and Codex user configs may also contain credentials / unrelated settings.
Never dump them, never modify unknown Blender configs and make on-disk backups
before changing a recognized entry. This script does NOT configure Private MCPs.
"""
from __future__ import annotations

import argparse
from datetime import datetime
import json
import os
from pathlib import Path
import re
import shutil
import stat
import sys
import tempfile
import tomllib

HEADER = re.compile(r'^\s*\[([^\]]+)\]\s*(?:#.*)?$')
MCP_BLENDER = re.compile(r'^mcp_servers\.(?:"blender"|blender)(?:\.|$)')
SUPPORTED_ARGS = (
    ['mcp-for-blender@2.2.0'],
    ['--python', '3.11', 'mcp-for-blender@2.2.0'],
)


def recognized(entry: object) -> bool:
    if not isinstance(entry, dict):
        return False
    executable = entry.get('command')
    args = entry.get('args')
    if not isinstance(executable, str) or Path(executable).name != 'uvx':
        return False
    if args not in SUPPORTED_ARGS:
        return False
    if entry.get('type', 'stdio') != 'stdio':
        return False
    if entry.get('env', {}) is not None and not isinstance(entry.get('env', {}), dict):
        return False
    return set(entry).issubset({'command', 'args', 'type', 'env', 'timeout', 'startup_timeout_sec', 'tool_timeout_sec', 'enabled'})


def clause_json(path: Path):
    if not path.exists():
        return None
    obj = json.loads(path.read_text(encoding='utf-8'))
    if not isinstance(obj, dict):
        raise ValueError(f'{path}: expected JSON object')
    servers = obj.get('mcpServers', {})
    if not isinstance(servers, dict):
        raise ValueError(f'{path}: unexpected mcpServers structure')
    if 'blender' not in servers:
        return None
    if not recognized(servers['blender']):
        raise ValueError(f'{path}: Blender server is not a recognized uvx mcp-for-blender@2.2.0 registration; leave unchanged and review manually')
    del servers['blender']
    return json.dumps(obj, indent=2, ensure_ascii=False) + '\n'


def codex_toml(path: Path):
    if not path.exists():
        return None
    content = path.read_text(encoding='utf-8')
    obj = tomllib.loads(content)
    servers = obj.get('mcp_servers', {})
    if not isinstance(servers, dict):
        raise ValueError(f'{path}: unexpected mcp_servers structure')
    if 'blender' not in servers:
        return None
    if not recognized(servers['blender']):
        raise ValueError(f'{path}: Blender server is not a recognized uvx mcp-for-blender@2.2.0 registration; leave unchanged and review manually')
    # Remove only dedicated [mcp_servers.blender] tables and their subsections.
    # An inline table or dynamically constructed config is deliberately rejected.
    output, dropping, found = [], False, False
    for line in content.splitlines(keepends=True):
        match = HEADER.match(line.rstrip('\r\n'))
        if match:
            dropping = bool(MCP_BLENDER.match(match.group(1).strip()))
            found |= dropping
        if not dropping:
            output.append(line)
    if not found:
        raise ValueError(f'{path}: Blender uses a nonstandard TOML representation; leave unchanged and review manually')
    result = ''.join(output)
    parsed = tomllib.loads(result)
    if 'blender' in parsed.get('mcp_servers', {}):
        raise ValueError(f'{path}: Blender registration still present after proposed edit; leave unchanged')
    return result


def atomic_replace(path: Path, contents: str):
    original_mode = stat.S_IMODE(path.stat().st_mode)
    fd, temp = tempfile.mkstemp(prefix='.frontend-ai-blender-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as out:
            out.write(contents)
            out.flush()
            os.fsync(out.fileno())
        os.chmod(temp, original_mode)
        os.replace(temp, path)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--preflight', action='store_true', help='check for safe migration, do not change files')
    mode.add_argument('--apply', action='store_true', help='backup and migrate recognized global Blender entries')
    args = parser.parse_args()
    home = Path.home()
    paths = [(home/'.claude.json', clause_json), (home/'.codex/config.toml', codex_toml)]
    updates = []
    try:
        for path, transform in paths:
            result = transform(path)
            if result is not None:
                updates.append((path, result))
    except (OSError, ValueError, TypeError) as exc:
        print(f'ERROR: global Blender migration not safe: {exc}', file=sys.stderr)
        print('TIP: Leave unrelated MCPs intact. Inspect `claude mcp get blender` and `codex mcp get blender`;', file=sys.stderr)
        print('     back up the relevant config and remove only the user-global Blender entry.', file=sys.stderr)
        return 2
    if not updates:
        print('PASS no global Blender entries to migrate')
        return 0
    if args.preflight:
        print('INFO recognized user-global Blender MCP(s): ' + ', '.join(str(p) for p, _ in updates))
        print('INFO these can be backed up and migrated by the installer')
        return 0
    stamp = datetime.now().strftime('%Y%m%d-%H%M%S')
    base = home/'.frontend-ai-stack-backups'/f'blender-global-migration-{stamp}-{os.getpid()}'
    base.mkdir(mode=0o700, parents=True, exist_ok=False)
    for path, _ in updates:
        dest = base/('claude.json' if path.name == '.claude.json' else 'codex-config.toml')
        shutil.copy2(path, dest)
        os.chmod(dest, 0o600)
    try:
        for path, output in updates:
            atomic_replace(path, output)
    except OSError as exc:
        print(f'ERROR: could not write global Blender migration: {exc}', file=sys.stderr)
        print(f'BACKUP: {base} (restore only after reviewing current files)', file=sys.stderr)
        return 2
    print(f'PASS removed recognized global Blender entry from {len(updates)} client config(s)')
    print(f'BACKUP global Blender configs: {base}')
    print('INFO private-only Blender is configured separately for claude-private / codex-private')
    return 0


if __name__ == '__main__':
    sys.exit(main())

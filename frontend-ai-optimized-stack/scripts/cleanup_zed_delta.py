#!/usr/bin/env python3
"""Targeted Zed Delta removal, NOT the unrelated mcpdelta product or Zed editor.

Defaults to read-only --scan. --apply backs up affected configs and moves only
verified Zed Delta Linux app artifacts to a recoverable backup directory.
Secrets never go to stdout/logs and all backups are private (0700).
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HOME = Path.home()
APP = HOME / '.local/delta.app'
PLUGIN = 'delta@zed-industries'
HEADER = re.compile(r'^\s*\[\[?([^\]]+)\]\]?\s*(?:#.*)?$', re.M)
IDENTIFIER = re.compile(r'(?i)(?:delta\.dev|zed-industries/delta(?:-claude)?|(?:^|/)delta\.app(?:/|$)|delta@zed-industries)')


def is_zed_mcp(name, node):
    n = name.lower()
    if n in {'zed-delta', 'zed_delta', 'delta-claude', 'delta-claude-code'}:
        return True
    if n not in {'delta', 'zed', 'delta-mcp'}:
        return False
    try:
        content = json.dumps(node, ensure_ascii=False)
    except (TypeError, ValueError):
        return False
    if IDENTIFIER.search(content):
        return True
    # The Zed Delta CLI, not generic npm package names such as 'mcpdelta'.
    if isinstance(node, dict):
        cmd = str(node.get('command', '')).strip()
        args = [str(x) for x in node.get('args', [])] if isinstance(node.get('args', []), list) else []
        if Path(cmd).name == 'delta' and (not args or args[0] in {'mcp', 'serve', 'server'}):
            return True
    return False


def strip_json_delta(node):
    """Remove only actual MCP server entries / exact plugin enablement; never arbitrary keys."""
    removed = []
    if not isinstance(node, dict):
        return removed
    for key in ('mcpServers', 'mcp_servers', 'context_servers'):
        servers = node.get(key)
        if isinstance(servers, dict):
            for name, entry in list(servers.items()):
                if is_zed_mcp(name, entry):
                    del servers[name]
                    removed.append(key + '.' + name)
    for key in ('enabledPlugins',):
        obj = node.get(key)
        if isinstance(obj, dict) and PLUGIN in obj:
            obj.pop(PLUGIN)
            removed.append(key + '.' + PLUGIN)
    # Claude config holds per-project MCP and plugin declarations.
    if isinstance(node.get('projects'), dict):
        for root, project in node['projects'].items():
            for item in strip_json_delta(project):
                removed.append(f'projects[{root}].{item}')
    return removed


def remove_toml_delta(content):
    """Keep unrelated TOML bytes; remove confirmed Delta MCP tables and subtables."""
    matches = list(HEADER.finditer(content))
    entries = []
    for i, m in enumerate(matches):
        heading = m.group(1).strip()
        mm = re.match(r'^mcp_servers\.(?:"([^"]+)"|\'([^\']+)\'|([^.]+))(?:\..*)?$', heading)
        if not mm:
            continue
        name = next(g for g in mm.groups() if g is not None)
        start = m.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(content)
        entries.append((start, end, heading, name, content[start:end]))
    known = set()
    for start, end, heading, name, section in entries:
        if heading.count('.') != 1:
            continue
        if is_zed_mcp(name, {'raw': section}) or (name.lower() == 'delta' and re.search(r'(?m)^\s*command\s*=\s*["\'](?:[^"\']*/)?delta["\']\s*$', section)):
            known.add(name)
    cuts = [(start, end, heading) for start, end, heading, name, section in entries if name in known]
    for start, end, _ in reversed(cuts):
        content = content[:start] + content[end:]
    return content, [c[2] for c in cuts]


def paths():
    base = [HOME / '.claude.json', HOME / '.claude/settings.json',
            HOME / '.claude/settings.local.json', HOME / '.codex/config.toml',
            HOME / '.omp/agent/mcp.json', HOME / '.omp/agent/settings.json']
    data_home = Path(os.environ.get('XDG_DATA_HOME', str(HOME / '.local/share')))
    stack = Path(os.environ.get('MM_STACK_DATA_HOME', str(data_home / 'frontend-ai-stack')))
    base.append(stack / 'codex-working-home/config.toml')
    for p in ('working', 'private'):
        base.append(HOME / f'.omp/profiles/{p}/agent/mcp.json')
        base.append(HOME / f'.omp/profiles/{p}/agent/settings.json')
    extra = [HOME / 'dev']
    if os.environ.get('MM_DELTA_PROJECT_ROOTS'):
        extra = [Path(item).expanduser() for item in os.environ['MM_DELTA_PROJECT_ROOTS'].split(':') if item]
    ignore = {'node_modules', '.git', '.venv', 'venv', 'dist', 'build', '.next', '.astro', '.cache', 'target', 'vendor'}
    for root in extra:
        if not root.is_dir():
            continue
        for current, dirs, files in os.walk(root, followlinks=False):
            current_p = Path(current)
            depth = len(current_p.relative_to(root).parts)
            dirs[:] = [d for d in dirs if d not in ignore and (depth < 7 or d in {'.claude', '.codex'})]
            for fname in files:
                if fname == '.mcp.json' or (current_p.name == '.claude' and fname in {'settings.json', 'settings.local.json'}) or (current_p.name == '.codex' and fname == 'config.toml'):
                    base.append(current_p / fname)
    return sorted(set(p for p in base if p.is_file() and not p.is_symlink()))


def backup_one(path, backup):
    try:
        rel = path.relative_to(HOME)
    except ValueError:
        rel = Path('external') / path.as_posix().lstrip('/')
    target = backup / 'config' / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        return
    shutil.copy2(path, target)


def update_one(path, result, backup):
    backup_one(path, backup)
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix='.mm-delta-', text=True)
    try:
        os.chmod(fd, path.stat().st_mode & 0o777)
        with os.fdopen(fd, 'w') as fout:
            fout.write(result)
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


def app_artifacts():
    # Only the official user's Delta app path, not a Zed editor or rpm package.
    found = []
    if APP.is_dir() and not APP.is_symlink():
        if (APP / 'bin/delta').exists() or (APP / 'Delta').exists() or any(APP.glob('*delta*')):
            found.append(APP)
    cli = HOME / '.local/bin/delta'
    if cli.is_symlink():
        target = cli.resolve(strict=False)
        if target == APP or APP in target.parents:
            found.append(cli)
    for dir_ in (HOME / '.local/share/applications', HOME / '.config/autostart'):
        if not dir_.is_dir():
            continue
        for p in dir_.glob('*.desktop'):
            if p.is_symlink() or not p.is_file():
                continue
            if p.stat().st_size > 50000:
                continue
            content = p.read_text(errors='replace')
            if 'delta.app' in content and ('zed' in content.lower() or 'delta' in p.name.lower() or 'Delta' in content):
                found.append(p)
    return found


def installed_plugin():
    path = HOME / '.claude/plugins/installed_plugins.json'
    if not path.is_file():
        return False
    try:
        data = json.loads(path.read_text())
    except (ValueError, OSError):
        return False
    def match(x):
        if isinstance(x, dict):
            return any(k == PLUGIN or (k in ('pluginId', 'id') and v == PLUGIN) or match(v) for k, v in x.items())
        if isinstance(x, list):
            return any(match(i) for i in x)
        return False
    return match(data)


def plugin_uninstall(backup):
    if not installed_plugin():
        return True
    claude = shutil.which('claude')
    if not claude:
        print('WARN  Claude Delta plugin still installed: Claude CLI missing. Run `claude plugin uninstall delta@zed-industries --scope user` manually.')
        return False
    meta = HOME / '.claude/plugins/installed_plugins.json'
    backup_one(meta, backup)
    for scope in ('user', 'local', 'project'):
        # User scope is default; other scopes require cwd project context and are
        # handled by scanning exact config declarations instead of blanket CLI calls.
        if scope != 'user':
            continue
        cmd = [claude, 'plugin', 'uninstall', PLUGIN, '--scope', scope]
        try:
            res = subprocess.run(cmd, cwd=str(HOME), stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30, check=False)
            if res.returncode:
                print('WARN  Claude plugin uninstall failed; exact plugin settings disabled, retry manually.')
                return False
            print('PASS  Claude Code Delta plugin uninstalled using official CLI')
        except (OSError, subprocess.TimeoutExpired):
            print('WARN  Claude plugin uninstall unavailable; retry manually.')
            return False
    return True


def scan_changes():
    all_ = []
    for p in paths():
        if p.suffix == '.toml':
            raw = p.read_text(errors='replace')
            new, removed = remove_toml_delta(raw)
        else:
            try:
                obj = json.loads(p.read_text())
                removed = strip_json_delta(obj)
                new = json.dumps(obj, ensure_ascii=False, indent=2) + '\n' if removed else ''
            except (ValueError, OSError):
                continue
        if removed:
            all_.append((p, new, removed))
    return all_


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--apply', action='store_true')
    mode.add_argument('--check', action='store_true')
    parser.add_argument('--backup-dir', type=Path)
    args = parser.parse_args()
    changed = scan_changes()
    app = app_artifacts()
    plugin = installed_plugin()
    if not (changed or app or plugin):
        print('PASS  No managed Zed Delta app, official plugin or known MCP registration detected')
        return 0
    for p, _, names in changed:
        print(f'{"INFO" if args.apply else "FOUND"} Delta references: {p} ({", ".join(names)})')
    for p in app:
        print(f'{"INFO" if args.apply else "FOUND"} Official Zed Delta app artifact: {p}')
    if plugin:
        print('FOUND Claude plugin delta@zed-industries')
    if args.check:
        return 1
    if not args.apply:
        print('INFO  Read-only scan; run --apply to uninstall identified Zed Delta items.')
        return 0
    if args.backup_dir is None:
        print('ERROR  --apply requires --backup-dir (must be under HOME)', file=sys.stderr)
        return 2
    backup = args.backup_dir.expanduser().resolve()
    if backup == HOME or not backup.is_relative_to(HOME):
        print('ERROR  backup must be within HOME and not HOME itself', file=sys.stderr)
        return 2
    backup.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(backup, 0o700)
    # Uninstall plugin before editing settings; the vendor CLI may itself edit settings.
    success = plugin_uninstall(backup)
    # Re-scan: CLI uninstall may have already edited the files.
    for p, new, removed in scan_changes():
        update_one(p, new, backup)
        print(f'PASS  Removed {len(removed)} Delta MCP/plugin config entries: {p}')
    for p in app:
        if not (p.exists() or p.is_symlink()):
            continue
        rel = p.relative_to(HOME)
        target = backup / 'uninstalled-app' / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists() or target.is_symlink():
            print(f'WARN  Target exists in backup; did not remove: {p}')
            success = False
            continue
        try:
            p.rename(target)
            print(f'PASS  Moved official Delta app artifact to recoverable backup: {p}')
        except OSError as err:
            print(f'WARN  Could not remove {p}: {err}')
            success = False
    print('INFO  No Zed editor, mcpdelta product, or unrelated MCPs were changed.')
    print('INFO  Backups/moved app files: ' + str(backup))
    if not success:
        print('WARN  Delta cleanup incomplete; see warnings above')
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""Idempotent Zed config overlay and guarded rollback, stdlib only."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import sys
import tempfile
from datetime import datetime

ROOT = Path(__file__).resolve().parent.parent


def jsonc_to_json(content: str) -> str:
    """Remove JSONC comments and trailing commas without modifying strings."""
    result = []
    index = 0
    in_str = False
    escaped = False
    while index < len(content):
        c = content[index]
        nxt = content[index + 1] if index + 1 < len(content) else ''
        if in_str:
            result.append(c)
            if escaped:
                escaped = False
            elif c == '\\':
                escaped = True
            elif c == '"':
                in_str = False
            index += 1
        elif c == '"':
            in_str = True
            result.append(c)
            index += 1
        elif c == '/' and nxt == '/':
            index += 2
            while index < len(content) and content[index] not in '\n\r':
                index += 1
        elif c == '/' and nxt == '*':
            end = content.find('*/', index + 2)
            if end < 0:
                raise ValueError('unterminated block comment')
            result.extend('\n' for _ in range(content[index:end + 2].count('\n')))
            index = end + 2
        else:
            result.append(c)
            index += 1
    no_comments = ''.join(result)
    out = []
    in_str = escaped = False
    for pos, c in enumerate(no_comments):
        if in_str:
            out.append(c)
            if escaped:
                escaped = False
            elif c == '\\':
                escaped = True
            elif c == '"':
                in_str = False
        elif c == '"':
            in_str = True
            out.append(c)
        elif c == ',':
            j = pos + 1
            while j < len(no_comments) and no_comments[j].isspace():
                j += 1
            if j == len(no_comments) or no_comments[j] not in '}]':
                out.append(c)
        else:
            out.append(c)
    return ''.join(out)


def load_jsonc(path: Path, default):
    if not path.exists():
        return default
    if path.is_symlink():
        raise ValueError(f'{path} is a symlink; edit it manually to avoid touching dotfiles-managed configurations')
    try:
        data = json.loads(jsonc_to_json(path.read_text(encoding='utf-8')))
    except (OSError, json.JSONDecodeError, ValueError) as err:
        raise ValueError(f'Could not parse {path}: {err}') from err
    if not isinstance(data, type(default)):
        raise ValueError(f'{path} must contain {type(default).__name__}')
    return data


def deep_merge(existing: dict, new: dict) -> dict:
    merged = dict(existing)
    for k, v in new.items():
        if isinstance(v, dict) and isinstance(merged.get(k), dict):
            merged[k] = deep_merge(merged[k], v)
        elif k == 'file_scan_exclusions' and isinstance(v, list) and isinstance(merged.get(k), list):
            merged[k] = list(dict.fromkeys([*merged[k], *v]))
        else:
            merged[k] = v
    return merged


def merge_tasks(existing: list, offered: list) -> list:
    new_labels = {entry['label'] for entry in offered}
    # Keep user-defined tasks in order; replace only the names owned by this kit.
    base = [task for task in existing if not isinstance(task, dict) or task.get('label') not in new_labels]
    return base + offered


def dump_json(data) -> bytes:
    return (json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode('utf-8')


def hash_bytes(blob: bytes) -> str:
    return hashlib.sha256(blob).hexdigest()


def atomic_write(target: Path, content: bytes, mode: int):
    target.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix=f'.{target.name}.', dir=target.parent)
    try:
        with os.fdopen(fd, 'wb') as f:
            f.write(content)
            f.flush()
            os.fsync(f.fileno())
        os.chmod(name, mode)
        os.replace(name, target)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def planned_targets(config_dir: Path, bin_dir: Path):
    old_settings = load_jsonc(config_dir / 'settings.json', {})
    old_tasks = load_jsonc(config_dir / 'tasks.json', [])
    new_settings = load_jsonc(ROOT / 'config/settings.json', {})
    new_tasks = load_jsonc(ROOT / 'config/tasks.json', [])
    for item in new_tasks:
        if not isinstance(item, dict) or not isinstance(item.get('label'), str):
            raise ValueError('invalid supplied tasks.json template')
    return [
        (config_dir / 'settings.json', dump_json(deep_merge(old_settings, new_settings)), 0o600),
        (config_dir / 'tasks.json', dump_json(merge_tasks(old_tasks, new_tasks)), 0o600),
        (bin_dir / 'zed-dev', (ROOT / 'scripts/zed-dev').read_bytes(), 0o755),
    ]


def install(args):
    config_dir, bin_dir, backup_base = args.config_dir, args.bin_dir, args.backup_dir
    targets = planned_targets(config_dir, bin_dir)
    changes = []
    for path, content, mode in targets:
        if path.is_symlink():
            raise ValueError(f'Refusing to update symlink: {path}')
        original = path.read_bytes() if path.exists() else None
        if original != content:
            changes.append((path, content, mode, original))
    if not changes:
        print('Already up to date. No files changed and no new backup needed.')
        return
    for path, _content, _mode, original in changes:
        print(f'{"UPDATE" if original is not None else "CREATE"}: {path}')
    if args.dry_run:
        print('Dry run: nothing written.')
        return
    if os.geteuid() == 0 and os.environ.get('ALLOW_ZED_DEVKIT_ROOT') != '1':
        raise ValueError('Do not run this user-profile installer as root/sudo')
    backup_base.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(backup_base, 0o700)  # pre-existing backup folders may be too permissive
    backup_dir = backup_base / f'{datetime.now():%Y%m%d-%H%M%S}-{os.getpid()}'
    backup_dir.mkdir(mode=0o700)
    manifest = {'version': '1.0.0', 'created': datetime.now().isoformat(), 'targets': []}
    for idx, (path, content, mode, original) in enumerate(changes):
        if original is not None:
            backup_name = f'original-{idx}'
            shutil.copy2(path, backup_dir / backup_name)
            os.chmod(backup_dir / backup_name, 0o600)
        else:
            backup_name = None
        entry = {
            'path': str(path.resolve(strict=False)),
            'backup_name': backup_name,
            'installed_sha256': hash_bytes(content),
            'original_mode': stat.S_IMODE(path.stat().st_mode) if original is not None else None,
        }
        manifest['targets'].append(entry)
    # Write manifest before writing destination files, so interrupted installs
    # still have a recovery manifest with recorded original states.
    atomic_write(backup_dir / 'manifest.json', dump_json(manifest), 0o600)
    try:
        for path, content, mode, original in changes:
            old_mode = stat.S_IMODE(path.stat().st_mode) if original is not None else mode
            atomic_write(path, content, old_mode)
    except Exception:
        print(f'ERROR: incomplete install; recovery data at {backup_dir}', file=sys.stderr)
        raise
    print(f'Backup: {backup_dir}')
    print('Extensions will be auto-installed by Zed on startup (requires network).')
    print('Claude, Codex, OMP, MCP, Kitty and git settings were not modified.')


def restore(args):
    root = args.backup_dir
    candidates = sorted([p for p in root.glob('*/manifest.json') if p.is_file()])
    if not candidates:
        raise ValueError(f'No backup manifests found under {root}')
    manifest_file = candidates[-1]
    manifest = json.loads(manifest_file.read_text(encoding='utf-8'))
    print(f'Restore from {manifest_file.parent}')
    entries = manifest['targets']
    # Refuse if anything changed since install, unless the user explicitly forces.
    for item in entries:
        target = Path(item['path'])
        if target.is_symlink():
            raise ValueError(f'Refusing to restore symlink: {target}')
        if not args.force:
            if not target.exists() or hash_bytes(target.read_bytes()) != item['installed_sha256']:
                raise ValueError(f'{target} changed after install. Re-run restore with --force after reviewing changes.')
        print(f'{"RESTORE" if item["backup_name"] is not None else "DELETE"}: {target}')
    if args.dry_run:
        print('Dry run: nothing written.')
        return
    for item in entries:
        target = Path(item['path'])
        backup_name = item['backup_name']
        if backup_name is None:
            if target.exists():
                target.unlink()
        else:
            original = (manifest_file.parent / backup_name).read_bytes()
            atomic_write(target, original, item['original_mode'])
    print('Restore completed. Reopen Zed to pick up previous configuration.')


def main():
    p = argparse.ArgumentParser(description='Zed Framework Devkit configuration manager')
    p.add_argument('--dry-run', action='store_true')
    p.add_argument('--restore-latest', action='store_true')
    p.add_argument('--force', action='store_true', help='permit restore even after manual edits')
    p.add_argument('--config-dir', type=Path, default=Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'zed')
    p.add_argument('--bin-dir', type=Path, default=Path.home() / '.local' / 'bin')
    p.add_argument('--backup-dir', type=Path, default=Path.home() / '.local' / 'share' / 'zed-devkit' / 'backups')
    args = p.parse_args()
    try:
        if args.restore_latest: restore(args)
        else: install(args)
    except (ValueError, OSError) as err:
        print(f'Error: {err}', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()

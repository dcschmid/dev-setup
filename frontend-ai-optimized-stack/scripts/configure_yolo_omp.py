#!/usr/bin/env python3
"""Non-destructive setup for two named OMP profiles, no API keys or network."""
import argparse
import json
import os
import sys
from pathlib import Path

MODEL = 'yolo-auto/qwen3.8-27b'
SAFE_CONFIG = f'''# Managed baseline: keep work/private MCP + skills isolated.
# OMP otherwise imports Claude/Codex user and project capabilities.
disabledProviders:
  - claude
  - codex
  - gemini
  - opencode
modelRoles:
  default: {MODEL}
'''


def fail(message):
    print('FAIL ' + message, file=sys.stderr)
    raise SystemExit(1)


def run(check, preflight=False):
    home = Path.home()
    data = Path(os.environ.get('MM_STACK_DATA_HOME', os.environ.get('XDG_DATA_HOME', str(home / '.local/share')) + '/frontend-ai-stack'))
    skills_root = data / 'skills'
    uvx = os.environ.get('MM_UVX_PATH')
    if not uvx:
        import shutil
        uvx = shutil.which('uvx')
    if not uvx:
        fail('uvx not found; install uv before OMP profile setup')
    memory = home / '.local/bin/mm-tinycontext-mcp'
    if not preflight and not memory.is_file():
        fail('mm-tinycontext-mcp missing; run install-profiles.sh first')
    for profile in ('working', 'private'):
        agent = home / '.omp/profiles' / profile / 'agent'
        config = agent / 'config.yml'
        mcp = agent / 'mcp.json'
        skill_dir = agent / 'skills'
        manifest = agent / '.mm-yolo-skill-links.json'
        # No parsing/rewriting arbitrary user YAML; if existing, require a safe policy.
        if config.exists():
            c = config.read_text()
            if 'disabledProviders:' not in c or not all('- ' + n in c for n in ('claude', 'codex', 'gemini', 'opencode')):
                fail(f'{config}: existing config does not prove external-agent discovery isolation; update manually (see docs/YOLO_OMP.md)')
            if MODEL not in c:
                print(f'WARN {config}: Yolo model not selected; use /model after login')
        elif check:
            fail(f'{config} missing')
        elif not preflight:
            agent.mkdir(parents=True, exist_ok=True)
            config.write_text(SAFE_CONFIG)
            config.chmod(0o600)
        desired = {
            'tinysearch': {'command': uvx, 'args': ['--python', '3.12', '--from', 'tinysuite-search[server]', 'tinysearch']},
            'mm-tinycontext': {'command': str(memory), 'args': []},
        }
        if profile == 'private':
            desired['blender'] = {'command': uvx, 'args': ['mcp-for-blender@2.2.0'], 'env': {
                'BLENDER_HOST': '127.0.0.1', 'BLENDER_PORT': '9876', 'BLENDER_MCP_SAFE_MODE': '1', 'DISABLE_TELEMETRY': 'true'}}
        if mcp.exists():
            try:
                old = json.loads(mcp.read_text())
            except (OSError, ValueError) as err:
                fail(f'{mcp}: invalid existing JSON ({err})')
            if not isinstance(old, dict) or not isinstance(old.get('mcpServers', {}), dict):
                fail(f'{mcp}: unexpected structure')
        else:
            old = {'mcpServers': {}}
        new = json.loads(json.dumps(old))
        for name, node in desired.items():
            existing = new['mcpServers'].get(name)
            if existing is not None and existing != node:
                fail(f'{mcp}: existing {name} differs; will not overwrite your server')
            new['mcpServers'][name] = node
        if profile == 'working':
            # Highest-precedence OMP MCP denylist blocks even inherited project/global Blender.
            deny = new.setdefault('disabledServers', [])
            if not isinstance(deny, list):
                fail(f'{mcp}: disabledServers must be list')
            if 'blender' not in deny:
                deny.append('blender')
            # Even if a user manually added Blender here, fail instead of hiding a surprise.
            if 'blender' in new['mcpServers']:
                fail(f'{mcp}: Working profile contains Blender; inspect/remove manually')
        elif 'blender' in new.get('disabledServers', []):
            fail(f'{mcp}: private Blender is disabled by an existing policy')
        if check:
            if new != old:
                fail(f'{mcp}: profile registrations incomplete; rerun ./setup-yolo-omp.sh')
        elif not preflight:
            if new != old:
                mcp.write_text(json.dumps(new, indent=2) + '\n')
                mcp.chmod(0o600)
        if preflight:
            print(f'PASS  preflight {profile}: safe to configure')
            continue
        expected = {}
        for group in ('shared', profile, 'omp'):
            g = skills_root / group
            if not g.is_dir():
                fail(f'Missing package skill group {g}')
            for path in sorted(g.iterdir()):
                if path.is_dir() and (path / 'SKILL.md').is_file():
                    expected[path.name] = path
        # Clean up only previously managed links, including retired Blender skills.
        prior = []
        if manifest.exists():
            try:
                prior = json.loads(manifest.read_text()).get('links', [])
            except (ValueError, TypeError):
                fail(f'{manifest}: malformed managed link manifest')
        if not check:
            skill_dir.mkdir(parents=True, exist_ok=True)
            for item in prior:
                p = skill_dir / item
                if p.is_symlink():
                    try:
                        p.resolve(strict=False).relative_to(skills_root.resolve())
                    except ValueError:
                        continue
                    p.unlink()
        installed = []
        for name, src in expected.items():
            dst = skill_dir / name
            if dst.exists() or dst.is_symlink():
                if dst.is_symlink() and dst.resolve(strict=False) == src.resolve():
                    installed.append(name)
                    continue
                print(f'INFO  User skill takes precedence; not replacing {dst}')
                continue
            if check:
                fail(f'Missing managed skill {dst}')
            dst.symlink_to(src)
            installed.append(name)
        if not check:
            manifest.write_text(json.dumps({'links': installed, 'profile': profile}, indent=2) + '\n')
        print(f'PASS  {profile}: native OMP profile, TinySearch/TinyContext, skills; Blender={profile == "private"}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--preflight', action='store_true')
    opts = parser.parse_args()
    if opts.check and opts.preflight:
        parser.error("--check and --preflight are mutually exclusive")
    run(opts.check, opts.preflight)

#!/usr/bin/env python3
"""Configure OMP workflow overlays without overwriting unrelated YAML or credentials.

The managed block is complete YAML and updates idempotently. Any top-level keys
that would collide with a user-owned part of the config cause a hard failure.
"""
import argparse
import copy
import json
import os
import re
import sys
from pathlib import Path
import tempfile

try:
    import yaml
except ImportError:
    raise SystemExit('FAIL PyYAML is required (Fedora: python3-pyyaml)')


class ConfigLoader(yaml.SafeLoader):
    """Match Bun's YAML 1.2 booleans; reject duplicate mapping keys."""
    yaml_implicit_resolvers = copy.deepcopy(yaml.SafeLoader.yaml_implicit_resolvers)


for initial, resolvers in ConfigLoader.yaml_implicit_resolvers.items():
    ConfigLoader.yaml_implicit_resolvers[initial] = [
        item for item in resolvers if item[0] != 'tag:yaml.org,2002:bool'
    ]
ConfigLoader.add_implicit_resolver('tag:yaml.org,2002:bool', re.compile(r'^(?:true|false)$', re.I), list('tTfF'))


def unique_mapping(loader, node):
    result = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node)
        if key in result:
            raise ValueError('duplicate YAML key')
        result[key] = loader.construct_object(value_node)
    return result


ConfigLoader.add_constructor('tag:yaml.org,2002:map', unique_mapping)

BEGIN = '# BEGIN FRONTEND-AI-STACK OMP WORKFLOW v3.13.2'
END = '# END FRONTEND-AI-STACK OMP WORKFLOW v3.13.2'
KEYS = {'lsp','bash','task','isolation','async','autolearn','memory','browser','computer','tools'}


def fail(msg):
    raise SystemExit('FAIL ' + msg)


def rendered(browser=True, computer=False):
    return f"""{BEGIN}
# Subagent work is opt-in per task; never auto-merge isolated changes.
lsp:
  enabled: true
  lazy: true
  diagnosticsOnWrite: true
  formatOnWrite: false
bash:
  gitGuard: true
task:
  batch: true
  isolation:
    enabled: true
    apply: false
isolation:
  backend: auto
async:
  enabled: true
  maxJobs: 8
# OMP can author skills; project history stays in TinyContext, not OMP memory.
autolearn:
  enabled: true
  autoContinue: false
memory:
  backend: off
browser:
  enabled: {str(browser).lower()}
computer:
  enabled: {str(computer).lower()}
  backgroundFallback: refuse
# Desktop input ALWAYS requires approval even when OMP uses yolo mode.
tools:
  approval:
    computer: prompt
    computer.control: prompt
{END}
"""


def get_content(path):
    s = path.read_text()
    if s.count(BEGIN) > 1 or s.count(END) > 1 or ((BEGIN in s) != (END in s)):
        fail(f'{path}: inconsistent managed block; manual inspection required')
    try:
        config = yaml.load(s, Loader=ConfigLoader) or {}
        if not isinstance(config, dict):
            raise ValueError('not a mapping')
    except (yaml.YAMLError, ValueError, TypeError):
        fail(f'{path}: invalid/duplicate YAML; left untouched')
    present = set(config) & KEYS
    browser, computer = True, False
    if present:
        # OMP serializes config.yml without comments. Adopt only a complete,
        # recognized policy, with the two supported per-profile toggles.
        try:
            browser = config['browser']['enabled']
            computer = config['computer']['enabled']
            if type(browser) is not bool or type(computer) is not bool:
                raise ValueError('invalid toggle')
            expected = yaml.load(rendered(browser, computer), Loader=ConfigLoader)
            if present != KEYS or any(config[k] != expected[k] for k in KEYS):
                raise ValueError('foreign policy')
        except (KeyError, TypeError, ValueError):
            fail(f'{path}: user-owned YAML keys would collide with managed policy; left untouched')
    return s, bool(present), browser, computer


def replace_policy(text, policy):
    """Replace recognized sections while preserving all other YAML bytes."""
    text = '\n'.join(line for line in text.splitlines() if line not in (BEGIN, END)) + '\n'
    headers = list(re.finditer(r'^([^\s#][^\n]*)', text, re.M))
    cuts = []
    for i, header in enumerate(headers):
        key = re.match(r'([a-zA-Z][\w-]*):', header.group(1))
        if key and key.group(1) in KEYS:
            end = headers[i + 1].start() if i + 1 < len(headers) else len(text)
            cuts.append((header.start(), end))
    for start, end in reversed(cuts):
        text = text[:start] + text[end:]
    result = text.rstrip() + '\n\n' + policy
    # Do not publish a replacement if an unusual YAML layout evaded the cuts.
    try:
        yaml.load(result, Loader=ConfigLoader)
    except (yaml.YAMLError, ValueError, TypeError):
        fail('unsupported YAML layout; left untouched')
    return result


def atomic_write(path, text):
    fd, name = tempfile.mkstemp(prefix='.mm-omp-features-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as handle:
            handle.write(text)
        os.chmod(name, 0o600)
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def run(opts):
    plans = []
    for profile in ('working','private'):
        path=Path.home()/'.omp/profiles'/profile/'agent/config.yml'
        if not path.is_file():
            if opts.preflight: print(f'PASS  features preflight {profile}: config pending'); continue
            fail(f'{path} missing; run ./setup-yolo-omp.sh')
        old, existing, browser, computer=get_content(path)
        if opts.preflight:
            print(f'PASS  features preflight {profile}: no colliding keys')
            continue
        # Preserve per-profile choices through later normal upgrades.
        if opts.profile in ('both',profile):
            if opts.browser != 'keep': browser=opts.browser=='on'
            if opts.computer != 'keep': computer=opts.computer=='on'
        desired = yaml.load(rendered(browser, computer), Loader=ConfigLoader)
        actual = yaml.load(old, Loader=ConfigLoader) or {}
        unchanged = existing and all(actual[k] == desired[k] for k in KEYS)
        new = old if unchanged else replace_policy(old, rendered(browser,computer))
        if opts.check:
            if not unchanged:
                fail(f'{path}: feature block missing/modified; run ./setup-yolo-omp.sh')
        plans.append((path, old, new, desired))
        print(f'PASS  OMP {profile} features: LSP, subagents, guarded skills, browser={browser}, computer={computer}, memory=TinyContext only')
    if not opts.check and not opts.preflight:
        # Validate both profiles before writing either one.
        for path, old, new, desired in plans:
            if new != old:
                atomic_write(path, new)
            manifest = path.parent / '.mm-omp-features.json'
            content = json.dumps({'version': 1, 'policy': desired}, indent=2) + '\n'
            if not manifest.exists() or manifest.read_text() != content:
                atomic_write(manifest, content)


if __name__ == '__main__':
    p=argparse.ArgumentParser()
    p.add_argument('--check', action='store_true')
    p.add_argument('--preflight', action='store_true')
    p.add_argument('--profile', choices=['working','private','both'],default='both')
    p.add_argument('--browser', choices=['on','off','keep'],default='keep')
    p.add_argument('--computer', choices=['on','off','keep'],default='keep')
    o=p.parse_args()
    if o.check and (o.browser!='keep' or o.computer!='keep'): p.error('Cannot modify features in --check mode')
    if o.check and o.preflight: p.error('--check and --preflight conflict')
    run(o)

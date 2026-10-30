#!/usr/bin/env python3
"""Configure OMP workflow overlays without overwriting unrelated YAML or credentials.

The managed block is complete YAML and updates idempotently. Any top-level keys
that would collide with a user-owned part of the config cause a hard failure.
"""
import argparse
import os
import re
import sys
from pathlib import Path

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
    existing = ''
    if BEGIN in s:
        prefix, tail = s.split(BEGIN, 1)
        block, suffix = tail.split(END, 1)
        existing = BEGIN + block + END
        remaining = prefix + suffix
    else:
        remaining = s
    # Reject foreign top-level keys whose semantics we would otherwise shadow.
    colliding = set(re.findall(r'^([a-zA-Z][\w-]*):\s*(?:#.*)?$', remaining, re.M)) & KEYS
    if colliding:
        fail(f'{path}: user-owned YAML keys would collide with managed policy: {", ".join(sorted(colliding))}')
    return s, remaining, existing


def run(opts):
    for profile in ('working','private'):
        path=Path.home()/'.omp/profiles'/profile/'agent/config.yml'
        if not path.is_file():
            if opts.preflight: print(f'PASS  features preflight {profile}: config pending'); continue
            fail(f'{path} missing; run ./setup-yolo-omp.sh')
        old, remaining, existing=get_content(path)
        if opts.preflight:
            print(f'PASS  features preflight {profile}: no colliding keys')
            continue
        # Preserve per-profile choices through later normal upgrades.
        browser = ('browser:\n  enabled: true' in existing) if existing else True
        computer = ('computer:\n  enabled: true' in existing) if existing else False
        if opts.profile in ('both',profile):
            if opts.browser != 'keep': browser=opts.browser=='on'
            if opts.computer != 'keep': computer=opts.computer=='on'
        new = remaining.rstrip() + '\n\n' + rendered(browser,computer)
        if opts.check:
            if not existing or new != old:
                fail(f'{path}: feature block missing/modified; run ./setup-yolo-omp.sh')
        elif new != old:
            # No overwrite of external user settings, and write in one rename.
            import tempfile
            fd, name=tempfile.mkstemp(prefix='.mm-omp-features-',dir=str(path.parent))
            try:
                with os.fdopen(fd,'w') as h: h.write(new)
                os.chmod(name,0o600)
                os.replace(name,path)
            finally:
                if os.path.exists(name): os.unlink(name)
        print(f'PASS  OMP {profile} features: LSP, subagents, guarded skills, browser={browser}, computer={computer}, memory=TinyContext only')


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

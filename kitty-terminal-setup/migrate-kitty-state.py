#!/usr/bin/env python3
"""Remove the two retired baseline tabs from a Kitty save without disturbing other tabs.

Requires Kitty to be closed. Makes a timestamped backup; never deletes the saved
session file and refuses to touch other content it cannot recognize safely.
"""
from __future__ import annotations
import datetime
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys

xdg_config=Path(os.environ.get('XDG_CONFIG_HOME',str(Path.home()/'.config')))
xdg_state=Path(os.environ.get('XDG_STATE_HOME',str(Path.home()/'.local/state')))
state=xdg_config/'kitty/last-state.kitty-session'
backups=xdg_state/'kitty-workspace-pack/state-backups'

try:
    running=subprocess.run(['pgrep','-x','kitty'],capture_output=True,check=False)
    if running.returncode==0:
        sys.exit('Kitty is still running. Close all Kitty windows before migrating the saved state.')
except FileNotFoundError:
    print('Warning: pgrep not installed; ensure Kitty is closed.',file=sys.stderr)

if not state.is_file():
    sys.exit(f'No saved state found: {state}')
original=state.read_text(encoding='utf-8')
lines=original.splitlines(keepends=True)
# Keep all directives before the first new_tab untouched. They define the
# OS-window configuration, not the obsolete tab.
first_tab=next((i for i,line in enumerate(lines) if line.strip().startswith('new_tab ')), None)
if first_tab is None:
    sys.exit('No new_tab directives found; saved session format is unfamiliar. No changes made.')
preamble=lines[:first_tab]
sections=[]
current=[]
for line in lines[first_tab:]:
    if line.strip().startswith('new_tab ') and current:
        sections.append(current)
        current=[]
    current.append(line)
if current: sections.append(current)

removed=[]
output=list(preamble)
for block in sections:
    title=None
    legacy_cwd=False
    for line in block:
        s=line.strip()
        try: parts=shlex.split(s,comments=False)
        except ValueError: parts=[]
        if parts and parts[0]=='new_tab' and len(parts)>1:
            title=' '.join(parts[1:])
        if parts and parts[0]=='cd' and len(parts)==2:
            cwd=parts[1].replace('\\','/')
            legacy_cwd=(cwd in ('~/dev/github/melody-mind', str(Path.home()/'dev/github/melody-mind')))
    if title in ('Melody Mind 1','Melody Mind 2') and legacy_cwd:
        # Refuse ambiguous blocks: users may have added windows or settings.
        allowed={'new_tab', 'cd', 'launch', 'layout', 'enabled_layouts'}
        actual=[]
        for line in block:
            s=line.strip()
            if s and not s.startswith('#'):
                try: actual.append(shlex.split(s)[0])
                except (ValueError,IndexError): actual.append('UNKNOWN')
        if any(word not in allowed for word in actual):
            sys.exit(f'Custom content in retired tab {title}; no changes made. Close it manually in Kitty and save.')
        removed.append(title)
        continue
    output.extend(block)

if not removed:
    if 'melody-mind' in original.lower() or 'Melody Mind' in original:
        sys.exit('A Melody Mind reference remains, but its tab format differs from the known baseline. No changes made; please close those tabs in Kitty and save manually.')
    print('No retired baseline tabs found. The saved state is unchanged.')
    sys.exit(0)

result=''.join(output)
if 'melody-mind' in result.lower() or 'Melody Mind' in result:
    sys.exit('Other Melody Mind references were found. No changes made; please review the session manually.')
if not any(line.strip().startswith('new_tab ') for line in output):
    sys.exit('Migration would leave no tabs. No changes made. Use reset-kitty-state.sh instead.')

backups.mkdir(parents=True,exist_ok=True)
stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
backup=backups/f'pre-fedora-{stamp}.kitty-session'
shutil.copy2(state,backup)
interim=state.with_suffix(state.suffix+'.tmp')
interim.write_text(result,encoding='utf-8')
interim.replace(state)
print('Removed legacy tabs:',', '.join(removed))
print('Other tabs, window settings and directories were preserved.')
print('Backup:',backup)
print('Live state:',state)

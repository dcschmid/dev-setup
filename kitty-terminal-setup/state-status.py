#!/usr/bin/env python3
"""Read-only status of Kitty persistent sessions; never prints session contents."""
from __future__ import annotations
import os
from pathlib import Path
from datetime import datetime

config = Path(os.getenv('KITTY_CONFIG_DIRECTORY') or Path(os.getenv('XDG_CONFIG_HOME',Path.home()/'.config'))/'kitty')
state_dir = Path(os.getenv('XDG_STATE_HOME',Path.home()/'.local/state'))/'kitty-workspace-pack'
state = config/'last-state.kitty-session'

def show(path: Path, title: str):
    if not path.is_file():
        print(f'{title}: nicht vorhanden')
        return
    text=path.read_text(encoding='utf-8', errors='replace')
    active=[line.strip().split(' ',1)[0] for line in text.splitlines() if line.strip() and not line.lstrip().startswith('#')]
    age=datetime.fromtimestamp(path.stat().st_mtime).strftime('%Y-%m-%d %H:%M:%S')
    print(f'{title}: {age}; {active.count("new_tab")} Tabs; {active.count("launch")} Terminals')
    print('  Prüfung:', 'plausibel' if 'new_tab' in active and 'launch' in active else 'UNGEWÖHNLICH')

show(state,'Aktueller Zustand')
backups=sorted((state_dir/'autosave-backups').glob('session-*.kitty-session')) if (state_dir/'autosave-backups').exists() else []
print(f'Automatische Sicherungen: {len(backups)} (max. 12)')
if backups: show(backups[-1], 'Letzte Sicherung')
error=state_dir/'autosave-error.log'
print('Autosave-Fehlerprotokoll:', str(error) if error.exists() else 'keines')
print('Tipp: Autosave-Funktion auf deinem Framework unter Wayland praktisch testen.')

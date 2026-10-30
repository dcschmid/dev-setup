#!/usr/bin/env python3
"""Offline checks; no actual Fedora or Kitty daemon needed."""
from __future__ import annotations
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import types
import unittest

ROOT = Path(__file__).resolve().parent


def load_watcher(home: Path):
    kitty = types.ModuleType('kitty')
    boss_mod = types.ModuleType('kitty.boss')
    fast = types.ModuleType('kitty.fast_data_types')
    win_mod = types.ModuleType('kitty.window')
    boss_mod.Boss = type('Boss', (), {})
    fast.add_timer = lambda fn, interval, repeat: None
    win_mod.Window = type('Window', (), {})
    saved = {name: sys.modules.get(name) for name in ['kitty', 'kitty.boss', 'kitty.fast_data_types', 'kitty.window']}
    sys.modules.update({'kitty':kitty, 'kitty.boss':boss_mod, 'kitty.fast_data_types':fast, 'kitty.window':win_mod})
    old={name:os.environ.get(name) for name in ['KITTY_CONFIG_DIRECTORY','XDG_STATE_HOME']}
    os.environ['KITTY_CONFIG_DIRECTORY']=str(home/'config')
    os.environ['XDG_STATE_HOME']=str(home/'state')
    try:
        spec=importlib.util.spec_from_file_location('mock_watcher', ROOT/'config/state-autosave.py')
        mod=importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
    finally:
        for name,prev in saved.items():
            if prev is None:sys.modules.pop(name, None)
            else:sys.modules[name]=prev
        for name,prev in old.items():
            if prev is None:os.environ.pop(name, None)
            else:os.environ[name]=prev
    return mod


class BossMock:
    def __init__(self, stage, text, quick=False):
        self.stage=stage;self.text=text;self.active_window=object()
        self.quick=quick;self.calls=0

    def list_os_windows(self):
        return [{'wm_class':'kitty-quick-access' if self.quick else 'kitty'}]

    def call_remote_control(self, window, args):
        assert args[0]=='action'
        assert 'save_as_session' in args[1]
        self.calls+=1
        self.stage.parent.mkdir(parents=True,exist_ok=True)
        self.stage.write_text(self.text)
        return {'ok':True}


class Tests(unittest.TestCase):
    def test_watcher_valid_and_invalid_state(self):
        with tempfile.TemporaryDirectory() as d:
            m=load_watcher(Path(d))
            initial='new_tab Unified Frontend 1\ncd ~\nlaunch\n'
            m.STATE_FILE.parent.mkdir(parents=True)
            m.STATE_FILE.write_text(initial)
            good='new_tab Unified Frontend 1\ncd ~\nlaunch\nnew_tab extra\nlaunch\n'
            boss=BossMock(m.STAGING_FILE,good)
            m._save(boss)
            self.assertEqual(m.STATE_FILE.read_text(),good)
            self.assertEqual(len(list(m.BACKUP_DIR.glob('*.kitty-session'))),1)
            broken=BossMock(m.STAGING_FILE,'corrupt')
            m._save(broken, force=True)
            self.assertEqual(m.STATE_FILE.read_text(),good)
            self.assertTrue(m.ERROR_FILE.exists())
            self.assertFalse(m.STAGING_FILE.exists())
            quick=BossMock(m.STAGING_FILE,initial,quick=True)
            m._save(quick, force=True)
            self.assertEqual(quick.calls,0)
            self.assertEqual(m.STATE_FILE.read_text(),good)

    def test_config_only_install_preserves_state_and_no_downloads(self):
        with tempfile.TemporaryDirectory() as d:
            home=Path(d)
            fakebin=home/'fakebin';fakebin.mkdir()
            kitty=fakebin/'kitty'; kitty.write_text('#!/bin/sh\necho "kitty 0.49.2"\n');kitty.chmod(0o755)
            zsh=fakebin/'zsh';zsh.write_text('#!/bin/sh\necho "zsh 5.9"\n');zsh.chmod(0o755)
            # Simulate an old state containing user-added tabs.
            session=home/'.config/kitty/last-state.kitty-session'
            session.parent.mkdir(parents=True)
            state='new_tab user one\ncd ~\nlaunch\nnew_tab user two\nlaunch\n'
            session.write_text(state)
            env=os.environ.copy();env['HOME']=str(home)
            env['XDG_CONFIG_HOME']=str(home/'.config');env['XDG_DATA_HOME']=str(home/'.local/share');env['XDG_STATE_HOME']=str(home/'.local/state')
            env['PATH']=str(fakebin)+os.pathsep+env.get('PATH','')
            # Defeat any latent package/network calls by making sudo/curl/git impossible.
            for tool in ['sudo','curl']:
                f=fakebin/tool;f.write_text('#!/bin/sh\necho "NETWORK DISALLOWED" >&2;exit 87\n');f.chmod(0o755)
            for _ in range(2):
                result=subprocess.run(['bash',str(ROOT/'install.sh'),'--config-only'],env=env,capture_output=True,text=True,timeout=25)
                self.assertEqual(result.returncode,0, result.stderr+result.stdout)
                self.assertEqual(session.read_text(),state)
            conf=(home/'.config/kitty/local-workspaces.conf').read_text()
            self.assertIn(f'save_as_session --save-only {session}',conf)
            self.assertIn('startup_session last-state.kitty-session',conf)
            self.assertEqual((home/'.config/kitty/kitty.conf').read_text().count('include local-workspaces.conf'),1)
            quick=(home/'.config/kitty/quick-access-kitty.conf').read_text()
            self.assertNotIn('watcher state-autosave',quick)
            self.assertIn('startup_session none',quick)
            self.assertTrue((home/'.local/share/applications/kitty-workspace.desktop').is_file())
            self.assertIn('--single-instance', (home/'.local/share/applications/kitty-workspace.desktop').read_text())
            # No legacy project sessions created.
            self.assertFalse((home/'.local/share/kitty/sessions/melody-mind.kitty-session').exists())
            self.assertFalse((home/'.local/share/kitty/sessions/unified-frontend.kitty-session').exists())
            before=session.read_text()
            result=subprocess.run(['bash',str(ROOT/'uninstall.sh')],env=env,capture_output=True,text=True,timeout=25)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual(session.read_text(),before)


if __name__=='__main__':unittest.main(verbosity=2)

import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'scripts'))
from manage_config import jsonc_to_json, deep_merge, merge_tasks


class ConfigTests(unittest.TestCase):
    def test_jsonc_comments_trailing_commas_and_urls(self):
        raw = '''{
          // comment
          "url": "https://a.test/a,//,}",
          "literal": "/* keep */",
          /* comment */ "nested": {"key": true,},
        }'''
        parsed = json.loads(jsonc_to_json(raw))
        self.assertEqual(parsed['url'], 'https://a.test/a,//,}')
        self.assertEqual(parsed['literal'], '/* keep */')
        self.assertTrue(parsed['nested']['key'])

    def test_merge_preserves_unowned_keys(self):
        old = {'agent_servers': {'custom': {'command': 'pi'}}, 'languages': {'Rust': {'tab_size': 4}},
               'file_scan_exclusions': ['**/secret/**', '...']}
        new = {'languages': {'Astro': {'tab_size': 2}},
               'file_scan_exclusions': ['**/node_modules/**', '...']}
        merged = deep_merge(old, new)
        self.assertEqual(merged['agent_servers']['custom']['command'], 'pi')
        self.assertEqual(merged['languages']['Rust']['tab_size'], 4)
        self.assertEqual(merged['file_scan_exclusions'].count('...'), 1)
        self.assertIn('**/secret/**', merged['file_scan_exclusions'])

    def test_tasks_only_replace_owned_labels(self):
        old = [{'label': 'My Custom Task', 'command': 'echo ok'},
               {'label': 'Web · Dev Server', 'command': 'old'}]
        new = [{'label': 'Web · Dev Server', 'command': 'new'}]
        out = merge_tasks(old, new)
        self.assertEqual(len(out), 2)
        self.assertEqual(out[0]['label'], 'My Custom Task')
        self.assertEqual(out[1]['command'], 'new')

    def test_install_idempotence_restore_conflict_and_guard(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t)
            config = root / 'zed'
            bindir = root / 'bin'
            backups = root / 'backups'
            config.mkdir()
            original = '{"agent_servers":{"myagent":{"command":"existing"}}, /* hi */ "theme":"Before",}\n'
            (config / 'settings.json').write_text(original)
            (config / 'tasks.json').write_text('[{"label":"Own", "command":"echo hi"}]\n')
            command = [sys.executable, str(ROOT / 'scripts/manage_config.py'),
                       '--config-dir', str(config), '--bin-dir', str(bindir), '--backup-dir', str(backups)]
            env = dict(os.environ, ALLOW_ZED_DEVKIT_ROOT='1')
            dry = subprocess.run([*command, '--dry-run'], env=env, capture_output=True, text=True)
            self.assertEqual(dry.returncode, 0, dry.stderr)
            self.assertEqual(list(backups.glob('*/manifest.json')), [])
            first = subprocess.run(command, env=env, capture_output=True, text=True)
            self.assertEqual(first.returncode, 0, first.stderr)
            installed = json.loads((config / 'settings.json').read_text())
            self.assertEqual(installed['agent_servers']['myagent']['command'], 'existing')
            self.assertEqual(installed['theme']['dark'], 'Catppuccin Mocha')
            self.assertEqual(len(list(backups.glob('*/manifest.json'))), 1)
            second = subprocess.run(command, env=env, capture_output=True, text=True)
            self.assertIn('Already up to date', second.stdout)
            self.assertEqual(len(list(backups.glob('*/manifest.json'))), 1)
            (config / 'settings.json').write_text('{}\n')
            denied = subprocess.run([*command, '--restore-latest'], env=env, capture_output=True, text=True)
            self.assertNotEqual(denied.returncode, 0)
            forced = subprocess.run([*command, '--restore-latest', '--force'], env=env, capture_output=True, text=True)
            self.assertEqual(forced.returncode, 0, forced.stderr)
            self.assertEqual((config / 'settings.json').read_text(), original)
            self.assertFalse((bindir / 'zed-dev').exists())
            self.assertEqual(json.loads((config / 'tasks.json').read_text())[0]['label'], 'Own')


if __name__ == '__main__':
    unittest.main()

# Additional functional smoke tests for the shell wrapper are intentionally
# run separately from unittest discovery, to avoid relying on a user zsh profile.

"""Offline regressions for policy delivery, profile boundaries and skill audits."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MaintenanceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.stack = self.home / 'stack'
        self.repo = self.home / 'repo'
        self.repo.mkdir()
        subprocess.run(['git', 'init', '-q', str(self.repo)], check=True)
        self.env = dict(os.environ, HOME=str(self.home), MM_STACK_DATA_HOME=str(self.stack),
                        MM_AGENT_PROFILE='private', PYTHONDONTWRITEBYTECODE='1')
        self.env.pop('CODEX_HOME', None)
        self.env.pop('MM_CODEX_WORKING_HOME', None)
        for profile in ('private', 'working'):
            self.put(self.stack / f'rules/{profile}.md', (ROOT / f'payload/{profile}/RULES.md').read_text())
        for name in ('claude-private', 'claude-working', 'yolo-private', 'yolo-working'):
            self.put(self.home / f'.local/bin/{name}', (ROOT / f'payload/bin/{name}').read_text())

    def put(self, path, value):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value)
        return path

    def run_tool(self, tool, *args, ok=True):
        result = subprocess.run(['python3', str(ROOT / 'payload/bin' / tool), *args],
                                env=self.env, cwd=self.repo, text=True, capture_output=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def test_codex_isolation_rules_and_credentials(self):
        private = self.put(self.home / '.codex/config.toml', '''model = "keep"
[mcp_servers.tinysearch]
command = "echo"
[mcp_servers."mm-tinycontext"]
command = "echo"
[mcp_servers."private.custom"]
command = "keep"
[mcp_servers."private.custom".env]
KEEP = "value"
[mcp_servers."riff-asset-forge"]
command = "/missing/riff-asset-forge/.venv/bin/tool"
''')
        auth = self.put(self.home / '.codex/auth.json', 'CREDENTIAL_SENTINEL')
        agents = self.put(self.home / '.codex/AGENTS.md', 'Personal instruction.\n')
        work = self.stack / 'codex-working-home/config.toml'
        work.parent.mkdir(parents=True)
        work.symlink_to(private)
        self.run_tool('mm-profile-runtime', 'install')
        self.assertFalse(work.is_symlink())
        working = tomllib.loads(work.read_text())
        self.assertEqual(set(working['mcp_servers']), {'tinysearch', 'mm-tinycontext'})
        self.assertEqual(working['model'], 'keep')
        original = tomllib.loads(private.read_text())
        self.assertIn('private.custom', original['mcp_servers'])
        self.assertNotIn('riff-asset-forge', original['mcp_servers'])
        self.assertEqual(auth.read_text(), 'CREDENTIAL_SENTINEL')
        self.assertIn('Personal instruction.', agents.read_text())
        previous = agents.read_text()
        self.run_tool('mm-profile-runtime', 'install')
        self.assertEqual(previous, agents.read_text())
        # User edits to the now independent Working file survive later launches.
        work.write_text(work.read_text() + '\n[mcp_servers.working_custom]\ncommand="echo"\n')
        self.run_tool('mm-profile-runtime', 'prepare', 'codex', 'working')
        self.assertIn('working_custom', tomllib.loads(work.read_text())['mcp_servers'])
        self.run_tool('mm-profile-runtime', 'check')

    def test_claude_scopes_global_and_project_tools(self):
        self.put(self.home / '.claude.json', json.dumps({'mcpServers': {
            'tinysearch': {'command': 'echo'}, 'mm-tinycontext': {'command': 'echo'},
            'private_custom': {'command': 'do-not-inherit'},
            'riff-asset-forge': {'command': '/missing/riff-asset-forge/tool'},
        }}))
        self.put(self.repo / '.mcp.json', json.dumps({'mcpServers': {
            'storybook': {'url': 'http://localhost:6006/mcp'},
            'disguised': {'command': 'uvx', 'args': ['mcp-for-blender@2.2.0']},
        }}))
        result = self.run_tool('mm-profile-runtime', 'claude-mcp')
        target = Path(result.stdout.strip())
        self.assertEqual(set(json.loads(target.read_text())['mcpServers']), {'tinysearch', 'mm-tinycontext', 'storybook'})
        self.assertEqual(target.stat().st_mode & 0o777, 0o600)

    def test_skill_audit_validates_yaml_and_follows_links(self):
        skills = self.stack / 'skills/shared'
        invalid = self.put(skills / 'invalid/SKILL.md', 'name: invalid\ndescription: No delimiters\n')
        self.run_tool('mm-skill-audit', '--profile', 'private', '--strict', ok=False)
        invalid.unlink()
        valid = self.put(skills / 'valid/SKILL.md', '---\nname: valid\ndescription: >\n  A multiline description.\n---\nInstructions.\n')
        link = self.home / '.codex/skills/valid'
        link.parent.mkdir(parents=True)
        link.symlink_to(valid.parent)
        (valid.parent / 'cycle').symlink_to(skills, target_is_directory=True)
        result = self.run_tool('mm-skill-audit', '--profile', 'private', '--strict', '--json')
        rows = json.loads(result.stdout)['skills']
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]['name'], 'valid')
        self.put(self.repo / '.agents/skills/a/SKILL.md', '---\nname: duplicate\ndescription: A\n---\nOne\n')
        self.put(self.repo / '.claude/skills/b/SKILL.md', '---\nname: duplicate\ndescription: B\n---\nTwo\n')
        self.run_tool('mm-skill-audit', '--profile', 'private', '--strict', ok=False)

    def test_upstream_missing_skill_does_not_replace_existing(self):
        source = self.home / 'upstream-fixture'
        self.put(source / 'skills/react-best-practices/SKILL.md', '---\nname: react\ndescription: Fixture\n---\nNew\n')
        old = self.put(self.stack / 'skills/working/react-best-practices/SKILL.md', 'OLD_CONTENT')
        mock = self.put(self.home / 'mockbin/git', '''#!/usr/bin/env python3
import os, pathlib, shutil, sys
if 'clone' in sys.argv:
    shutil.copytree(os.environ['TEST_UPSTREAM_SOURCE'], sys.argv[-1])
else:
    print('a' * 40)
''')
        mock.chmod(0o755)
        self.env.update(PATH=str(mock.parent) + os.pathsep + os.environ['PATH'], TEST_UPSTREAM_SOURCE=str(source))
        self.run_tool('mm-refresh-skills', '--only', 'vercel', ok=False)
        self.assertEqual(old.read_text(), 'OLD_CONTENT')
        self.assertFalse((self.stack / 'upstream/vercel-agent-skills.commit').exists())
        self.put(source / 'skills/composition-patterns/SKILL.md', '---\nname: composition\ndescription: Fixture\n---\nCompose\n')
        self.run_tool('mm-refresh-skills', '--only', 'vercel')
        self.assertIn('New', old.read_text())
        self.assertEqual((self.stack / 'upstream/vercel-agent-skills.commit').read_text().strip(), 'a' * 40)
        backups = list((self.stack / 'upstream/backups').glob('*/react-best-practices/SKILL.md'))
        self.assertTrue(any(p.read_text() == 'OLD_CONTENT' for p in backups))

    def test_omp_skill_refresh_respects_repository_override(self):
        for group, name in (('shared', 'common'), ('private', 'game'), ('omp', 'omp-only')):
            self.put(self.stack / f'skills/{group}/{name}/SKILL.md', f'---\nname: {name}\ndescription: Fixture\n---\nPackage\n')
        self.run_tool('mm-profile-skills-sync', 'omp', 'private', '--quiet')
        target = self.home / '.omp/profiles/private/agent/skills'
        self.assertTrue((target / 'common').is_symlink())
        self.assertTrue((target / 'omp-only').is_symlink())
        custom = self.put(target / 'user-owned/SKILL.md', 'USER_CONTENT')
        self.put(self.repo / '.agents/skills/common/SKILL.md', '---\nname: common\ndescription: Repo fixture\n---\nRepository\n')
        self.run_tool('mm-profile-skills-sync', 'omp', 'private', '--quiet')
        self.assertFalse((target / 'common').exists())
        self.assertTrue((target / 'game').is_symlink())
        self.assertEqual(custom.read_text(), 'USER_CONTENT')


if __name__ == '__main__':
    unittest.main()

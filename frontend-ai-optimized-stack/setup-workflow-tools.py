#!/usr/bin/env python3
"""Install optional verified user-local forge/lint CLIs and pinned Firefox tooling."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request

TOOLS = {
    'gh': ('2.103.3', 'https://github.com/cli/cli/releases/download/v2.103.3/gh_2.103.3_linux_amd64.tar.gz', '4c806978ffce1cec70853302a56d70ac6da4f19bae7adca4e1a8ab00633dd91d'),
    'glab': ('1.126.0', 'https://gitlab.com/gitlab-org/cli/-/releases/v1.126.0/downloads/glab_1.126.0_linux_amd64.tar.gz', 'f386519ba83e9482979992ee7f60eeebee4d95b950f95f4fe7289e0a1b1ea74c'),
    'shellcheck': ('0.11.0', 'https://github.com/koalaman/shellcheck/releases/download/v0.11.0/shellcheck-v0.11.0.linux.x86_64.tar.xz', '8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198'),
}
PLAYWRIGHT_CLI = '0.1.22'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--install', action='store_true')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if args.install and args.check:
        parser.error('--install and --check conflict')
    if platform.system() != 'Linux' or platform.machine() not in ('x86_64', 'amd64'):
        parser.error('This pinned installer currently supports Linux x86_64 only')
    home = Path.home()
    stack = Path(os.getenv('MM_STACK_DATA_HOME', str(Path(os.getenv('XDG_DATA_HOME', str(home / '.local/share'))) / 'frontend-ai-stack')))
    bindir = home / '.local/bin'
    missing = []
    for name, (version, url, digest) in TOOLS.items():
        if shutil.which(name):
            subprocess.run([name, '--version'], check=True, stdout=subprocess.DEVNULL)
            print(f'PASS  {name}: existing CLI kept')
            continue
        if not args.install:
            missing.append(name)
            continue
        target = bindir / name
        if target.exists() or target.is_symlink():
            raise ValueError(f'{target}: refusing to overwrite an existing executable/link')
        bindir.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='.workflow-', dir=bindir) as tmp:
            archive = Path(tmp) / 'download'
            with urllib.request.urlopen(url, timeout=60) as response, archive.open('wb') as stream:
                shutil.copyfileobj(response, stream)
            if hashlib.sha256(archive.read_bytes()).hexdigest() != digest:
                raise ValueError(f'{name}: checksum verification failed')
            with tarfile.open(archive) as package:
                members = [m for m in package.getmembers() if m.isfile() and Path(m.name).name == name]
                if len(members) != 1:
                    raise ValueError(f'{name}: unexpected archive contents')
                # Extract one verified regular file, never archive-controlled paths.
                stream = package.extractfile(members[0])
                staged = Path(tmp) / name
                with staged.open('wb') as out:
                    shutil.copyfileobj(stream, out)
                staged.chmod(0o755)
                subprocess.run([str(staged), '--version'], check=True, stdout=subprocess.DEVNULL)
                os.replace(staged, target)
            print(f'PASS  {name} {version}: installed verified binary')
    prefix = stack / 'tools/playwright'
    binary = prefix / 'node_modules/.bin/playwright-cli'
    if args.install:
        prefix.mkdir(parents=True, exist_ok=True)
        manifest = prefix / 'node_modules/@playwright/cli/package.json'
        installed = json.loads(manifest.read_text()).get('version') if manifest.exists() else None
        if installed != PLAYWRIGHT_CLI:
            subprocess.run(['npm', 'install', '--prefix', str(prefix), '--ignore-scripts', '--no-audit', '--no-fund', f'@playwright/cli@{PLAYWRIGHT_CLI}'], check=True)
        source = Path(__file__).parent / 'payload/bin/mm-playwright'
        target = bindir / 'mm-playwright'
        if target.is_symlink():
            raise ValueError('refusing to replace a user-owned mm-playwright symlink')
        shutil.copy2(source, target)
        target.chmod(0o755)
        subprocess.run([str(binary), 'install-browser', 'firefox'], check=True)
    if binary.exists() and shutil.which('mm-playwright'):
        result = subprocess.run(['node', '-e', 'process.stdout.write(require(process.argv[1]).firefox.executablePath())', str(prefix / 'node_modules/playwright')], check=True, capture_output=True, text=True)
        if not Path(result.stdout).is_file():
            missing.append('Playwright Firefox runtime')
    else:
        missing.append('Playwright CLI/Firefox launcher')
    if missing:
        print('INFO  Optional tools missing: ' + ', '.join(missing))
        return 1
    print('PASS  Workflow tools available; forge authentication remains account-specific')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

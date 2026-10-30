#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

if len(sys.argv) != 3:
    raise SystemExit("usage: patch_codex_tinycontext.py <config.toml> <launcher-command>")

path = Path(sys.argv[1]).expanduser()
command = sys.argv[2]
path.parent.mkdir(parents=True, exist_ok=True)
text = path.read_text() if path.exists() else ""
lines = text.splitlines(keepends=True)
header_re = re.compile(r"^\s*\[([^]]+)\]\s*(?:#.*)?$")
target_re = re.compile(r'^mcp_servers\.(?:"mm-tinycontext"|mm-tinycontext)(?:\.|$)')

out: list[str] = []
i = 0
while i < len(lines):
    m = header_re.match(lines[i].rstrip("\n"))
    if m and target_re.match(m.group(1).strip()):
        i += 1
        while i < len(lines):
            if header_re.match(lines[i].rstrip("\n")):
                break
            i += 1
        continue
    out.append(lines[i])
    i += 1

base = "".join(out).rstrip()
if base:
    base += "\n\n"
base += '[mcp_servers."mm-tinycontext"]\n'
base += f"command = {json.dumps(command)}\n"
base += "args = []\n"
base += "enabled = true\n"
path.write_text(base)

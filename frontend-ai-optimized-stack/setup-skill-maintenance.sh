#!/usr/bin/env bash
set -euo pipefail
command -v claude >/dev/null 2>&1 || { echo 'ERROR: Claude Code not found.' >&2; exit 1; }
cat <<'EOF'
Optional maintenance tool: Anthropic's official skill-creator plugin.
It is NOT needed for normal coding and is intentionally not auto-installed by the stack.
EOF
# Claude CLI supports plugin install non-interactively; if a future version rejects
# this form, the command printed below can be entered via /plugin in Claude Code.
if claude plugin install skill-creator@claude-plugins-official --scope user; then
  echo 'PASS: skill-creator installed for Claude Code (user scope).'
else
  echo 'Could not install non-interactively. In Claude Code run:' >&2
  echo '  /plugin install skill-creator@claude-plugins-official' >&2
  exit 1
fi

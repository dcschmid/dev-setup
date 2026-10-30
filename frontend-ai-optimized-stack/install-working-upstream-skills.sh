#!/usr/bin/env bash
set -euo pipefail
QUIET=0
[[ "${1:-}" == "--quiet" ]] && QUIET=1
log(){ [[ "$QUIET" -eq 1 ]] || printf '%s\n' "$*"; }
warn(){ printf 'WARN: %s\n' "$*" >&2; }
command -v git >/dev/null 2>&1 || { warn 'git not found; upstream skills were not refreshed.'; exit 0; }

STACK_ROOT="${MM_STACK_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/frontend-ai-stack}"
DEST="$STACK_ROOT/skills/working"
UP="$STACK_ROOT/upstream"
mkdir -p "$DEST" "$UP"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

refresh_repo() {
  local repo="$1" dst="$2"
  git clone --depth 1 -q "$repo" "$dst" 2>/dev/null
}

if refresh_repo https://github.com/vercel-labs/agent-skills.git "$tmp/vercel"; then
  for src in react-best-practices composition-patterns; do
    if [[ -d "$tmp/vercel/skills/$src" ]]; then
      rm -rf "$DEST/$src"
      cp -a "$tmp/vercel/skills/$src" "$DEST/"
    else
      warn "Vercel upstream skill missing: $src"
    fi
  done
  git -C "$tmp/vercel" rev-parse HEAD > "$UP/vercel-agent-skills.commit"
  log 'PASS: refreshed Working Vercel React/composition skills.'
else
  warn 'could not fetch Vercel Agent Skills; bundled/package fallbacks remain available.'
fi

if refresh_repo https://github.com/figma/mcp-server-guide.git "$tmp/figma"; then
  for src in figma-use figma-design-to-code figma-code-connect; do
    if [[ -d "$tmp/figma/skills/$src" ]]; then
      rm -rf "$DEST/$src"
      cp -a "$tmp/figma/skills/$src" "$DEST/"
    else
      warn "Figma upstream skill missing: $src"
    fi
  done
  git -C "$tmp/figma" rev-parse HEAD > "$UP/figma-mcp-server-guide.commit"
  log 'PASS: refreshed Working Figma figma-use + design-to-code + Code Connect skills.'
else
  warn 'could not fetch Figma MCP skills; Working remains usable with bundled Figma SSOT policy.'
fi

log "Canonical Working skill store: $DEST"
log 'Workspace/repository skills are never modified by this updater.'

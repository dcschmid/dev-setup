#!/usr/bin/env bash
set -u
failed=()
pass(){ printf 'PASS  %-43s %s\n' "$1" "${2:-}"; }
info(){ printf 'INFO  %-43s %s\n' "$1" "${2:-}"; }
bad(){ printf 'FAIL  %-43s %s\n' "$1" "${2:-}"; failed+=("$1${2:+: $2}"); }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="${MM_STACK_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/frontend-ai-stack}"
echo 'Frontend AI Optimized Stack v3.14.0 verification'
python3 "$ROOT/scripts/check_blender_scope.py" >/dev/null 2>&1 && pass 'No globally visible Blender MCP' || bad 'No globally visible Blender MCP' 'See docs/GLOBAL_MCPS.md'
for c in python3 uvx; do
  command -v "$c" >/dev/null 2>&1 && pass "dependency $c" || bad "dependency $c" 'missing'
done
for c in codex claude cswap; do
  command -v "$c" >/dev/null 2>&1 && pass "CLI $c" || info "CLI $c" 'not installed yet'
done
if "$ROOT/setup-omp-cli.sh" --check >/dev/null 2>&1; then
  pass 'Oh My Pi CLI executable and healthy'
else
  bad 'Oh My Pi CLI executable and healthy' 'missing/broken; run ./setup-omp-cli.sh --install'
fi
for c in codex-private codex-working claude-private claude-working yolo-private yolo-working omp-private omp-working mm-profile-skills-sync mm-tinycontext-mcp mm-tinycontext-path mm-project-memory-doctor mm-codex-manual-doctor mm-yolo-doctor; do
  [[ -x "$HOME/.local/bin/$c" ]] && pass "command $c" || bad "command $c" 'missing/not executable'
done
# Official Zed Delta is not part of this stack. The scanner never mistakes
# unrelated mcpdelta integrations for Zed's Delta product.
if python3 "$ROOT/scripts/cleanup_zed_delta.py" --check >/dev/null 2>&1; then
  pass 'No Zed Delta app/plugin/MCP registrations'
else
  bad 'No Zed Delta app/plugin/MCP registrations' 'run ./remove-zed-delta.sh --apply'
fi
for p in shared private working omp; do
  [[ -d "$STACK_ROOT/skills/$p" ]] && pass "skill group $p" || bad "skill group $p" 'missing'
done
if [[ -f "$STACK_ROOT/skills/omp/mm-omp-code-workflow/SKILL.md" ]]; then
  pass 'OMP-only code workflow skill installed'
else bad 'OMP-only code workflow skill installed' 'missing; run installer'; fi
for old in mm-blender-asset-pipeline mm-blender-defold-handoff; do
  [[ ! -e "$STACK_ROOT/skills/private/$old" ]] && pass "Blender skill removed: $old" || bad "Blender skill removed: $old" 'still in managed package'
done
for script in codex-private codex-working; do
  f="$HOME/.local/bin/$script"
  if [[ -f "$f" ]] && ! grep -Eq 'codex-switch run|cxswap auto|cxswap switch' "$f" && grep -q 'exec codex ' "$f"; then
    pass "direct Codex $script" 'no account rotation'
  else bad "direct Codex $script" 'still calls a rotation tool'; fi
done
if [[ -f "$HOME/.local/bin/codex-working" ]] && grep -q 'CODEX_HOME="$WORK_HOME"' "$HOME/.local/bin/codex-working"; then
  pass 'Working Codex session isolation'
else bad 'Working Codex session isolation' 'missing dedicated CODEX_HOME'; fi
if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active --quiet codex-swap-auto.service 2>/dev/null; then
  bad 'Legacy Codex auto-rotation daemon' 'active; run ./setup-codex-manual.sh'
else pass 'Legacy Codex auto-rotation daemon' 'inactive'; fi
if command -v uvx >/dev/null 2>&1; then
  "$ROOT/setup-yolo-omp.sh" --check >/dev/null 2>&1 && pass 'OMP Working/Private isolation and MCPs' || bad 'OMP Working/Private isolation and MCPs' 'run ./setup-yolo-omp.sh'
else info 'OMP profile registration' 'requires uvx'; fi

[[ -x "$ROOT/setup-omp-cli.sh" ]] && pass 'OMP auto-install helper available' || bad 'OMP auto-install helper available' 'missing'
[[ -x "$ROOT/setup-omp-features.sh" ]] && pass 'OMP feature toggles available' || bad 'OMP feature toggles available' 'missing'
[[ -x "$ROOT/setup-yolo-todo.sh" ]] && pass 'YOLO plan-first extension installer available' || bad 'YOLO plan-first extension installer available' 'missing'
[[ -x "$ROOT/setup-omp-completions.sh" ]] && pass 'OMP zsh completion helper available' || bad 'OMP zsh completion helper available' 'missing'
if command -v uvx >/dev/null 2>&1 && { command -v codex >/dev/null 2>&1 || command -v claude >/dev/null 2>&1; }; then
  "$ROOT/setup-global-mcps.sh" --check >/dev/null 2>&1 && pass 'Claude/Codex TinySuite + Private Blender' || bad 'Claude/Codex TinySuite + Private Blender' 'run ./setup-global-mcps.sh'
fi
if command -v codex >/dev/null 2>&1 && command -v claude >/dev/null 2>&1; then
  for p in working private; do
    MM_AGENT_PROFILE="$p" "$HOME/.local/bin/mm-project-memory-doctor" >/dev/null 2>&1 && pass "Shared Claude/Codex/OMP memory: $p" || bad "Shared Claude/Codex/OMP memory: $p" 'run mm-project-memory-doctor'
  done
fi
"$HOME/.local/bin/mm-profile-runtime" check >/dev/null 2>&1 && pass 'Profile rules and Working MCP boundary' || bad 'Profile rules and Working MCP boundary' 'run mm-profile-runtime check'
if (( ${#failed[@]} )); then
  echo; echo 'VERIFICATION_FAIL v3.14.0'; printf ' - %s\n' "${failed[@]}"; exit 1
fi
echo; echo 'VERIFICATION_PASS v3.14.0'

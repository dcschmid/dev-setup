#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/home/.config" XDG_CACHE_HOME="$TMP/home/.cache"
mkdir -p "$HOME/.omp/profiles/working/agent" "$HOME/.omp/profiles/private/agent" "$HOME/.local/bin"
for p in working private; do
  cat > "$HOME/.omp/profiles/$p/agent/config.yml" <<'YAML'
disabledProviders:
  - claude
  - codex
  - gemini
  - opencode
modelRoles:
  default: yolo-auto/qwen3.8-27b
YAML
done
printf 'TOKEN_DO_NOT_TOUCH\n' > "$HOME/.omp/profiles/private/agent/secret.json"
"$ROOT/setup-omp-features.sh" > /dev/null
"$ROOT/setup-omp-features.sh" --check > /dev/null
w="$HOME/.omp/profiles/working/agent/config.yml"
p="$HOME/.omp/profiles/private/agent/config.yml"
[[ "$(grep -c '^lsp:' "$w")" == 1 ]]
grep -q '  gitGuard: true' "$w"
grep -q '  backgroundFallback: refuse' "$p"
grep -q '  autoContinue: false' "$w"
grep -q '  backend: off' "$w"
grep -A1 '^browser:' "$w" | grep -q 'enabled: true'
grep -A1 '^computer:' "$p" | grep -q 'enabled: false'
"$ROOT/setup-omp-features.sh" --profile private --computer on >/dev/null
"$ROOT/setup-omp-features.sh" --profile working --browser off >/dev/null
"$ROOT/setup-omp-features.sh" --check > /dev/null
"$ROOT/setup-omp-features.sh" > /dev/null # idempotent, preserve toggles
grep -A1 '^computer:' "$p" | grep -q 'enabled: true'
grep -A1 '^computer:' "$w" | grep -q 'enabled: false'
grep -A1 '^browser:' "$w" | grep -q 'enabled: false'
grep -A1 '^browser:' "$p" | grep -q 'enabled: true'
[[ "$(grep -c '^lsp:' "$w")" == 1 ]]
grep -q 'TOKEN_DO_NOT_TOUCH' "$HOME/.omp/profiles/private/agent/secret.json"
# OMP saves parsed YAML and discards comments. Checks/upgrades must survive that
# round trip without changing the user's per-profile choices or unrelated keys.
python3 - "$ROOT" "$w" "$p" <<'PYROUNDTRIP'
from pathlib import Path
import runpy, sys, yaml
loader = runpy.run_path(str(Path(sys.argv[1]) / 'scripts/configure_omp_features.py'))['ConfigLoader']
for name in sys.argv[2:]:
    path = Path(name)
    data = yaml.load(path.read_text(), Loader=loader)
    data['symbolPreset'] = 'nerd'
    path.write_text(yaml.safe_dump(data, sort_keys=False))
PYROUNDTRIP
before="$(sha256sum "$w" "$p")"
"$ROOT/setup-omp-features.sh" --check > /dev/null
"$ROOT/setup-omp-features.sh" > /dev/null
[[ "$(sha256sum "$w" "$p")" == "$before" ]]
"$ROOT/setup-omp-features.sh" --profile working --browser on >/dev/null
"$ROOT/setup-omp-features.sh" --check >/dev/null
grep -q '^symbolPreset: nerd' "$w"
grep -A1 '^computer:' "$p" | grep -q 'enabled: true'
# Own settings collisions must not be overwritten.
printf 'browser:\n  enabled: true\n' >> "$w"
if "$ROOT/setup-omp-features.sh" --preflight >/dev/null 2>&1; then echo 'collision not rejected'; exit 1; fi
# Verify managed extension is hash-gated, not fetched at install time.
mkdir -p "$(dirname "$XDG_CACHE_HOME/frontend-ai-stack/yolo-todo-discipline.ts")"
printf '/* Simulated inert test extension */\n' > "$XDG_CACHE_HOME/frontend-ai-stack/yolo-todo-discipline.ts"
if "$ROOT/setup-yolo-todo.sh" --enable "$(printf '0%.0s' {1..64})" >/dev/null 2>&1; then echo 'bad sha accepted'; exit 1; fi
hash="$(sha256sum "$XDG_CACHE_HOME/frontend-ai-stack/yolo-todo-discipline.ts"|cut -d' ' -f1)"
"$ROOT/setup-yolo-todo.sh" --enable "$hash" >/dev/null
for profile in working private; do
  [[ -f "$HOME/.omp/profiles/$profile/agent/extensions/yolo-todo-discipline.ts" ]]
  test "$(cat "$HOME/.omp/profiles/$profile/agent/extensions/.mm-yolo-todo.sha256")" = "$hash"
done
"$ROOT/setup-yolo-todo.sh" --disable >/dev/null
for profile in working private; do
  [[ ! -e "$HOME/.omp/profiles/$profile/agent/extensions/yolo-todo-discipline.ts" ]]
done
# Test shell completions in a clean HOME, without requiring OMP installed.
"$ROOT/setup-omp-completions.sh" --install > /dev/null
"$ROOT/setup-omp-completions.sh" --install > /dev/null
[[ "$(grep -c '^# BEGIN FRONTEND-AI-STACK OMP COMPLETIONS$' "$HOME/.zshrc")" == 1 ]]
"$ROOT/setup-omp-completions.sh" --check > /dev/null
echo 'PASS OMP features: safe profiles, approvals, isolated memory, extension hash, rollback-safe disable, zsh completions'

#!/usr/bin/env bash
set -euo pipefail
# Protect local config backups (some user MCP configs may carry secrets).
umask 077
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
command -v python3 >/dev/null || { echo 'ERROR: python3 missing.' >&2; exit 1; }
# Validate first, before changing user files. Known v2.2.0 global Blender
# registrations will be snapshotted and migrated to the private-only overlay.
# Unknown custom registrations fail safely and are never touched.
python3 "$ROOT/scripts/migrate_global_blender.py" --preflight
# Fail before mutations on any unsafe old OMP profile or foreign Codex swap unit.
"$ROOT/setup-codex-manual.sh" --preflight
if command -v uvx >/dev/null 2>&1; then "$ROOT/setup-yolo-omp.sh" --preflight; fi
# Install the vendor CLI before modifying stack-managed config: a network/download
# failure must not leave a half-upgraded profile setup. Existing omp is reused.
"$ROOT/setup-omp-cli.sh" --install
STACK_ROOT="${MM_STACK_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/frontend-ai-stack}"
STAMP="$(date +%Y%m%d-%H%M%S)-$$"
BACKUP="$HOME/.frontend-ai-stack-backups/${STAMP}-v3.13.4-omp-delta-cleanup"
mkdir -p "$BACKUP/state" "$HOME/.local/bin"
# All runtime credentials and existing Oh My Pi installations are left untouched.
# The only migrated user files are stack-owned bins, two managed MCP settings and skill links.
snapshot() {
  local path="$1" key="$2"; mkdir -p "$BACKUP/state/$(dirname "$key")"
  if [[ -e "$path" || -L "$path" ]]; then cp -a "$path" "$BACKUP/state/$key";
  else : > "$BACKUP/state/$key.__MISSING__"; fi
}
BINS=(codex-private codex-working claude-private claude-working mm-direct-profile mm-profile-skills-sync mm-skill-precedence-doctor mm-tinycontext-mcp mm-tinycontext-path tinycontext-project tinycontext-doctor mm-project-memory-doctor mm-runtime-update mm-stack-update mm-skill-audit mm-agent-runtime-doctor mm-claude-swap-doctor mm-codex-manual-doctor mm-yolo-doctor yolo-private yolo-working omp-private omp-working mm-stack-audit)
LEGACY=(mm-omp-extension-audit mm-omp-worktree mm-yolo-health mm-yolo-model-sync mm-ponytail-doctor mm-codex-swap-doctor)
# Only managed package assets are backed up. Do not copy working CODEX_HOME
# or other app data/auth tokens into the stack backup.
snapshot "$STACK_ROOT/skills" stack-skills
snapshot "$STACK_ROOT/mcp/private-blender.json" stack-private-blender
snapshot "$HOME/.codex/config.toml" codex-config
snapshot "$HOME/.claude.json" claude-config
# OMP profile config and managed links only: NEVER back up OAuth/token files.
for profile in private working; do
  agent="$HOME/.omp/profiles/$profile/agent"
  for name in config.yml mcp.json .mm-yolo-skill-links.json; do
    snapshot "$agent/$name" "yolo/$profile/$name"
  done
  mkdir -p "$BACKUP/yolo-links/$profile"
  if [[ -d "$agent/skills" ]]; then
    for link in "$agent/skills"/*; do
      [[ -L "$link" ]] && cp -a "$link" "$BACKUP/yolo-links/$profile/" || true
    done
  fi
done
for client in codex claude; do
  dir="$HOME/.$client/skills"
  for f in .mm-managed-package-links-v392.json .mm-managed-profile-links .mm-active-profile; do
    snapshot "$dir/$f" "metadata/$client/$f"
  done
  # Backup only symlinks; do not duplicate or overwrite user-owned skill directories.
  mkdir -p "$BACKUP/links/$client"
  if [[ -d "$dir" ]]; then
    for link in "$dir"/*; do [[ -L "$link" ]] && cp -a "$link" "$BACKUP/links/$client/" || true; done
  fi
done
# Working Codex has its OWN managed skill links/metadata; don't overwrite on rollback.
WORK_SKILLS="${MM_CODEX_WORKING_HOME:-$STACK_ROOT/codex-working-home}/skills"
for file in .mm-managed-package-links-v392.json .mm-managed-profile-links .mm-active-profile; do
  snapshot "$WORK_SKILLS/$file" "metadata/codex-working/$file"
done
mkdir -p "$BACKUP/links/codex-working"
if [[ -d "$WORK_SKILLS" ]]; then
  for link in "$WORK_SKILLS"/*; do
    [[ -L "$link" ]] && cp -a "$link" "$BACKUP/links/codex-working/" || true
  done
fi
for bin in "${BINS[@]}" "${LEGACY[@]}"; do snapshot "$HOME/.local/bin/$bin" "bin/$bin"; done
printf '%s\n' "$BACKUP" > "$HOME/.frontend-ai-stack-last-backup"
# Backup exists before any global MCP migration; keep separate, restrictive
# file backups as well for targeted recovery.
python3 "$ROOT/scripts/migrate_global_blender.py" --apply
python3 "$ROOT/scripts/check_blender_scope.py"
mkdir -p "$STACK_ROOT/skills"
for profile in shared private working omp; do
  mkdir -p "$STACK_ROOT/skills/$profile"
  # Existing canonical package contents are superseded by this package.
  # Backups above allow precise rollback.
  find "$STACK_ROOT/skills/$profile" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
  cp -a "$ROOT/payload/$profile/skills/." "$STACK_ROOT/skills/$profile/"
done
for bin in "${BINS[@]}"; do install -m 0755 "$ROOT/payload/bin/$bin" "$HOME/.local/bin/$bin"; done
# Remove obsolete managed shims only when bytes match the previous release.
# Never uninstall the raw `omp` executable or remove ~/.omp user files.
for bin in "${LEGACY[@]}"; do
  dest="$HOME/.local/bin/$bin"
  [[ -f "$dest" && ! -L "$dest" ]] || continue
  if [[ -f "$ROOT/legacy-hashes.sha256" ]] && grep -q "  $bin$" "$ROOT/legacy-hashes.sha256"; then
    expected="$(awk -v n="$bin" '$2==n {print $1}' "$ROOT/legacy-hashes.sha256")"
    actual="$(sha256sum "$dest" | cut -d' ' -f1)"
    if [[ "$actual" == "$expected" ]]; then rm -f "$dest"; echo "Removed old stack-managed command: $bin"; fi
  fi
done
# Apply skill fallbacks directly to the CLIs. User/repository skills retain precedence.
for client in codex claude; do
  "$HOME/.local/bin/mm-profile-skills-sync" "$client" private --root "$PWD" --quiet
done
# Clean and repopulate Working CODEX_HOME's package links too. Its login stays isolated.
WORK_HOME="${MM_CODEX_WORKING_HOME:-$STACK_ROOT/codex-working-home}"
mkdir -p "$WORK_HOME"
chmod 0700 "$WORK_HOME"
CODEX_HOME="$WORK_HOME" "$HOME/.local/bin/mm-profile-skills-sync" codex working --root "$PWD" --quiet
# Preserve unrelated client config and current auth.json. Only our TinyContext tables are inserted.
if command -v codex >/dev/null 2>&1; then
  python3 "$ROOT/scripts/patch_codex_tinycontext.py" "$HOME/.codex/config.toml" "$HOME/.local/bin/mm-tinycontext-mcp"
else
  echo 'INFO: Codex not installed yet; configure MCP after installing Codex by re-running installer.'
fi
if command -v claude >/dev/null 2>&1; then
  if ! claude mcp get mm-tinycontext >/dev/null 2>&1; then
    claude mcp add mm-tinycontext --scope user "$HOME/.local/bin/mm-tinycontext-mcp" >/dev/null 2>&1 || echo 'WARN: could not register Claude TinyContext MCP.'
  fi
else
  echo 'INFO: Claude Code not installed yet; configure MCP by re-running installer.'
fi
# Register TinySearch/TinyContext globally and Blender in Private overlay only.
# Re-running setup after CLI installation is supported and does not change credentials.
if command -v uvx >/dev/null 2>&1; then
  "$ROOT/setup-global-mcps.sh"
else
  echo 'INFO: uvx missing; MCP registration deferred. Run ./setup-global-mcps.sh after installing uv.'
fi
# Stop only the legacy stack-owned Codex rotation daemon. Never alter token stores.
"$ROOT/setup-codex-manual.sh"
# Two native OMP profile directories with strict discovery isolation.
if command -v uvx >/dev/null 2>&1; then
  "$ROOT/setup-yolo-omp.sh"
else
  echo 'INFO: uvx missing; Yolo OMP setup deferred until uv is installed.'
fi
# Clean up ONLY verified Zed Delta app/CLI, its Claude plugin and its MCP registrations.
# The cleaning helper creates private, recoverable backups and intentionally
# never touches Zed editor binaries or unrelated Delta MCP products.
if ! python3 "$ROOT/scripts/cleanup_zed_delta.py" --apply --backup-dir "$BACKUP/zed-delta"; then
  echo 'WARN: v3.13.4 stack installed, but Zed Delta cleanup needs attention. See docs/ZED_DELTA_REMOVAL.md' >&2
fi
printf '
PASS: v3.13.4 stack files installed. Backup: %s
'  "$BACKUP"
echo 'Important: no credentials were copied, imported, overwritten or exported.'
echo 'NEXT: OMP CLI verified. Run ./setup-omp-completions.sh --install (optional), then omp-working or omp-private and /login yolo-auto.'
echo 'Optional: ./setup-yolo-todo.sh --stage ; review source, activate by SHA256.'
echo 'Codex runs without automatic rotation. Native login separately in each CODEX_HOME if needed.'
echo 'Then: ./verify-profiles.sh'

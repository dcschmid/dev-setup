#!/usr/bin/env bash
set -euo pipefail
# Run manually in a normal shell, never with sudo.
NVM_VERSION="v0.40.8" # latest verified 2026-10-30
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
command_name="${1:---check}"
case "$command_name" in --check|--install-nvm|--install-project) ;; *)
  echo 'Usage: ./setup-node.sh [--check|--install-nvm|--install-project]' >&2; exit 2 ;; esac
[[ "$#" -le 1 ]] || exit 2
[[ "$(id -u)" -ne 0 ]] || { echo 'Do not use sudo/root for NVM' >&2; exit 1; }

source_nvm() {
  [[ -s "$NVM_DIR/nvm.sh" ]] || return 1
  # shellcheck disable=SC1090
  source "$NVM_DIR/nvm.sh"
}

case "$command_name" in
  --install-nvm)
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
      echo "NVM already installed: $NVM_DIR"
    else
      echo "Install official nvm $NVM_VERSION into $NVM_DIR?"
      printf '[y/N] '; read -r answer
      [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]] || { echo 'Cancelled'; exit 0; }
      command -v curl >/dev/null 2>&1 || { echo 'curl missing' >&2; exit 1; }
      # PROFILE=/dev/null stops the upstream script from changing .zshrc;
      # Kitty Workspace already configures the OMZ nvm plugin.
      curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | PROFILE=/dev/null bash
      echo 'Open a new Kitty tab after installation.'
    fi
    ;;
  --install-project)
    source_nvm || { echo 'NVM missing; run ./setup-node.sh --install-nvm first.' >&2; exit 1; }
    repo="$HOME/dev/gitlab/unified-frontend"
    [[ -d "$repo" ]] || { echo "Project checkout missing: $repo" >&2; exit 1; }
    cd "$repo"
    if [[ -f .nvmrc ]]; then
      printf 'Install Node requested by %s/.nvmrc? [y/N] ' "$repo"
      read -r answer
      [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]] || exit 0
      nvm install
    else
      echo 'No .nvmrc present. Inspect package.json engines.node first.'
      echo 'Then use nvm install <version> and optionally add .nvmrc.'
    fi
    ;;
esac

printf '\nNode development check:\n'
if source_nvm; then
  printf 'NVM: installed (%s)\n' "${NVM_DIR}"
  nvm current || true
else echo 'NVM: missing'; fi
for name in node npm pnpm corepack; do
  if command -v "$name" >/dev/null 2>&1; then
    printf 'OK    %-9s %s\n' "$name" "$(command -v "$name")"
  else printf 'MISS  %-9s (not on PATH for this shell)\n' "$name"; fi
done
printf '\nCorepack may need separate installation on newer Node versions.\n'
printf 'See NODE-SETUP.md; do not install global pnpm over existing Corepack shims blindly.\n'

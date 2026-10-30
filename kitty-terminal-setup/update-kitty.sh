#!/usr/bin/env bash
set -euo pipefail

TARGET_VERSION="0.49.2" # verified 2026-10-30; check upstream for newer releases
usage() {
  cat <<'EOF'
Usage: ./update-kitty.sh [--check | --dnf | --official]

  --check     Report installed Kitty version; NO changes (default).
  --dnf       Update Fedora-managed Kitty/kitten via dnf.
  --official  Explicitly install current upstream Kitty into ~/.local/kitty.app.

The official build may take precedence over Fedora's packaged build.
Do not choose --official unless you intend to use that build.
EOF
}
mode="${1:---check}"
case "$mode" in --check|--dnf|--official) ;; *) usage >&2; exit 2 ;; esac
[[ "$#" -le 1 ]] || { usage >&2; exit 2; }

show_versions() {
  printf 'Upstream reference checked: Kitty %s (2026-10-30)\n' "$TARGET_VERSION"
  if command -v kitty >/dev/null 2>&1; then
    printf 'PATH kitty: %s (%s)\n' "$(command -v kitty)" "$(kitty --version 2>&1)"
  else printf 'PATH kitty: not found\n'; fi
  if [[ -x "$HOME/.local/kitty.app/bin/kitty" ]]; then
    printf 'Official local build: %s\n' "$("$HOME/.local/kitty.app/bin/kitty" --version 2>&1)"
  fi
  if command -v rpm >/dev/null 2>&1; then
    rpm -q kitty kitty-kitten 2>/dev/null || true
  fi
}
show_versions
case "$mode" in
  --check) exit 0 ;;
  --dnf)
    command -v dnf >/dev/null 2>&1 || { echo 'dnf is required for --dnf' >&2; exit 1; }
    echo 'Updating Fedora-managed Kitty. This may remain behind upstream.'
    sudo dnf upgrade -y kitty kitty-kitten
    ;;
  --official)
    command -v curl >/dev/null 2>&1 || { echo 'curl is required' >&2; exit 1; }
    echo 'Explicit official Kitty installation selected.'
    printf 'Continue and make ~/.local/kitty.app preferred? [y/N] '
    read -r answer
    [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]] || { echo 'Cancelled'; exit 0; }
    curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
    [[ -x "$HOME/.local/kitty.app/bin/kitty" ]] || { echo 'Installer did not place Kitty in ~/.local/kitty.app' >&2; exit 1; }
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
    ln -sfn "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
    ;;
esac
printf '\nAfter update:\n'
show_versions

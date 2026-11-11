#!/usr/bin/env bash
# Blender MCP is attached only in the Private wrappers, not global user MCP.
# Its Blender addon still needs to be installed into the right Blender profile.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${1:-$PWD}"
[[ -d "$PROJECT" ]] || { echo "ERROR: project not found: $PROJECT" >&2; exit 2; }
command -v uvx >/dev/null || { echo 'ERROR: uvx required.' >&2; exit 1; }
# This helper installs the Blender add-on only; private CLI MCP registration
# is handled separately by ./setup-global-mcps.sh during stack install.
python3 "$ROOT/scripts/migrate_global_blender.py" --apply
python3 "$ROOT/scripts/check_blender_scope.py"
MODE="${MM_BLENDER_INSTALL_MODE:-auto}"
APP="${MM_BLENDER_FLATPAK_APP_ID:-org.blender.Blender}"
VERSION="2.2.7"
ADDON="${MM_BLENDER_INSTALL_ADDON:-1}"
if [[ "$ADDON" != 1 ]]; then
  echo 'INFO: Blender addon step skipped (MM_BLENDER_INSTALL_ADDON=0).'; exit 0
fi
if [[ "$MODE" == auto ]]; then
  if command -v flatpak >/dev/null && flatpak info "$APP" >/dev/null 2>&1; then MODE=flatpak; else MODE=native; fi
fi
case "$MODE" in
  flatpak)
    command -v flatpak >/dev/null && flatpak info "$APP" >/dev/null 2>&1 || { echo 'ERROR: Blender Flatpak missing' >&2; exit 2; }
    detected="$(flatpak info --show-version "$APP" 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+' | head -1 || true)"
    detected="${MM_BLENDER_FLATPAK_VERSION:-$detected}"
    [[ -n "$detected" ]] || { echo 'ERROR: Unknown Blender version; set MM_BLENDER_FLATPAK_VERSION=5.2 (example)' >&2; exit 2; }
    ADDON_DIR="$HOME/.var/app/$APP/config/blender/$detected/scripts/addons"
    mkdir -p "$ADDON_DIR"
    perms="$(flatpak info --show-permissions "$APP" 2>/dev/null || true)"
    if ! grep -Eq 'shared=.*network|network.*;' <<<"$perms"; then
      echo "WARN: Blender Flatpak may require network sharing for localhost: flatpak override --user --share=network $APP"
    fi
    BLENDERMCP_ADDONS_DIR="$ADDON_DIR" uvx --python 3.11 "mcp-for-blender@$VERSION" install-addon
    echo "PASS: Blender add-on version $VERSION installed for Flatpak $APP ($detected)"
    ;;
  native)
    uvx --python 3.11 "mcp-for-blender@$VERSION" install-addon
    echo "PASS: Blender add-on version $VERSION installed using upstream native detection"
    ;;
  *) echo 'ERROR: MM_BLENDER_INSTALL_MODE must be auto, flatpak or native' >&2; exit 2;;
esac
cat <<'HELP'
Restart Blender, enable 'MCP for Blender' in Add-ons, and start its server from the N-panel if necessary.
This helper DOES NOT modify project .mcp.json or .codex/config.toml anymore.
If Riff Racers still has older project-level MCP overrides, see docs/GLOBAL_MCPS.md.
HELP

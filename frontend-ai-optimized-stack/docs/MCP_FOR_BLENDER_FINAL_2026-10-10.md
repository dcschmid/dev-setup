> **Historical document (Oct 10).** This 2.1.9 setup is superseded by v3.12.3: use `mcp-for-blender@2.2.0` only through Private launchers. For current instructions see [MCP profiles](GLOBAL_MCPS.md).

> Archived technical reference from the pre-Fedora stack. Use ../README.md and FEDORA_FRAMEWORK_16.md for current installation instructions.

# MCP for Blender — final integration decision (2026-10-10)

Private GameDev standardizes on **`ahujasid/mcp-for-blender`**. The interim `PatrykIti/blender-ai-mcp` experiment is no longer the active integration.

## Tested target

- Repository: `ahujasid/mcp-for-blender`
- Python package: `mcp-for-blender==2.1.9`
- Blender socket: `127.0.0.1:9876` for the Flatpak path
- MCP key: `blender`
- Safe Mode: `BLENDER_MCP_SAFE_MODE=1`
- Telemetry: `DISABLE_TELEMETRY=true`

The upstream package was renamed from `blender-mcp` to `mcp-for-blender`; the old package name remains a compatibility wrapper, but new configurations should use `mcp-for-blender`.

## Flatpak Blender

The helper prefers the installed `org.blender.Blender` Flatpak when present. It determines Blender's `major.minor` config tree and installs the upstream add-on with:

```bash
BLENDERMCP_ADDONS_DIR="$HOME/.var/app/org.blender.Blender/config/blender/<major.minor>/scripts/addons" \
  uvx --python 3.11 'mcp-for-blender==2.1.9' install-addon
```

This avoids accidentally writing the add-on into the native `~/.config/blender/...` tree.

The helper does not silently change Flatpak permissions. It warns if the Blender Flatpak does not appear to share the network namespace, because the bridge uses a local TCP socket.

## Project-local clients

`setup-private-gamedev-mcp.sh` writes the same project-local Blender server to:

- `.mcp.json` for OMP/Claude-compatible project discovery
- `.codex/config.toml` for Codex

Before writing the canonical `blender` entry, stale `blender`, `mcp-for-blender`, and `blender-ai-mcp` aliases are removed from those project files. Unrelated MCP configuration is preserved.

## Working rules

Use the MCP tools directly. Do not create separate project Blender Python helper scripts as a normal workflow. Inspect the existing scene before editing, prefer small verifiable operations, and validate transforms, dimensions, names, materials, rigs/animations and export state from Blender data rather than relying only on screenshots.

Reference images and viewport renders are useful for visual comparison, but they are not the sole truth layer.

## Security posture

Safe Mode is enabled by default because the server can execute Blender Python through its MCP surface. It is an additional validation layer on that path, not a complete sandbox around Blender. Telemetry is explicitly disabled by the project MCP environment.

The Blender socket stays local (`127.0.0.1:9876`) for the normal Flatpak workflow and should not be exposed to untrusted networks.

## Manual Blender step

After add-on install/update, restart Blender or disable/re-enable **Interface: MCP for Blender** in Preferences. Then open the `MCP for Blender` tab in the 3D View sidebar (`N`) and start the connection/server as required by the installed add-on version.

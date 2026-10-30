> **Update for v3.12.3 (Fedora scoped MCPs):** The following 2.1.9 instructions are legacy reference. Active Blender integration is `mcp-for-blender@2.2.0`, injected only by `claude-private` and `codex-private`. Use `./setup-private-gamedev-mcp.sh` for the add-on; do not register Blender as a user-global MCP. See [MCP profiles](GLOBAL_MCPS.md).

> Archived technical reference from the pre-Fedora stack. Use ../README.md and FEDORA_FRAMEWORK_16.md for current installation instructions.

# Private GameDev runtime

Game-development tooling belongs to the **Private** profile. Working repositories do not inherit Blender/Defold MCPs or GameDev package skills.

## Blender: ahujasid/mcp-for-blender

The preferred Blender integration is **`ahujasid/mcp-for-blender`**, pinned by this release to `mcp-for-blender==2.1.9` for reproducibility.

Configure it project-locally:

```bash
/path/to/package/setup-private-gamedev-mcp.sh /path/to/game-project
```

The helper writes `.mcp.json` and `.codex/config.toml`, preserving unrelated entries. Stale package-managed aliases (`blender`, `mcp-for-blender`, `blender-ai-mcp`) are removed before the canonical `blender` entry is written so parallel Blender bridges are not accidentally active.

### Flatpak Blender

When `org.blender.Blender` is installed, Flatpak mode is selected automatically. The add-on is installed to:

```text
~/.var/app/org.blender.Blender/config/blender/<major.minor>/scripts/addons
```

through upstream's `BLENDERMCP_ADDONS_DIR` override. The project MCP connects to `127.0.0.1:9876`.

Defaults:

```text
mcp-for-blender==2.1.9
BLENDER_MCP_SAFE_MODE=1
DISABLE_TELEMETRY=true
BLENDER_HOST=127.0.0.1   # Flatpak
BLENDER_PORT=9876
```

Safe Mode is a guard on model-authored code sent through the MCP path; it is not a full Blender sandbox.

Useful overrides:

```bash
MM_BLENDER_MCP_VERSION=2.1.9 ./setup-private-gamedev-mcp.sh
MM_BLENDER_INSTALL_ADDON=0 ./setup-private-gamedev-mcp.sh
MM_BLENDER_INSTALL_MODE=flatpak ./setup-private-gamedev-mcp.sh
MM_BLENDER_FLATPAK_VERSION=5.2 ./setup-private-gamedev-mcp.sh
BLENDER_MCP_SAFE_MODE=0 ./setup-private-gamedev-mcp.sh
```

Use direct MCP tools for Blender work and avoid separate project Python helper scripts unless explicitly required. Inspect first, make small verifiable edits, then verify actual Blender state and the export contract. Vision is useful for appearance checks but should not replace deterministic scene inspection.

## Blender -> Defold boundary

Treat Blender data/export and Defold import/runtime configuration as separate ownership layers. Validate scale, axes, names, transforms, materials, UVs, rigs, actions, origins/pivots and export assumptions before export. After import, validate the actual running Defold result and fix the layer that owns the defect.

## Defold

Default Defold automation remains official-first:

- project files and editor scripts
- editor HTTP API/OpenAPI for supported editor operations
- engine/runtime automation for live state/input/screenshots
- Bob for CLI builds, reports, archives and bundles

The third-party Defold community MCP helper remains explicit opt-in and requires a reviewed/built checkout. It is not installed by the default GameDev helper.

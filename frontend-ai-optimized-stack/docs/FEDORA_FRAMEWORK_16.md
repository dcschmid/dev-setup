# Framework Laptop 16 / Fedora Workstation 44 onboarding

## Day 1 - Fedora OS

- Install the official Fedora Workstation 44 x86_64 ISO, verifying the checksums before writing a USB drive.
- Update firmware (from Fedora GNOME Software / fwupdmgr where supported) and the OS (`sudo dnf upgrade --refresh`).
- For the Framework Ryzen AI 9 HX 370 and optional RTX 5070, verify AMD display, external monitors, Wi-Fi and suspend/resume before changing drivers.
- NVIDIA graphics, RPM Fusion, Secure Boot enrollment and hybrid GPU selection are *deliberately outside* this stack. Use official Fedora/Framework guidance after basic hardware QA.
- Fedora Workstation uses GNOME by default. Kitty + Zsh are optional (included in `fedora-prerequisites.sh`).

## Day 1 - CLI stack

Run from the extracted package directory:

```bash
./fedora-prerequisites.sh --apply
curl -fsSL https://claude.ai/install.sh | bash
npm install -g @openai/codex
claude --version
codex --version
./install-profiles.sh
./verify-profiles.sh
```

## Day 2 - Claude rotation, manual Codex, and Yolo-Auto via OMP

**Claude:** Use the account wizard in `claude`, capture the first login with `cswap add`, and add the remaining accounts according to `cswap` help. `setup-claude-swap.sh` installs `cswap` and configures its user service.

**Codex (no automatic rotation):**

```bash
./setup-codex-manual.sh                 # stops only the old stack-owned auto-switch daemon
codex-private                           # normal native Codex CLI, Private Blender MCP
codex-working                           # separate Working CODEX_HOME, no Blender
codex-working login                     # initial Working login, if needed
mm-codex-manual-doctor
```

**YOLO-Auto via OMP (two isolated named profiles):**

```bash
# install-profiles.sh already installs OMP automatically when missing
./setup-omp-cli.sh --check
./setup-yolo-omp.sh --check
omp-working                           # type /login yolo-auto in OMP
omp-private                           # type /login yolo-auto in OMP
mm-yolo-doctor
```

Default model `yolo-auto/qwen3.8-27b`, provided your paid plan authorizes it.
The official YOLO todo-discipline extension is optional, **not installed by default**.
See `docs/YOLO_OMP.md` for profile isolation and safe extension setup.

The new Fedora machine must use fresh logins. Do **not** copy `auth.json`, cookies or refresh tokens from the previous device.

## Riff Racers

- Install Blender from Flathub if desired: `flatpak install flathub org.blender.Blender`.
- Riff Racers uses Defold **1.14.0** with `Fulviuus/defold-mcp v1.0.2` and Blender MCP; use the provided project-local MCP helper *inside the game repository*.
- Keep the official Blender MCP private-only; packaged Blender skills have been removed. YOLO-Auto via OMP is available as a separate agent.

## Global Blender, TinySearch, TinyContext

```bash
./setup-global-mcps.sh
./setup-private-gamedev-mcp.sh  # after Blender is installed, installs the addon
claude mcp list
codex mcp list
```

## Support commands

```bash
./verify-profiles.sh
mm-agent-runtime-doctor
systemctl --user status claude-swap-auto.service
systemctl --user is-active codex-swap-auto.service # should be inactive
mm-codex-manual-doctor
mm-yolo-doctor
./rollback-profiles.sh
```

A pass in our **mock** tests proves local install/rollback mechanics, not that Fedora 44 or the live third-party login API were tested on your laptop.

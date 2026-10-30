# Troubleshooting · Fedora / Zed / Framework 16

## Zed does not start or shows graphics errors

Zed for Linux requires Vulkan 1.3 and desktop portals. Test:

```bash
vulkaninfo --summary                  # if vulkan-tools is installed
nvidia-smi                            # if an NVIDIA driver is used
systemctl --user status xdg-desktop-portal
```

On Fedora with KDE/GNOME/Cinnamon, the xdg-desktop-portal backends **matching the actual desktop session** must be running; do not blindly install a foreign backend. If `vulkaninfo` is missing, `vulkan-tools` is a useful diagnostic package on Fedora (`sudo dnf install vulkan-tools`). Choose the active Vulkan GPU and address driver problems first according to Zed's official Linux guide, not by disabling Secure Boot. Zed installation also requires the FileChooser/OpenURI and Secret/Secrets portals.

## Only the standard font instead of JetBrains Mono

```bash
fc-match 'JetBrains Mono'
```

If no real JetBrains Mono family is installed, simply set `Zed Mono` as the font in the Zed editor or **install** JetBrains Mono yourself from a trusted source. The package contains no fonts.

## Astro/React/TypeScript or Tailwind without autocomplete

Check the extension installation in `zed: extensions`. `Astro` and `Defold` need their extensions; TypeScript/TSX and Tailwind are integrated in Zed or Zed-supported language servers. Open the project root and have `node_modules` / local project dependencies installed. For Astro projects, the extensions/Tailwind configuration is only correct if the respective project actually uses Tailwind. The LSP settings example in `config/settings.json` follows the official Astro guide.

## Prettier changes too many files

By default, only format web languages on save. If your repo needs special Prettier/ESLint/Biome rules, define them **in the repo** and configure `languages.*.formatter` there if needed. Zed's `format_on_save` can be set to `off` per project; Lua and Defold are already on `off`.

## Tasks show "No package.json" or "No script"

The global task finds no suitable local package configuration. Open the right repo or choose a file inside the package. Add the necessary `scripts` under `package.json` for your Next.js/Astro package, or create matching `.zed/tasks.json` tasks in the repo root. In large monorepos, project-local tasks are often more reliable than global ones.

## YOLO/Claude/Codex launchers missing in Zed

`./scripts/check.sh` shows whether they are recognizable in an interactive zsh. Check in a normal Kitty terminal:

```zsh
whence -w claude codex yolo-working yolo-private
```

If the existing OMP stack launcher has a **different name**, adjust the two task names/wrappers accordingly. The Devkit deliberately installs no new YOLO-Auto and creates no untested profiles. For Claude, use the CLI task if you need your cswap rotation; ACP can have its own sessions/logins. Codex is started in the package **without** rotation. If zsh direnv/nvm only initializes in interactive shells, open Zed from a correctly initialized session or adjust the desktop environment variables. Do not write API keys into `settings.json`.

## TinySearch/TinyContext appear twice or are missing

Do not additionally set them up under Zed's own MCP servers if the ACP/CLI agent already loads the server from its native configuration. Zed ACP support for MCP pass-through is agent-dependent. Check the specific agent thread first before adding a second server. The Devkit creates no MCP entries.

## Bob build fails

Set `BOB_JAR` or `~/.config/zed-devkit/bob.path`; `game.project` must be in the current working root. The current official Bob documentation names OpenJDK 25; an older JDK installation may be insufficient. Match the Bob version to the Defold version. The editor build in Defold remains a safe alternative. Do not accidentally start via the task **Defold · Bob Build** in a web repo.

## Backup or rollback blocked

The originals are in `~/.local/share/zed-devkit/backups`. `restore.sh` compares file checksums and protects against later changes. If needed, make your own manual copies first, then restore explicitly with `--force`.

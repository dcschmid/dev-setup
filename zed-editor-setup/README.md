# Zed Framework Devkit 1.1.0

**Fedora 44 / Framework Laptop 16 · Astro · Next.js/React · TypeScript · Defold/Lua · Claude Code · Codex · YOLO-Auto**

A deliberately small and safe Zed setup for everyday development. The package **configures the editor** instead of building a second toolchain or a second agent stack alongside your existing setup. It is **not a full offline installer for Zed or extensions**.

## New in 1.1: Delta as an optional add-on

[**Delta**](https://delta.dev/) is a **separate app from the Zed makers** for agent threads, review, and tracing changes with DeltaDB. It is **not** a Zed extension and is **not** installed automatically with Zed. The new Zed task **Delta · Open collaboration app (optional)** launches the app after a separate installation.

Important for your agents: Delta offers an official Claude Code plugin integration, but currently no confirmed Codex CLI or YOLO-Auto/OMP session synchronization. Delta can run in its own agent harness with a ChatGPT Plus/Pro login and its own API keys. **Claude subscriptions are not automatically a login for the native Delta agent.** There is a free Personal tier; hosted models can incur costs.

The Devkit installs **no Claude plugins** and enables **no automatic repository sync**. When using the Delta plugin, depending on your selection, uncommitted files as well as conversation and tool contents are synchronized to DeltaDB. Work repositories: check approvals/data protection first and start with manual private sessions. Guide: [docs/DELTA.md](docs/DELTA.md).

Install optionally, without touching the existing setup:

```bash
./scripts/install-delta.sh --dry-run
./scripts/install-delta.sh --install
```

## Quick install

```bash
unzip zed-framework-devkit-v1.1.0.zip
cd zed-framework-devkit-v1.1.0
./install.sh --dry-run            # Check what would be written
./install.sh --install-zed        # Installs Zed Stable if zed is still missing, plus the Devkit configuration
./scripts/check.sh                # Diagnostics
```

If Zed is already installed, `./install.sh` alone (without `--install-zed`) is enough. **Do not run with `sudo`.** Alternatively, install Zed manually via [the official Linux guide](https://zed.dev/docs/installation). `--install-zed` downloads the official installation script over HTTPS into a temporary file and executes it; if you want to inspect third-party scripts before running them, install Zed manually beforehand.

**After installation:** restart Zed. Zed fetches the extensions listed in `auto_install_extensions` on its own. `Ctrl+Shift+P` → `task: spawn` opens the ready-made tasks. For Claude and Codex you can additionally run `zed: acp registry` and enable both in the ACP agent panel. API keys and logins stay with the respective agents.

## What gets configured

| Area | Setting |
|---|---|
| Look | Catppuccin Mocha Dark + Catppuccin-Mocha-Icons, JetBrains Mono (if present) |
| Editor | VSCode keybindings, 2 spaces Web, 4 spaces Lua, inlay hints, inline diagnostics, Git Blame |
| Frontend | Astro extension/LSP, native TS/TSX/JS support, Tailwind (incl. Astro classes), HTML/Emmet, SCSS, TOML, Dockerfile |
| Formatting | Save formats Web files; Lua/Defold is **not** reformatted without asking |
| Project tasks | Dev server, build, lint, typecheck/Astro check, test, format check, Bob build and bundles |
| Agents | Claude/Codex via ACP **or** terminal; YOLO-Auto (`yolo-working`/`yolo-private`) via terminal/tasks |
| Safety | Existing Zed configs are merged and backed up beforehand; other tools are left untouched |

No system-wide Node modules, no Ollama, no duplication of TinySearch/TinyContext, no changes to cswap, OMP, Codex, Git, SSH, Kitty, Blender, Defold, or project repositories.

## Architecture of the three agents

**Claude Code:** Available in the Zed agent panel as *Claude Agent* from `zed: acp registry`. For your already `cswap`-managed Claude CLI behavior, start the Zed task **Agent · Claude Code (existing CLI/cswap)** or a terminal thread and type `claude`. **ACP and CLI are not guaranteed to be identical during account rotation**; use the CLI for the previous cswap logic.

**Codex:** As *Codex* from the ACP registry or via **Agent · Codex (direct, no rotation)**. The task deliberately starts only `codex`, without cxswap/codex-switch/account rotation.

**YOLO-Auto:** The Devkit does not install a second OMP or Qwen. The tasks **Agent · YOLO working (OMP)** and **Agent · YOLO private (OMP)** run the **already existing** `yolo-working` and `yolo-private` launchers from the interactive zsh. Prerequisite: the launchers are actually available in your stack under those names. If a launcher has a different name, adjust `scripts/zed-dev` and the Zed tasks accordingly. Alternatively, call your existing launcher manually in a terminal thread.

**MCP/Skills:** TinySearch and TinyContext stay in the existing Claude/Codex/OMP configurations. Zed ACP can additionally provide MCPs depending on the integration; the setup deliberately adds **no** `context_servers` entry to avoid double registration. Blender MCP stays, as you have it set up, only in the private profile. Zed agent profiles and external agent profiles are separate things.

## The daily workflow

1. Open a project: `zed /path/to/repo` (or from within Zed).
2. Open an Astro/Next.js file, wait for Astro/TS LSP initialization. If needed, `Ctrl+Shift+P` → `task: spawn` → `Web · Dev Server`.
3. To check, run `Web · Typecheck / Astro Check`, `Web · Lint`, `Web · Build`.
4. Via `agent: new thread`, select an ACP agent (Claude/Codex), **or** open a terminal thread for your usual CLI tools. For YOLO working/private, use the corresponding Zed tasks.
5. For Riff Racers, open `game.project` as the project; edit Defold scripts via the Defold extension. Build normally in the **Defold editor** or optionally via Bob tasks.

Additionally, there is the optional task **Delta · Open collaboration app**, which exclusively opens the separately installed Delta app.

The Web tasks install **no packages**. They look for `package.json`, choose npm, pnpm, yarn, or bun based on `packageManager`/lockfile, and run **only existing scripts**. In monorepos, the `package.json` closest to the active file is used where possible. If your monorepo needs its own orchestrator, adjust the local task in the repo.

## Sign-in and extensions

- `Ctrl+Shift+P` → `zed: acp registry`: install Claude Agent and Codex and perform their own logins. These two ACP installations cannot meaningfully be authenticated through our shell files.
- `Ctrl+Shift+P` → `zed: extensions`: check whether Catppuccin, Catppuccin Icons, Astro, Defold, and Lua are installed. Extensions are requested at startup via the Zed setting and require network access.
- `Ctrl+K`, then `Ctrl+T`: theme selection. If an extension is still missing, restart Zed or install the extension manually in the store.
- Zed-native AI models or Zed Cloud subscriptions are **not** additionally set up or billed.

## Defold 1.14 and Lua

For Defold, Lua **5.1/LuaJIT** is the smallest common denominator (HTML5 uses Lua 5.1). The Defold extension provides its own language support for Defold file types; the separate Lua extension is intended for generic `.lua` files. The optional template `config/defold.luarc.template.json` can be manually copied into a Defold project as `.luarc.json`, **only if** no project-specific LuaLS configuration exists there yet. Do not copy automatically; existing libraries/diagnostic settings could otherwise be lost.

For Bob tasks you need a suitable `bob.jar` and Java (the current Defold Bob documentation names **OpenJDK 25**). In `~/.config/zed-devkit/bob.path`, the **absolute path** to `bob.jar` can be entered as the only line, e.g.:

```bash
mkdir -p ~/.config/zed-devkit
printf '%s\n' "$HOME/opt/defold/bob.jar" > ~/.config/zed-devkit/bob.path
```

Please adjust this example path to your existing installation. Alternatively, provide `BOB_JAR` as an exported environment variable. With the Defold editor itself you build as usual; Bob is optional. `bundle-html5` produces the HTML5 package and `bundle-linux` the Linux package. Bob invocations deliberately change no project files but produce regular build artifacts.

## Maintenance, updates, and rollback

- **Re-apply the Devkit:** `./install.sh` (idempotent; no further backup is created if the state is unchanged).
- **Update Zed:** With the official script installation, Zed usually manages its updates itself; check the current state in the Zed UI.
- **Update extensions:** Zed updates installed extensions by default at startup.
- **Check status:** `./scripts/check.sh`.
- **Check rollback:** `./restore.sh --dry-run`.
- **Undo the last installation:** `./restore.sh`. The script refuses to restore if you have changed files since installation; only use `./restore.sh --force` after a deliberate check.
- **Backups:** `~/.local/share/zed-devkit/backups/`. Contain **original configuration files** that may hold secrets; the directory is created privately (`0700`), backups (`0600`). Do not upload to public Git repositories.
- **Uninstall Zed:** For the official script installation, `zed --uninstall`; use `./restore.sh` beforehand if needed. The Devkit never removes your existing agent stack.

**Note on existing Zed configs:** `settings.json` and `tasks.json` are read as JSONC (comments and trailing commas supported), **merged** with the desired recommendations, and written as regular JSON. Custom keys and other tasks are preserved, but **comments/original formatting are lost in the new file**. The unchanged original is in the backup. If your Zed configuration is managed via symlinks/dotfiles, the installer deliberately aborts: then transfer the bundled settings manually into the central dotfiles repo.

Further notes: [docs/DELTA.md](docs/DELTA.md), [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md), [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/SOURCES.md](docs/SOURCES.md).

# Architektur und Integrationsgrenzen

```text
Fedora 44 / Framework 16 / Wayland
  ├─ Zed Stable (offizielles Linux-Installationsskript)
  │   ├─ Frontend: Astro Extension; TypeScript/TSX; Tailwind; Emmet
  │   ├─ Spiele: Defold Extension + Lua Extension
  │   ├─ Tasks: ~/.config/zed/tasks.json → ~/.local/bin/zed-dev
  │   ├─ ACP Registry: Claude Agent und Codex (separat in Zed hinzufügen)
  │   └─ Terminal Threads: claude / codex / yolo-working / yolo-private
  └─ Bestehender eigener Stack (NICHT modifiziert)
      ├─ Claude Code + cswap
      ├─ Codex CLI (direkt, ohne cxswap/codex-switch)
      ├─ OMP / YOLO-Auto (working, private)
      │   └─ Qwen-Provider wie bereits separat konfiguriert
      ├─ TinySearch + TinyContext; Blender MCP nur private
      ├─ Node / Corepack / pkg manager / direnv / zsh
      └─ Kitty Workspace Pack / Git Signaturen / Defold 1.14
```

## Wichtige Trennung

**Zed-Agent vs ACP-Agent vs Terminal Thread** sind unterschiedliche Wege und haben keine identischen Konfigurationszuständigkeiten. ACP-Agenten übernehmen gewöhnlich eigene Modellanmeldungen/Tools; Terminal Threads laufen mit der nativen CLI-Konfiguration. Dieses Paket konfiguriert absichtlich **keine** Zed-LLM-Provider, keine Token und keine zusätzlichen Zed-MCP-Server.

Globaler Task im Zed-Editor: `~/.config/zed/tasks.json`. Projektlokale Einstellungen: `.zed/settings.json` und `.zed/tasks.json` im jeweiligen Repo, bei Bedarf **manuell** hinzufügen. Das Paket greift nie in Repos oder Agent-Dotfiles ein.

## Was das Installer-Skript ersetzt

Es schreibt ausschließlich diese Dateien (falls Änderungen nötig sind):

```text
~/.config/zed/settings.json
~/.config/zed/tasks.json
~/.local/bin/zed-dev
```

Vorherige Dateien werden in einem privaten Transaktionsbackup gesichert. Eigene andere Tasks und nicht adressierte `settings`-Schlüssel bleiben erhalten. Es wird **keine** `.zshrc`, kein git config, kein `~/.claude`, `~/.codex`, `~/.pi`, keine systemd-Unit und keine Shell-/Kitty-Konfiguration überschrieben.

## Delta (optional, v1.1)

Delta by Zed Industries is a separate public-beta application. Do not confuse it with the `git-delta` Git pager, and do not represent it as a Zed ACP extension. We only add a Zed task that launches an existing Delta installation and a separate opt-in installer. The Claude Code plugin and repository syncing are entirely opt-in and not installed by this package. Codex and OMP integrations remain separate.

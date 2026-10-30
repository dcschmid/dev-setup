# Zed Framework Devkit 1.1.0

**Fedora 44 / Framework Laptop 16 · Astro · Next.js/React · TypeScript · Defold/Lua · Claude Code · Codex · YOLO-Auto**

Ein bewusst kleines und sicheres Zed-Setup für den täglichen Entwickleralltag. Das Paket **konfiguriert den Editor**, statt eine zweite Toolchain oder einen zweiten Agenten-Stack neben deinem bestehenden Setup aufzubauen. Es ist **kein vollständiger Offline-Installer für Zed oder Extensions**.

## Neu in 1.1: Delta als optionale Ergänzung

[**Delta**](https://delta.dev/) ist eine **separate App der Zed-Macher** für Agent-Threads, Review und das Nachvollziehen von Änderungen mit DeltaDB. Sie ist **nicht** eine Zed-Erweiterung und wird **nicht** automatisch mit Zed installiert. Der neue Zed-Task **Delta · Open collaboration app (optional)** startet die App nach einer gesonderten Installation.

Wichtig für deine Agenten: Delta bietet eine offizielle Claude-Code-Plugin-Integration, aber aktuell keine bestätigte Codex-CLI- oder YOLO-Auto-/OMP-Sitzungssynchronisierung. Delta kann im eigenen Agent-Harness mit ChatGPT-Plus/Pro-Anmeldung und eigenen API-Keys arbeiten. **Claude-Abos sind nicht automatisch ein Login für den nativen Delta-Agenten.** Es gibt einen kostenlosen Personal-Tarif; gehostete Modelle können Kosten verursachen.

Das Devkit installiert **keine Claude-Plugins** und aktiviert **keinen automatischen Repository-Sync**. Bei Nutzung des Delta-Plugins werden je nach Auswahl auch uncommittete Dateien sowie Gesprächs- und Tool-Inhalte in DeltaDB synchronisiert. Berufliche Repos: zuerst Freigaben/Datenschutz prüfen und mit manuellen privaten Sessions beginnen. Anleitung: [docs/DELTA.md](docs/DELTA.md).

Optional installieren, ohne das bestehende Setup anzufassen:

```bash
./scripts/install-delta.sh --dry-run
./scripts/install-delta.sh --install
```

## Schnellinstallation

```bash
unzip zed-framework-devkit-v1.1.0.zip
cd zed-framework-devkit-v1.1.0
./install.sh --dry-run            # Prüfen, was geschrieben würde
./install.sh --install-zed         # Installiert Zed Stable, falls zed noch fehlt, und die Devkit-Konfiguration
./scripts/check.sh                # Diagnose
```

Ist Zed bereits installiert, genügt `./install.sh` (ohne `--install-zed`). **Nicht mit `sudo` ausführen.** Alternativ Zed manuell über [die offizielle Linux-Anleitung](https://zed.dev/docs/installation) installieren. `--install-zed` lädt das offizielle Installationsskript per HTTPS in eine temporäre Datei und führt es aus; wenn du Drittanbieter-Skripte vor Ausführung prüfen willst, installiere Zed vorher manuell.

**Nach der Installation:** Zed neu starten. Zed lädt die in `auto_install_extensions` genannten Extensions selbstständig nach. `Ctrl+Shift+P` → `task: spawn` öffnet die fertigen Tasks. Für Claude und Codex kannst du zusätzlich `zed: acp registry` ausführen und beide im ACP-Agent-Panel aktivieren. Die API-Keys und Logins bleiben bei den jeweiligen Agenten.

## Was eingerichtet wird

| Bereich | Einstellung |
|---|---|
| Look | Catppuccin Mocha Dark + Catppuccin-Mocha-Icons, JetBrains Mono (wenn vorhanden) |
| Editor | VSCode-Tastaturkürzel, 2 Spaces Web, 4 Spaces Lua, Inlay Hints, Inline-Diagnostik, Git Blame |
| Frontend | Astro Extension/LSP, native TS/TSX/JS-Unterstützung, Tailwind (inkl. Astro-Klassen), HTML/Emmet, SCSS, TOML, Dockerfile |
| Formatierung | Speichern formatiert Web-Dateien; Lua/Defold wird **nicht** ungefragt neu formatiert |
| Projekt-Tasks | Dev Server, Build, Lint, Typecheck/Astro Check, Test, Format-Check, Bob Build und Bundles |
| Agenten | Claude/Codex via ACP **oder** Terminal; YOLO-Auto (`yolo-working`/`yolo-private`) via Terminal/Tasks |
| Sicherheit | Bestehende Zed-Configs werden zusammengeführt und vorher gesichert; andere Tools bleiben unangetastet |

Keine systemweiten Node-Module, kein Ollama, keine Duplizierung von TinySearch/TinyContext, keine Änderung an cswap, OMP, Codex, Git, SSH, Kitty, Blender, Defold oder Projekt-Repositories.

## Architektur der drei Agenten

**Claude Code:** Im Zed-Agent-Panel als *Claude Agent* aus `zed: acp registry` nutzbar. Für dein bereits über `cswap` geregeltes Claude-CLI-Verhalten den Zed-Task **Agent · Claude Code (existing CLI/cswap)** oder einen Terminal Thread starten und `claude` eingeben. **ACP und CLI sind nicht garantiert identisch bei Account-Rotation**; für die bisherige cswap-Logik CLI verwenden.

**Codex:** Als *Codex* aus dem ACP-Registry oder über **Agent · Codex (direct, no rotation)**. Der Task startet absichtlich nur `codex`, ohne cxswap/codex-switch/Account-Rotation.

**YOLO-Auto:** Das Devkit installiert weder ein zweites OMP noch Qwen neu. Die Tasks **Agent · YOLO working (OMP)** und **Agent · YOLO private (OMP)** führen die **bereits vorhandenen** `yolo-working` und `yolo-private`-Launcher aus dem interaktiven zsh aus. Voraussetzung: Die Launcher sind in deinem Stack tatsächlich so verfügbar. Falls ein Launcher anders heißt, `scripts/zed-dev` und die Zed-Tasks entsprechend anpassen. Alternativ im Terminal Thread deinen vorhandenen Launcher manuell aufrufen.

**MCP/Skills:** TinySearch und TinyContext bleiben in den bestehenden Claude-/Codex-/OMP-Konfigurationen. Zed-ACP kann MCPs je nach Integration zusätzlich bereitstellen; das Setup fügt absichtlich **keinen** `context_servers`-Eintrag hinzu, um Doppelregistrierung zu vermeiden. Blender MCP bleibt, wie bei dir eingerichtet, nur im privaten Profil. Zed-Agent-Profile und externe Agent-Profile sind getrennte Dinge.

## Der tägliche Ablauf

1. Projekt öffnen: `zed /pfad/zum/repo` (oder aus Zed heraus).
2. Astro/Next.js-Datei öffnen, auf Astro/TS-LSP-Initialisierung warten. Bei Bedarf `Ctrl+Shift+P` → `task: spawn` → `Web · Dev Server`.
3. Zum Prüfen `Web · Typecheck / Astro Check`, `Web · Lint`, `Web · Build`.
4. Über `agent: new thread` einen ACP-Agenten (Claude/Codex) auswählen, **oder** einen Terminal Thread für deine gewohnten CLI-Tools öffnen. Für YOLO working/private die entsprechenden Zed-Tasks verwenden.
5. Bei Riff Racers `game.project` als Projekt öffnen; Defold-Skripte über die Defold-Extension bearbeiten. Builds regulär im **Defold-Editor** oder optional über Bob-Tasks starten.

Zusätzlich existiert der optionale Task **Delta · Open collaboration app**, der ausschließlich die gesondert installierte Delta-App öffnet.

Die Web-Tasks installieren **keine Pakete**. Sie suchen nach `package.json`, wählen anhand von `packageManager`/Lockfile npm, pnpm, yarn oder bun und führen **nur vorhandene Skripte** aus. In Monorepos wird, soweit möglich, das `package.json` nahe der aktiven Datei verwendet. Falls dein Monorepo einen eigenen Orchestrator braucht, passe den lokalen Task im Repo an.

## Anmelden und Erweiterungen

- `Ctrl+Shift+P` → `zed: acp registry`: Claude Agent und Codex installieren und deren eigenen Login durchführen. Diese beiden ACP-Installationen können nicht sinnvoll durch unsere Shell-Dateien authentifiziert werden.
- `Ctrl+Shift+P` → `zed: extensions`: Prüfen, ob Catppuccin, Catppuccin Icons, Astro, Defold und Lua installiert sind. Erweiterungen werden beim Start über die Zed-Einstellung angefordert und benötigen Netzwerkzugang.
- `Ctrl+K`, dann `Ctrl+T`: Theme-Auswahl. Falls eine Erweiterung noch fehlt, Zed neu starten oder die Erweiterung manuell im Store installieren.
- Zed-native KI-Modelle oder Zed-Cloud-Abos werden **nicht** zusätzlich eingerichtet oder gebucht.

## Defold 1.14 und Lua

Für Defold gilt Lua **5.1/LuaJIT** als kleinster gemeinsamer Nenner (HTML5 verwendet Lua 5.1). Die Defold-Extension stellt für Defold-Dateitypen eine eigene Sprachunterstützung bereit; die separate Lua-Erweiterung ist für generische `.lua`-Dateien gedacht. Die optionale Vorlage `config/defold.luarc.template.json` kann manuell als `.luarc.json` in ein Defold-Projekt übernommen werden, **nur falls** dort noch keine projektspezifische LuaLS-Konfiguration existiert. Nicht automatisch kopieren; vorhandene Libraries/Diagnoseeinstellungen könnten sonst verloren gehen.

Für Bob-Tasks benötigst du eine passende `bob.jar` und Java (die aktuelle Defold-Bob-Dokumentation nennt **OpenJDK 25**). In `~/.config/zed-devkit/bob.path` kann der **absolute Pfad** zu `bob.jar` als einzige Zeile eingetragen werden, z. B.:

```bash
mkdir -p ~/.config/zed-devkit
printf '%s\n' "$HOME/opt/defold/bob.jar" > ~/.config/zed-devkit/bob.path
```

Diesen Beispielpfad bitte an deine vorhandene Installation anpassen. Alternativ `BOB_JAR` als exportierte Umgebungsvariable bereitstellen. Mit dem Defold-Editor selbst baust du ganz normal weiter; Bob ist optional. `bundle-html5` erzeugt das HTML5-Paket und `bundle-linux` das Linux-Paket. Bob-Aufrufe ändern keine Projektdateien absichtlich, erzeugen aber reguläre Build-Artefakte.

## Pflege, Updates und Rückkehr

- **Devkit erneut anwenden:** `./install.sh` (idempotent; bei unverändertem Stand entsteht kein weiteres Backup).
- **Zed aktualisieren:** Bei offizieller Skriptinstallation verwaltet Zed seine Updates üblicherweise selbst; den aktuellen Stand in der Zed-Oberfläche prüfen.
- **Extensions aktualisieren:** Zed aktualisiert installierte Extensions standardmäßig beim Start.
- **Status prüfen:** `./scripts/check.sh`.
- **Rollback prüfen:** `./restore.sh --dry-run`.
- **Letzte Installation rückgängig machen:** `./restore.sh`. Das Skript verweigert die Wiederherstellung, wenn du Dateien seit der Installation verändert hast; nur nach bewusster Prüfung `./restore.sh --force` verwenden.
- **Backups:** `~/.local/share/zed-devkit/backups/`. Enthalten **Original-Konfigurationsdateien**, in denen Geheimnisse stehen könnten; Verzeichnis wird privat angelegt (`0700`), Backups (`0600`). Nicht in öffentliche Git-Repos hochladen.
- **Zed deinstallieren:** Für die offizielle Skriptinstallation `zed --uninstall`; vorher gegebenenfalls `./restore.sh` verwenden. Das Devkit entfernt nie deinen bestehenden Agent-Stack.

**Hinweis zu vorhandenen Zed-Configs:** `settings.json` und `tasks.json` werden als JSONC gelesen (Kommentare und überflüssige Kommas unterstützt), mit den gewünschten Empfehlungen **zusammengeführt** und als reguläres JSON geschrieben. Benutzerdefinierte Schlüssel und andere Tasks bleiben erhalten, doch **Kommentare/ursprüngliche Formatierung gehen in der neuen Datei verloren**. Das unveränderte Original liegt im Backup. Falls deine Zed-Konfiguration über Symlinks/Dotfiles verwaltet wird, bricht der Installer absichtlich ab: dann die mitgelieferten Einstellungen manuell in das zentrale Dotfiles-Repo übertragen.

Weitere Hinweise: [docs/DELTA.md](docs/DELTA.md), [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md), [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/SOURCES.md](docs/SOURCES.md).

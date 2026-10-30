# Fehlerbehebung · Fedora / Zed / Framework 16

## Zed startet nicht oder zeigt Grafikfehler

Zed für Linux benötigt Vulkan 1.3 und Desktop-Portals. Teste:

```bash
vulkaninfo --summary                  # falls vulkan-tools installiert
nvidia-smi                            # falls NVIDIA-Treiber genutzt wird
systemctl --user status xdg-desktop-portal
```

Auf Fedora mit KDE/GNOME/Cinnamon müssen die **zur tatsächlichen Desktop-Session passenden** xdg-desktop-portal-Backends laufen; ein fremdes Backend nicht blind dazuinstallieren. Wenn `vulkaninfo` fehlt, ist `vulkan-tools` unter Fedora ein nützliches Diagnosepaket (`sudo dnf install vulkan-tools`). Wähle die aktive Vulkan-GPU und Driver-Probleme zunächst nach Zeds offizieller Linux-Anleitung, nicht durch Abschalten von Secure Boot. Zed-Installation verlangt außerdem FileChooser/OpenURI und Secret/Secrets-Portale.

## Nur Standardschrift statt JetBrains Mono

```bash
fc-match 'JetBrains Mono'
```

Wenn keine echte JetBrains-Mono-Familie installiert ist, im Zed-Editor einfach `Zed Mono` als Schrift setzen oder **selbst** JetBrains Mono aus einer vertrauenswürdigen Quelle installieren. Im Paket liegen keine Fonts.

## Astro/React/TypeScript oder Tailwind ohne Autocomplete

Extension-Installation in `zed: extensions` kontrollieren. `Astro` und `Defold` brauchen ihre Extensions; TypeScript/TSX und Tailwind sind in Zed integriert bzw. von Zed unterstützte Language-Server. Den Projekt-Root öffnen und `node_modules` / lokale Projekt-Dependencies installiert haben. Bei Astro-Projekten stimmen die Erweiterungen/Tailwind-Konfiguration nur, wenn das jeweilige Projekt tatsächlich Tailwind nutzt. Das LSP-Settings-Beispiel in `config/settings.json` folgt der offiziellen Astro-Anleitung.

## Prettier verändert zu viele Dateien

Standardmäßig nur Web-Sprachen beim Speichern formatieren. Wenn dein Repo spezielle Prettier/ESLint/Biome-Regeln braucht, lege sie **im Repo** fest und konfiguriere bei Bedarf `languages.*.formatter` dort. Zed-`format_on_save` kann projektspezifisch auf `off` gestellt werden; Lua und Defold stehen bereits auf `off`.

## Tasks zeigen „No package.json" oder „No script"

Der globale Task findet keine geeignete lokale Package-Konfiguration. Öffne das richtige Repo oder wähle eine Datei innerhalb des Pakets. Füge für dein Next.js-/Astro-Paket nötige `scripts` unter `package.json` hinzu oder erstelle passende `.zed/tasks.json`-Tasks in der Repo-Wurzel. In großen Monorepos sind projektlokale Tasks oft zuverlässiger als globale.

## YOLO/Claude/Codex-Launcher fehlen in Zed

`./scripts/check.sh` zeigt, ob sie in einem interaktiven zsh erkennbar sind. Prüfe im normalen Kitty-Terminal:

```zsh
whence -w claude codex yolo-working yolo-private
```

Wenn der vorhandene OMP-Stack Launcher **anders benennt**, die zwei Task-Namen/Wrapper entsprechend anpassen. Das Devkit installiert absichtlich kein neues YOLO-Auto und erzeugt keine ungetesteten Profile. Für Claude nutze den CLI-Task, wenn du deine cswap-Rotation brauchst; ACP kann eigene Sitzungen/Anmeldungen haben. Codex wird im Paket **ohne** Rotation gestartet. Wenn zsh direnv/nvm erst in interaktiven Shells initialisiert, öffne Zed am besten aus einer korrekt initialisierten Session oder passe die Desktop-Umgebungsvariablen an. Keine API-Schlüssel in `settings.json` schreiben.

## TinySearch/TinyContext erscheinen doppelt oder fehlen

Nicht zusätzlich unter Zeds eigenen MCP-Servern einrichten, wenn der ACP-/CLI-Agent den Server bereits aus seiner nativen Konfiguration lädt. Die Zed-ACP-Unterstützung für MCP-Weitergabe ist agentabhängig. Erst den konkreten Agent-Thread prüfen, bevor ein zweiter Server hinzugefügt wird. Das Devkit erstellt keine MCP-Einträge.

## Bob-Build scheitert

`BOB_JAR` oder `~/.config/zed-devkit/bob.path` setzen; `game.project` muss in der aktuellen Arbeitswurzel liegen. Aktuelle offizielle Bob-Dokumentation nennt OpenJDK 25; eine ältere JDK-Installation kann unzureichend sein. Bob-Version an Defold-Version anpassen. Der Editor-Build in Defold bleibt eine sichere Alternative. Über den Task **Defold · Bob Build** nicht versehentlich in einem Web-Repo starten.

## Backup oder Rollback blockiert

Originale liegen in `~/.local/share/zed-devkit/backups`. `restore.sh` vergleicht Dateiprüfsummen und schützt nachträgliche Änderungen. Bei Bedarf erst eigene manuelle Kopien machen, dann mit `--force` explizit wiederherstellen.

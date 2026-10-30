# Delta by Zed Industries · Integration ins Framework-Devkit

Stand: 30.10.2026. Delta ist eine **eigene** Beta-Anwendung neben dem Zed-Editor. Die Git-CLI `git-delta` (Pager) ist **nicht** dasselbe und belegt möglicherweise bereits den Befehl `delta`.

## Einsatzempfehlung

- **Zed**: täglicher Editor für Astro/Next.js/TypeScript/Defold, Claude/Codex ACP oder CLI, OMP über Terminal.
- **Delta**: Agent-Threads, mehrstufige Änderungen, Reviews mit nachvollziehbarer Historie zwischen Commits, gelegentliche Kollaboration.
- GitHub und GitLab bleiben die Source of Truth. Delta benutzt die vorhandenen Git-Repositories und benötigt für Projekte eine Git-Remote-Verbindung.

## Voraussetzungen

Linux x86_64 mit glibc, Zed-Account sowie Online-Anmeldung bei Delta und Zustimmung zur Delta-Early-Access-Vereinbarung. Delta läuft unter Fedora (Systembibliotheken müssen kompatibel sein). Der kostenlose Personal-Tarif unterstützt eigene API-Keys/externe Agenten, der kostenpflichtige Pro-Tarif gehostete Modelle. Details: https://delta.dev/pricing.

## Sicher installieren (optional)

```bash
./scripts/install-delta.sh --dry-run
./scripts/install-delta.sh --install
./scripts/install-delta.sh --status
```

Der Wrapper lädt das **offizielle** Skript `https://delta.dev/install.sh` per HTTPS in eine temporäre Datei und führt es aus. Bei Bedarf die Quelle vor Ausführung selbst prüfen. Es installiert in `~/.local/delta.app` und verlinkt `~/.local/bin/delta`; der Wrapper überschreibt keine fremde CLI gleichen Namens. Kein `sudo`. Nach der Installation ggf. Kitty/Zed neu starten, damit PATH aktualisiert ist.

Alternativ die App von https://delta.dev/download als Linux-x86_64-Archiv beziehen und die offizielle Installationsanleitung nutzen: https://delta.dev/docs/installation.

Start: `delta` oder der Zed-Task **Delta · Open collaboration app (optional)**. Im Delta-Welcome-Screen anmelden. In Zed und Delta getrennte Arbeitsflächen einplanen, da Delta **nicht** einfach als ACP-Panel innerhalb Zeds läuft.

## Agenten · Was wirklich unterstützt ist

**Claude Code**: offizielles Delta-Plugin zum Sync bestehender Claude-CLI-Sitzungen (Claude Code 2.1.303+ und Delta 0.22.0+). Das Devkit installiert es **nicht** automatisch:

```bash
claude plugin marketplace add zed-industries/delta-claude
claude plugin install delta@zed-industries
```

Neue Claude-Session starten, `/delta` prüfen und bei Bedarf einmal `/delta share` verwenden. **Nicht** `/delta setup` auf automatische Team-Synchronisierung stellen, bevor private/professionelle Datengrenzen geklärt sind. Vor Benutzung mit der vorhandenen `cswap`-Rotation die Plugin-Kompatibilität in einer Testsession prüfen. Plugin-/Claude-Installation dürfen nicht mit dem Devkit-Installer verwechselt werden.

**Codex CLI**: Eine gleichwertige offizielle Delta-Sitzungssynchronisierung ist nicht dokumentiert. Die Delta-App selbst kann OpenAI-Modelle per ChatGPT-Plus/Pro-Anmeldung nutzen (separat vom Codex-CLI-Agenten). Das bedeutet nicht, dass bestehende Codex-Sessions automatisch importiert werden. Codex in Zed über ACP/CLI unverändert lassen.

**YOLO-Auto / OMP**: Die Integration für Pi ist laut Delta-Roadmap/CLI noch in Arbeit, für OMP keine gleichwertige fertige offizielle Integration belegt. Deshalb YOLO-Auto weiter separat in Zed-Terminal-Threads nutzen.

**Lokale Modelle**: Delta kann auf dem Desktop auch kompatible OpenAI-/Anthropic-Endpunkte verbinden; das ist ein eigener Modellanbieter und keine direkte Verbindung zu TinySearch/TinyContext/MCP. MCP-Support steht laut Roadmap noch in Arbeit. Nicht automatisch lokale Endpoints aufsetzen.

## Datenschutz · besonders wichtig für berufliche GitLab-Repositories

Delta ist kein rein lokaler Git-Diff-Viewer. Teilen/Sync kann **uncommittete**, **unstaged** und **untracked** Dateien, Nachrichten, Tool-Inputs/-Outputs und Bilder zu DeltaDB synchronisieren. Git-ignorierte Dateien sind laut Plugin-Doku ausgeschlossen; das ersetzt aber keine Sicherheitsprüfung. Team-Teilen kann Daten allen Organisationsmitgliedern zugänglich machen. Einmal geteilte Sitzungen lassen sich laut Doku nicht einfach auf privat zurückschalten. Am sichersten: zunächst Demo-/Testrepo, manuelles `/delta share`, Sichtbarkeit auf *Just me*, keine `.env`/Zugangsdaten im Verlauf; Firmenpolicy vor Nutzung einhalten.

Der Devkit-Installer **richtet weder das Delta-Plugin noch Sync ein**. Die optionale Delta-App benötigt für Workspaces eine Internetverbindung und einen Account. Wenn du aus Sicherheitsgründen offline bleibst, nutze weiterhin Zed + lokale CLI-Agenten.

## Updates und Fehlerbehebung

```bash
./scripts/install-delta.sh --update  # Delta-App per offizieller CLI aktualisieren
# alternativ:
delta update --check
delta update
```

Wenn `delta` stattdessen `git-delta` ausführt: `type -a delta`, `readlink -f ~/.local/bin/delta` prüfen. Ein vorhandenes Git-Diff-Pager-Binary nicht ungefragt überschreiben. Weitere Details und eine alternative Installation: https://delta.dev/docs/installation.

Quellen: https://delta.dev/docs/installation · https://delta.dev/docs/cli/claude-code · https://delta.dev/docs/agents/models-and-providers · https://delta.dev/pricing · https://delta.dev/roadmap.

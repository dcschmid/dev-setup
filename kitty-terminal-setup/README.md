# Kitty Workspace Pack v1.6.0 — Fedora / Framework 16

Ein bewusst schlankes, lokal betriebenes Kitty-/Zsh-Setup für dein **Framework Laptop 16 mit Fedora 44 (KDE Plasma oder GNOME auf Wayland)**.

## Was beim Start erscheint

Nur beim ersten Start bzw. nach einem bewussten Reset:

```text
Unified Frontend 1    ~/dev/gitlab/unified-frontend
Unified Frontend 2    ~/dev/gitlab/unified-frontend
```

Danach erstellst, schließt und benennst **du** deine Tabs und Fenster. Kitty stellt den jeweils zuletzt gesicherten Zustand wieder her. **Keine alten Melody-Mind-Projektlauncher oder vordefinierten OMP-/DEV-/TEST-Tabs.**

Der sichtbare **Kitty Workspace**-Launcher verwendet `--single-instance --instance-group=kitty-workspace`, damit wiederholte Aufrufe möglichst in derselben Kitty-Instanz landen (neue OS-Fenster sind dabei möglich). Separat gestartete, unabhängige Kitty-Prozesse können weiterhin unterschiedliche Zustände speichern; verwende für diesen Workspace daher denselben Launcher.

Der Zustand enthält Tabs, Titel, Verzeichnisse und Fensterstruktur, **nicht** laufende Shell-Programme (kein automatischer Restart von `pnpm dev`, Claude oder Codex).

## Installation / Upgrade

Entpacken und aus einem normalen Terminal starten:

```bash
unzip kitty-workspace-pack-v1.6.0.zip
cd kitty-workspace-pack-v1.6.0
./install.sh
./shell-doctor.sh
./state-status.py
```

**Empfohlen, wenn du auf Fedora bereits fast alle Tools hast:**

```bash
./install.sh --config-only
```

Der Config-only-Modus verändert die vom Paket verwalteten Einstellungen, installiert aber **keine Software** und führt **keine Upgrades/Downloads** aus. Er lässt vorhandene persönliche Kitty-Zustände unangetastet.

`./install.sh` fragt bei fehlenden Paketen nach, installiert die Basis über `dnf` und aktualisiert Kitty **nicht automatisch**. `--yes` akzeptiert die normalen fehlenden Abhängigkeiten, aber **keine automatische Kitty-Aktualisierung** und kein optionales Lazygit.

## Aktuelle Versionen und Quellen (30. Oktober 2026)

| Komponente | Verifiziert | Verhalten dieses Pakets |
|---|---|---|
| Kitty upstream | **0.49.2** | Überprüfen; kein ungefragtes Update |
| Fedora 44 Kitty RPM | **0.47.1** in der Fedora-Paketübersicht | DNF-Version bleibt Standard, wenn sie installiert ist |
| nvm | **v0.40.8** | Installation **nur auf expliziten Wunsch** |
| Atuin | Fedora 44 in der Paketübersicht: **18.12.1** | Ältere vs. neuere Init-Flags werden berücksichtigt |

Für Kitty:

```bash
./update-kitty.sh --check       # nur Versionsprüfung
./update-kitty.sh --dnf         # explizit Fedora-Pakete aktualisieren
./update-kitty.sh --official    # explizit upstream in ~/.local/kitty.app installieren
```

Die offizielle Installation ist **optional**; Fedora- und Upstream-Binaries sollten nicht unbemerkt vertauscht werden.

## Persistenter Zustand — jetzt mit Sicherungen

- Alle ~10 Sekunden sowie nach relevanten Kitty-Ereignissen wird ein Session-Snapshot angefordert.
- Vor dem Überschreiben prüft das neue Watcher-Skript die erzeugte Session in einer **temporären Datei**. Ein ungültiger Snapshot ersetzt nicht den letzten gültigen.
- Zusätzlich wird der vorherige Zustand ca. alle 15 Minuten gesichert; maximal zwölf rotierende Auto-Backups.
- Der Quick-Access-Kitten benutzt eine **eigene Kitty-Konfigurationsdatei ohne Autosave-Watcher**, damit sein kurzes Terminal den Hauptzustand nicht überschreibt.
- Das Log enthält nur Fehlertypen, keine Session-Inhalte/Kommandos.

```text
~/.config/kitty/last-state.kitty-session
~/.local/state/kitty-workspace-pack/autosave-backups/
~/.local/state/kitty-workspace-pack/autosave-error.log
```

Manuell speichern: `Ctrl+Space, S`.

Status prüfen:

```bash
./state-status.py
```

**Wichtig:** Ein echter Kitty-Test auf deinem Fedora/Wayland-System bleibt nötig; der Watcher wurde hier mit Mocks getestet, nicht live auf deinem Framework. Siehe `PERSISTENT-STATE.md`.

## Entfernte alte Starttabs / Reset

Falls du aus einem alten v1.5-Zustand noch zwei identifizierbare Melody-Mind-Starttabs mitgebracht hast, **Kitty vollständig schließen**, dann:

```bash
./migrate-kitty-state.py
```

Bei unklaren Sessio­nen wird nichts verändert. Der bisherige Zustand wird bei erfolgreicher Migration vorher gesichert.

Wenn du bewusst **alle selbst angelegten Tabs verwerfen** willst, Kitty schließen und:

```bash
./reset-kitty-state.sh
```

Das Script sichert die alte Datei und setzt dann nur auf die beiden Unified-Frontend-Tabs zurück.

## Fehlendes Node / pnpm von deiner letzten Doctor-Ausgabe

Unser Zsh-Profil aktiviert zwar das Oh-My-Zsh-NVM-Plugin, **installiert aber nicht NVM, Node oder pnpm**. Damit `node`, `npm` und `pnpm` nach einem Fedora-Neuaufsetzen wieder funktionieren:

```bash
./setup-node.sh --check
./setup-node.sh --install-nvm       # optional, mit Nachfrage
./setup-node.sh --install-project   # nur bei vorhandener .nvmrc, mit Nachfrage
```

`NODE-SETUP.md` erklärt die Version aus `.nvmrc`, `package.json`, Corepack und pnpm. **Conda, Rust, uv, Claude, Codex, OMP (Oh My Pi) und Lazygit bleiben optional.** Der neue Doctor stellt diese nicht mehr als gleichwertige Fehler dar.

## Enthaltene Funktionen

Kitty Catppuccin Mocha, Powerline-Tabs, JetBrains Mono (optional), Zsh/Oh My Zsh, Git/gitfast, sicherer NVM-`.nvmrc`-Wechsel, fzf, zoxide, direnv, Atuin lokal mit AI-Bindung deaktiviert, eza, bat, delta, optionale lazygit-TUI und sichere Git-Worktree-Helfer. Dazu Kitty `diff`, `icat`, `choose-files`, Quick Access und Benachrichtigungen für lange Hintergrundkommandos.

Die Standard-Shell deines Linux-Accounts wird **nicht** geändert. Das Paket führt keine Agenten automatisch aus.

## Dokumentationswegweiser

- `PERSISTENT-STATE.md`: Autosave, Backups, Test, Migration und Reset
- `NODE-SETUP.md`: NVM, Node, pnpm und Corepack auf Fedora
- `TOOLS-GUIDE.md`: Wichtigste Tools und ihre Funktionsweise
- `KEYBOARD-SHORTCUTS.md`: Alle Tastenkürzel
- `CLI-POLISH-WORKTREES.md`: Git Worktrees, eza, bat, delta, lazygit
- `KITTY-KITTENS.md`, `ZSH-EXTRAS.md`, `VISUAL-QOL.md`: Detailreferenzen
- `CHANGELOG.md`: vollständige Versionshistorie

## Deinstallation

```bash
./uninstall.sh
```

**Bewahrt absichtlich** die persönliche gespeicherte Session, Backups, Secrets, selbst erstellte Sessions, Tools und die bestehende Login-Shell.

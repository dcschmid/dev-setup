# Persistent Kitty State — v1.6.0

Kitty startet mit der Datei `~/.config/kitty/last-state.kitty-session` (bei abweichendem `XDG_CONFIG_HOME` entsprechend dort). **Nur beim ersten Start** wird die Vorlage mit 2× Unified Frontend eingesetzt.

## Was wiederhergestellt wird

Fensterstruktur, Tabs, deren Namen, Arbeitsverzeichnisse und Layoutinformationen, soweit Kitty sie speichert. Bei Wayland bestimmt der Compositor die tatsächliche Platzierung auf dem Monitor; Bildschirmkoordinaten können nicht garantiert werden.

**Nicht** wiederhergestellt: laufende Shell-Prozesse oder Inhalte der interaktiven Shell, Editor-Puffer, laufende Webserver und Coding-Agenten. Diese werden aus Sicherheitsgründen nicht automatisch neu gestartet. `--use-foreground-process` wird nicht verwendet.

## Wie Autosave funktioniert

`watcher state-autosave.py` aktiviert einen globalen Kitty-Watcher. Er veranlasst etwa alle 10 Sekunden und bei Tab-/Fokus-/Titeländerungen einen Save in eine temporäre Datei.

Nur wenn diese eine plausible Session mit `new_tab` und `launch` enthält, ersetzt sie atomar die vorherige `last-state.kitty-session`. Ein Fehler hinterlässt die vorherige Datei und einen generischen Hinweis in:

```text
~/.local/state/kitty-workspace-pack/autosave-error.log
```

Die letzten maximal zwölf zeitlich versetzten Kopien liegen unter:

```text
~/.local/state/kitty-workspace-pack/autosave-backups/
```

Der Quick Access verwendet `quick-access-kitty.conf` ohne Watcher und ohne startup_session. Das vermeidet, dass ein transientes Mini-Terminal die eigentliche Session überschreibt.

## Praktischer Test auf Fedora / Wayland

1. Starte `Kitty Workspace` und öffne einen neuen Testtab mit `Ctrl+Shift+T`.
2. Wechsel in diesem Testtab in ein existierendes Verzeichnis, benenne den Tab um (`Ctrl+Space, N`).
3. Warte mindestens 15 Sekunden und prüfe außerhalb von Kitty mit `./state-status.py` Zeitpunkt und Tabzahl.
4. Schließe Kitty normal und starte `Kitty Workspace` erneut. Prüfe Tabtitel, Tabanzahl und Verzeichnis.
5. Teste getrennt `Ctrl+Space, S` (manueller Save) und das Quick-Access-Terminal. Quick Access darf den Hauptzustand nicht überschreiben.

**Diese Live-Prüfung ist auf deinem Framework notwendig.** Unser automatisierter Watcher-Test ersetzt keine echte Ausführung auf Fedora/KDE-Wayland.

## Reparatur, Migration und Reset

Nie die Live-Session manuell editieren, während Kitty läuft: Der Watcher könnte sie überschreiben.

```bash
./migrate-kitty-state.py    # nur bekannte alte Startertabs entfernen
./reset-kitty-state.sh      # alle gespeicherten Tabs verwerfen; Backup vor Reset
./state-status.py           # lesende Statusprüfung
```

Für den historischen Fehler durch alte Launcher gibt es `repair-v1.5-startup.sh`. Verwende immer den sichtbaren **Kitty Workspace**-Launcher statt älterer `kitty --session melody-mind...`-Starter.

## Mehrere Instanzen

Der Pack-Launcher benutzt `kitty --single-instance --instance-group=kitty-workspace`, damit reguläre neue Fenster zu demselben Kitty-Prozess gehören. Eine anders gestartete, unabhängige Kitty-Instanz mit derselben Config kann trotzdem dieselbe Session-Datei verwenden. Vermeide deshalb parallele unabhängige Instanzen für den persistenten Workspace.

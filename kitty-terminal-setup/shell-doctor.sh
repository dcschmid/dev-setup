#!/usr/bin/env bash
set -uo pipefail

GOOD=0; WARN=0; FAIL=0
ok() { printf 'OK    %s\n' "$*"; GOOD=$((GOOD + 1)); }
note() { printf 'INFO  %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; WARN=$((WARN + 1)); }
fail() { printf 'FAIL  %s\n' "$*"; FAIL=$((FAIL + 1)); }
installed() { command -v "$1" >/dev/null 2>&1; }
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
kw_dir="${XDG_CONFIG_HOME:-$HOME/.config}/kitty-workspace"
managed="$config_dir/local-workspaces.conf"
state="$config_dir/last-state.kitty-session"

printf '\nKitty Workspace Pack v1.6.0 — Fedora/Framework Diagnose\n'
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  note "System: ${PRETTY_NAME:-Linux} / ${XDG_CURRENT_DESKTOP:-Desktop unknown} / ${XDG_SESSION_TYPE:-session unknown}"
fi

printf '\n[1] Kitty und persistenter Zustand\n'
if installed kitty; then
  ok "kitty $(kitty --version 2>/dev/null) ($(command -v kitty))"
else fail 'Kitty nicht im PATH gefunden'; fi
[[ -r "$managed" ]] && ok 'Paketkonfiguration vorhanden' || fail 'Paketkonfiguration fehlt'
if [[ -r "$managed" ]] && grep -Eq '^startup_session[[:space:]]+last-state\.kitty-session$' "$managed"; then
  ok 'Automatische Session-Wiederherstellung konfiguriert'
else fail 'startup_session fehlt'; fi
if [[ -r "$managed" ]] && grep -Eq '^watcher[[:space:]]+state-autosave\.py$' "$managed"; then
  ok 'Autosave-Watcher eingebunden'
else fail 'Watcher nicht eingebunden'; fi
[[ -r "$config_dir/state-autosave.py" ]] && ok 'Watcher-Datei vorhanden' || fail 'Watcher-Datei fehlt'
if [[ -r "$state" ]]; then
  if python3 - "$state" <<'PY'
import sys
p=sys.argv[1]
try:
 lines=[line.strip().split(' ',1)[0] for line in open(p,encoding='utf-8') if line.strip() and not line.lstrip().startswith('#')]
 assert 'new_tab' in lines and 'launch' in lines
except Exception: sys.exit(1)
PY
  then ok 'Gespeicherter Zustand plausibel'; else fail 'Gespeicherter Zustand beschädigt/ungewöhnlich'; fi
else fail 'last-state.kitty-session fehlt'; fi
if [[ -r "$state" ]] && grep -Eqi 'melody-mind' "$state"; then
  warn 'Alter Melody-Mind-Tab in Session: nach Kitty-Ende migrate-kitty-state.py ausführen'
fi
if [[ -r "$config_dir/kitty.conf" ]] && grep -Eq 'melody-mind\.kitty-session|unified-frontend\.kitty-session' "$config_dir/kitty.conf"; then
  fail 'Veralteter Projekt-Launcher in kitty.conf'
fi
if [[ -r "$config_dir/kitty.conf" ]] && grep -Fqx 'include local-workspaces.conf' "$config_dir/kitty.conf"; then
  ok 'Kitty-Config-include aktiv'
else warn 'include local-workspaces.conf nicht in kitty.conf gefunden'; fi
if [[ -r "${XDG_STATE_HOME:-$HOME/.local/state}/kitty-workspace-pack/autosave-error.log" ]]; then
  warn 'Autosave hat Fehler protokolliert — Status im Log prüfen'
else ok 'Keine protokollierten Autosave-Fehler'; fi

printf '\n[2] Zsh, NVM und Projekt-Node\n'
installed zsh && ok "$(zsh --version)" || warn 'Zsh ist nicht installiert'
[[ -r "$kw_dir/zsh/kitty-workspace.zsh" ]] && ok 'Zsh-Profil vorhanden' || warn 'Zsh-Profil fehlt'
[[ -d "$HOME/.oh-my-zsh" ]] && ok 'Oh My Zsh vorhanden' || warn 'Oh My Zsh fehlt'
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  ok 'NVM installiert (~/.nvm/nvm.sh)'
else
  warn 'NVM fehlt — OMZ-nvm-Plugin installiert Node NICHT; ./setup-node.sh --check'
fi
if [[ -r "$HOME/dev/gitlab/unified-frontend/.nvmrc" ]]; then
  note "Unified Frontend .nvmrc: $(head -n 1 "$HOME/dev/gitlab/unified-frontend/.nvmrc")"
else note 'Unified Frontend: keine .nvmrc festgestellt'; fi

if installed zsh; then
  output="$(zsh -ic '
   for c in node npm pnpm corepack; do
     if (( $+commands[$c] || $+functions[$c] )); then
       printf "OK %s\\n" "$c"
     else
       printf "MISSING %s\\n" "$c"
     fi
   done
  ' 2>&1)"
  if [[ "$output" == *'command not found'* || "$output" == *'parse error'* ]]; then
    warn 'Zsh-Start meldet Fehler; bitte zsh -ic exit selbst ausführen'
  fi
  while read -r status cmd; do
    case "$status" in
      OK) ok "In interaktiver Zsh erreichbar: $cmd" ;;
      MISSING) warn "In interaktiver Zsh fehlt: $cmd (siehe NODE-SETUP.md)" ;;
    esac
  done <<< "$output"
else warn 'Node-Check in Zsh übersprungen'; fi

printf '\n[3] CLI-Tools — empfohlen\n'
for c in git fzf zoxide direnv rg fd atuin eza bat delta git-worktree-helper; do
  installed "$c" && ok "$c" || warn "$c fehlt"
done
printf '\n[4] Optionale Werkzeuge — kein Fehler\n'
for c in lazygit conda uv cargo rustup lemonade omp codex claude; do
  installed "$c" && note "$c vorhanden" || note "$c nicht installiert (optional)"
done
note 'omp bezeichnet hier den Coding-Agenten Oh My Pi.'

printf '\n[5] Datenschutz / lokale Konfiguration\n'
if [[ -r "$kw_dir/secrets.zsh" ]]; then
  mode="$(stat -c '%a' "$kw_dir/secrets.zsh" 2>/dev/null || true)"
  [[ "$mode" == '600' ]] && ok 'secrets.zsh: 0600' || warn "secrets.zsh: Datei-Rechte ${mode:-unbekannt}, erwartet 0600"
fi
if installed atuin; then
  note 'Atuin: Ctrl+R lokal, AI sollte explizit deaktiviert bleiben'
fi

printf '\nErgebnis: %d OK · %d Warnungen · %d Fehler\n' "$GOOD" "$WARN" "$FAIL"
[[ "$FAIL" -eq 0 ]]

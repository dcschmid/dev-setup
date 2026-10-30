#!/usr/bin/env bash
set -euo pipefail

PACK_NAME="kitty-workspace-pack"
PACK_VERSION="1.6.0"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

KITTY_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
KITTY_CONFIG="$KITTY_CONFIG_DIR/kitty.conf"
MANAGED_CONFIG="$KITTY_CONFIG_DIR/local-workspaces.conf"
THEME_DIR="$KITTY_CONFIG_DIR/themes"
MANAGED_THEME="$THEME_DIR/catppuccin-mocha.conf"
CHOOSE_FILES_CONF="$KITTY_CONFIG_DIR/choose-files.conf"
QUICK_ACCESS_CONF="$KITTY_CONFIG_DIR/quick-access-terminal.conf"
QUICK_KITTY_CONF="$KITTY_CONFIG_DIR/quick-access-kitty.conf"
AUTOSAVE_WATCHER="$KITTY_CONFIG_DIR/state-autosave.py"
LIVE_STATE="$KITTY_CONFIG_DIR/last-state.kitty-session"

KW_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty-workspace"
KW_ZSH_DIR="$KW_CONFIG_DIR/zsh"
KW_ZSH_CONFIG="$KW_ZSH_DIR/kitty-workspace.zsh"
KW_SECRETS="$KW_CONFIG_DIR/secrets.zsh"
GIT_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/git"
GIT_INCLUDE="$GIT_CONFIG_DIR/kitty-workspace.inc"

SESSION_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/kitty/sessions"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
WORKSPACE_DESKTOP="$APP_DIR/kitty-workspace.desktop"
LOCAL_BIN="$HOME/.local/bin"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/$PACK_NAME"
BACKUP_DIR="$STATE_DIR/backups/$(date +%Y%m%d-%H%M%S)"

OMZ_DIR="$HOME/.oh-my-zsh"
OMZ_CUSTOM="$OMZ_DIR/custom"
OMZ_THEME="$OMZ_CUSTOM/themes/kitty-mocha.zsh-theme"
ZSHRC="$HOME/.zshrc"

INSTALL_KITTY="ask"
UPDATE_KITTY="no"
INSTALL_ZSH="ask"
INSTALL_EXTRAS="ask"
INSTALL_FONT="ask"
INSTALL_CLI_POLISH="ask"
INSTALL_LAZYGIT="ask"
CONFIG_ONLY="no"

usage() {
  cat <<USAGE
Kitty Workspace Pack $PACK_VERSION

Usage: ./install.sh [options]

Options:
  --yes                 Install missing Kitty/Zsh/developer extras.
  --skip-kitty-install  Do not install Kitty if missing.
  --update-kitty        Explicitly update Kitty via the distro package manager.
  --config-only         Install/repair configs without package downloads.
  --skip-zsh            Keep Kitty's existing shell; do not install/configure Zsh.
  --skip-extras         Do not install fzf/zoxide/direnv/ripgrep/fd/Atuin.
  --skip-font           Do not install JetBrains Mono if missing.
  --skip-cli-polish     Do not install eza/bat/delta.
  --with-lazygit        Install optional lazygit.
  --skip-lazygit        Do not ask about lazygit.
  -h, --help            Show this help.

Developer extras:
  fzf, zoxide, direnv, ripgrep, fd, Atuin

Visual extras:
  JetBrains Mono (optional; falls back to monospace)

CLI polish:
  eza, bat, git-delta
  lazygit is optional
  Atuin is configured local-first with auto-sync OFF and AI OFF.
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --yes) INSTALL_KITTY="yes"; INSTALL_ZSH="yes"; INSTALL_EXTRAS="yes"; INSTALL_FONT="yes"; INSTALL_CLI_POLISH="yes"; INSTALL_LAZYGIT="no" ;;
    --skip-kitty-install) INSTALL_KITTY="no" ;;
    --update-kitty) UPDATE_KITTY="yes" ;;
    --config-only) CONFIG_ONLY="yes"; INSTALL_KITTY="no"; UPDATE_KITTY="no"; INSTALL_ZSH="no"; INSTALL_EXTRAS="no"; INSTALL_FONT="no"; INSTALL_CLI_POLISH="no"; INSTALL_LAZYGIT="no" ;;
    --skip-zsh) INSTALL_ZSH="no" ;;
    --skip-extras) INSTALL_EXTRAS="no" ;;
    --skip-font) INSTALL_FONT="no" ;;
    --skip-cli-polish) INSTALL_CLI_POLISH="no" ;;
    --with-lazygit) INSTALL_LAZYGIT="yes" ;;
    --skip-lazygit) INSTALL_LAZYGIT="no" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

say() { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }

backup_if_exists() {
  local src="$1"
  [[ -e "$src" ]] || return 0
  mkdir -p "$BACKUP_DIR"
  local safe
  safe="$(printf '%s' "$src" | sed "s|^$HOME/||; s|/|__|g")"
  cp -a "$src" "$BACKUP_DIR/$safe"
}

ask_yes_no() {
  local prompt="$1"
  local default="${2:-Y}"
  if [[ ! -t 0 ]]; then
    [[ "$default" == "Y" ]]
    return
  fi
  local suffix="[Y/n]"
  [[ "$default" == "N" ]] && suffix="[y/N]"
  printf '%s %s ' "$prompt" "$suffix"
  read -r answer
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

find_kitty() {
  if [[ -x "$HOME/.local/kitty.app/bin/kitty" ]]; then
    printf '%s\n' "$HOME/.local/kitty.app/bin/kitty"
  elif command -v kitty >/dev/null 2>&1; then
    command -v kitty
  else
    return 1
  fi
}

find_kitten() {
  if command -v kitten >/dev/null 2>&1; then
    command -v kitten
  elif [[ -x "$HOME/.local/kitty.app/bin/kitten" ]]; then
    printf '%s\n' "$HOME/.local/kitty.app/bin/kitten"
  else
    return 1
  fi
}

kitty_version() {
  local bin="$1"
  "$bin" --version 2>/dev/null | awk '{print $2; exit}'
}

version_lt() {
  [[ "$1" != "$2" && "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" == "$1" ]]
}

install_kitty() {
  command -v curl >/dev/null 2>&1 || { echo "curl is required." >&2; exit 1; }
  if command -v dnf >/dev/null 2>&1; then
    say "Installing Fedora-managed Kitty"
    sudo dnf install -y kitty kitty-kitten
  else
    say "Installing Kitty from the official upstream Linux installer"
    curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
    mkdir -p "$LOCAL_BIN"
    ln -sfn "$HOME/.local/kitty.app/bin/kitty" "$LOCAL_BIN/kitty"
    ln -sfn "$HOME/.local/kitty.app/bin/kitten" "$LOCAL_BIN/kitten"
  fi
}

install_zsh_package() {
  say "Installing Zsh"
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y zsh
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y zsh
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed zsh
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper --non-interactive install zsh
  else
    echo "Unsupported package manager. Install zsh manually and re-run." >&2
    exit 1
  fi
}

install_system_extras() {
  say "Installing developer extras"

  if command -v dnf >/dev/null 2>&1; then
    local packages=(fzf zoxide direnv ripgrep fd-find atuin)
    for pkg in "${packages[@]}"; do
      sudo dnf install -y "$pkg" || warn "Could not install package: $pkg"
    done
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    local packages=(fzf zoxide direnv ripgrep fd-find)
    for pkg in "${packages[@]}"; do
      sudo apt-get install -y "$pkg" || warn "Could not install package: $pkg"
    done
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed fzf zoxide direnv ripgrep fd
  elif command -v zypper >/dev/null 2>&1; then
    local packages=(fzf zoxide direnv ripgrep fd)
    for pkg in "${packages[@]}"; do
      sudo zypper --non-interactive install "$pkg" || warn "Could not install package: $pkg"
    done
  else
    warn "No supported package manager found for fzf/zoxide/direnv/ripgrep/fd."
  fi

  mkdir -p "$LOCAL_BIN"
  if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    ln -sfn "$(command -v fdfind)" "$LOCAL_BIN/fd"
  fi
}



apt_has_package() {
  command -v apt-cache >/dev/null 2>&1 &&
    apt-cache show "$1" >/dev/null 2>&1
}

ensure_bat_command() {
  mkdir -p "$LOCAL_BIN"
  if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
    ln -sfn "$(command -v batcat)" "$LOCAL_BIN/bat"
  fi
}

cargo_install_if_missing() {
  local cmd="$1"
  local crate="$2"

  command -v "$cmd" >/dev/null 2>&1 && return 0

  if command -v cargo >/dev/null 2>&1; then
    cargo install --locked "$crate" || warn "Cargo install failed: $crate"
  else
    warn "$cmd is missing and Cargo is unavailable."
  fi
}

install_cli_polish() {
  say "Installing CLI polish: eza, bat, delta"

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update

    # bat is available in Ubuntu/Debian repositories.
    sudo apt-get install -y bat || warn "Could not install bat."

    # Some newer Debian/Ubuntu releases package eza directly.
    if apt_has_package eza; then
      sudo apt-get install -y eza || warn "Could not install eza from apt."
    fi

    # git-delta is not consistently packaged by Ubuntu/Debian.
    if apt_has_package git-delta; then
      sudo apt-get install -y git-delta || warn "Could not install git-delta from apt."
    fi
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y eza bat git-delta || warn "Some CLI polish packages failed via dnf."
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed eza bat git-delta
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper --non-interactive install eza bat git-delta || warn "Some CLI polish packages failed via zypper."
  fi

  ensure_bat_command

  # Safe user-local fallback for tools missing from distro repositories.
  cargo_install_if_missing eza eza
  cargo_install_if_missing delta git-delta

  # bat is normally available in distro repos, but Cargo is a final fallback.
  cargo_install_if_missing bat bat
}

find_lazygit() {
  command -v lazygit 2>/dev/null || true
}

install_lazygit_upstream() {
  command -v curl >/dev/null 2>&1 || {
    warn "curl is required for upstream lazygit installation."
    return 0
  }

  local machine arch release_json tag version asset_url checksum_url tmp asset
  machine="$(uname -m)"
  case "$machine" in
    x86_64|amd64) arch="x86_64" ;;
    aarch64|arm64) arch="arm64" ;;
    armv6l|armv7l) arch="armv6" ;;
    *)
      warn "Unsupported architecture for automatic lazygit binary install: $machine"
      return 0
      ;;
  esac

  release_json="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest)" || {
    warn "Could not query lazygit releases."
    return 0
  }

  tag="$(printf '%s' "$release_json" | sed -n 's/.*"tag_name":[[:space:]]*"v\([^"]*\)".*/\1/p' | head -n1)"
  [[ -n "$tag" ]] || {
    warn "Could not determine latest lazygit version."
    return 0
  }

  asset="lazygit_${tag}_linux_${arch}.tar.gz"
  asset_url="$(printf '%s' "$release_json" |
    grep -oE '"browser_download_url":[[:space:]]*"[^"]+"' |
    cut -d'"' -f4 |
    grep -F "/$asset" |
    head -n1 || true)"
  checksum_url="$(printf '%s' "$release_json" |
    grep -oE '"browser_download_url":[[:space:]]*"[^"]+"' |
    cut -d'"' -f4 |
    grep -F '/checksums.txt' |
    head -n1 || true)"

  [[ -n "$asset_url" && -n "$checksum_url" ]] || {
    warn "Could not locate lazygit release asset/checksums."
    return 0
  }

  tmp="$(mktemp -d)"

  curl -fsSL "$asset_url" -o "$tmp/$asset"
  curl -fsSL "$checksum_url" -o "$tmp/checksums.txt"

  (
    cd "$tmp"
    grep -F "  $asset" checksums.txt | sha256sum -c -
  ) || {
    warn "lazygit checksum verification failed."
    rm -rf "$tmp"
    return 0
  }

  tar -xzf "$tmp/$asset" -C "$tmp" lazygit
  install -m 0755 "$tmp/lazygit" "$LOCAL_BIN/lazygit"
  rm -rf "$tmp"
  printf 'Installed lazygit %s to %s\n' "$tag" "$LOCAL_BIN/lazygit"
}

install_lazygit_optional() {
  if command -v lazygit >/dev/null 2>&1; then
    printf 'KEEP lazygit: %s\n' "$(command -v lazygit)"
    return 0
  fi

  say "Installing optional lazygit"

  if command -v apt-get >/dev/null 2>&1 && apt_has_package lazygit; then
    sudo apt-get update
    sudo apt-get install -y lazygit || true
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed lazygit || true
  fi

  command -v lazygit >/dev/null 2>&1 || install_lazygit_upstream
}

configure_delta_git() {
  command -v git >/dev/null 2>&1 || return 0
  command -v delta >/dev/null 2>&1 || return 0

  mkdir -p "$GIT_CONFIG_DIR"
  cp "$SCRIPT_DIR/config/git/kitty-workspace.inc" "$GIT_INCLUDE"

  if ! git config --global --get-all include.path 2>/dev/null | grep -Fxq "$GIT_INCLUDE"; then
    git config --global --add include.path "$GIT_INCLUDE"
  fi
}

font_available() {
  if command -v fc-list >/dev/null 2>&1; then
    fc-list : family 2>/dev/null | grep -qi 'JetBrains Mono'
    return
  fi

  local kitty_bin
  kitty_bin="$(find_kitty 2>/dev/null || true)"
  if [[ -n "$kitty_bin" ]]; then
    "$kitty_bin" +list-fonts 2>/dev/null | grep -qi 'JetBrains Mono'
    return
  fi

  return 1
}

install_jetbrains_mono() {
  if font_available; then
    printf 'KEEP font JetBrains Mono\n'
    return 0
  fi

  say "Installing JetBrains Mono"

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y fonts-jetbrains-mono || {
      warn "Could not install fonts-jetbrains-mono; keeping monospace fallback."
      return 0
    }
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y jetbrains-mono-fonts || {
      warn "Could not install jetbrains-mono-fonts; keeping monospace fallback."
      return 0
    }
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed ttf-jetbrains-mono || {
      warn "Could not install ttf-jetbrains-mono; keeping monospace fallback."
      return 0
    }
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper --non-interactive install jetbrains-mono-fonts || {
      warn "Could not install JetBrains Mono from zypper; keeping monospace fallback."
      return 0
    }
  else
    warn "No supported package manager for JetBrains Mono; keeping monospace fallback."
    return 0
  fi

  command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 || true
}

find_atuin() {
  if command -v atuin >/dev/null 2>&1; then
    command -v atuin
  elif [[ -x "$HOME/.atuin/bin/atuin" ]]; then
    printf '%s\n' "$HOME/.atuin/bin/atuin"
  else
    return 1
  fi
}

install_atuin() {
  if ATUIN_BIN="$(find_atuin 2>/dev/null)"; then
    printf 'KEEP Atuin: %s\n' "$ATUIN_BIN"
    return 0
  fi

  command -v curl >/dev/null 2>&1 || {
    warn "curl missing; skipping Atuin install"
    return 0
  }

  say "Installing Atuin binary"
  # Use Atuin's upstream release installer, not setup.atuin.sh, so this pack
  # retains control of ~/.zshrc and can explicitly disable AI bindings.
  curl --proto '=https' --tlsv1.2 -LsSf \
    https://github.com/atuinsh/atuin/releases/latest/download/atuin-installer.sh | sh

  mkdir -p "$LOCAL_BIN"
  if [[ -x "$HOME/.atuin/bin/atuin" ]]; then
    ln -sfn "$HOME/.atuin/bin/atuin" "$LOCAL_BIN/atuin"
  fi
}

configure_atuin() {
  local atuin_bin
  atuin_bin="$(find_atuin 2>/dev/null || true)"
  [[ -n "$atuin_bin" ]] || {
    warn "Atuin binary not found; skipping Atuin configuration."
    return 0
  }

  say "Configuring Atuin: local-first, Git-workspace-aware, AI OFF"

  # The config command preserves the user's existing config structure.
  "$atuin_bin" config set auto_sync false || true
  "$atuin_bin" config set update_check false || true
  "$atuin_bin" config set workspaces true || true
  "$atuin_bin" config set filter_mode workspace || true
  "$atuin_bin" config set style compact || true
  "$atuin_bin" config set inline_height 20 || true
  "$atuin_bin" config set enter_accept false || true
  "$atuin_bin" config set ai.enabled false || true
}

ensure_oh_my_zsh() {
  command -v git >/dev/null 2>&1 || { echo "git is required for Oh My Zsh." >&2; exit 1; }

  if [[ ! -d "$OMZ_DIR/.git" ]]; then
    if [[ -e "$OMZ_DIR" ]]; then
      warn "$OMZ_DIR exists but is not a Git checkout; leaving it untouched."
    else
      say "Installing Oh My Zsh"
      git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR"
    fi
  else
    say "Oh My Zsh already installed; keeping existing checkout"
  fi

  mkdir -p "$OMZ_CUSTOM/plugins" "$OMZ_CUSTOM/themes"

  local name repo
  while read -r name repo; do
    local dest="$OMZ_CUSTOM/plugins/$name"
    if [[ -d "$dest/.git" ]]; then
      printf 'KEEP plugin %s\n' "$name"
    elif [[ -e "$dest" ]]; then
      warn "Plugin path exists but is not a Git checkout: $dest"
    else
      git clone --depth=1 "$repo" "$dest"
    fi
  done <<'PLUGINS'
zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions
zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
PLUGINS
}

write_workspace_desktop_entry() {
  local kitty_bin="$1"
  cat > "$WORKSPACE_DESKTOP" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Kitty Workspace
Comment=Open the persistent Kitty workspace
Exec=$kitty_bin --single-instance --instance-group=kitty-workspace
Icon=kitty
Terminal=false
Categories=Development;System;TerminalEmulator;
StartupNotify=true
DESKTOP
  chmod 0644 "$WORKSPACE_DESKTOP"
}

remove_known_legacy_session_refs() {
  if [[ -f "$KITTY_CONFIG" ]] &&
     grep -Eq 'melody-mind\.kitty-session|unified-frontend\.kitty-session' "$KITTY_CONFIG"; then
    local tmp
    tmp="$(mktemp)"
    awk '
      /melody-mind\.kitty-session/ {next}
      /unified-frontend\.kitty-session/ {next}
      {print}
    ' "$KITTY_CONFIG" > "$tmp"
    cat "$tmp" > "$KITTY_CONFIG"
    rm -f "$tmp"
    printf 'MIGRATE removed legacy project-session reference(s) from %s\n' "$KITTY_CONFIG"
  fi

  local dir file tmp
  for dir in "$APP_DIR" "${XDG_CONFIG_HOME:-$HOME/.config}/autostart"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r -d '' file; do
      grep -Eq 'melody-mind\.kitty-session|unified-frontend\.kitty-session' "$file" 2>/dev/null || continue
      tmp="$(mktemp)"
      awk -v kitty="$KITTY_BIN" '
        /^Exec=/ && ($0 ~ /melody-mind\.kitty-session/ || $0 ~ /unified-frontend\.kitty-session/) {
          print "Exec=" kitty
          next
        }
        {print}
      ' "$file" > "$tmp"
      cat "$tmp" > "$file"
      rm -f "$tmp"
      printf 'MIGRATE repaired legacy desktop launcher: %s\n' "$file"
    done < <(find "$dir" -maxdepth 1 -type f -name '*.desktop' -print0 2>/dev/null)
  done
}

write_quick_access_desktop_entry() {
  local desktop="$APP_DIR/kitty-quick-access.desktop"
  cat > "$desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Kitty Quick Access
Comment=Toggle Kitty quick access terminal
Exec=$LOCAL_BIN/kitty-quick-access
Icon=utilities-terminal
Terminal=false
Categories=Development;System;TerminalEmulator;
StartupNotify=false
DESKTOP
  chmod 0644 "$desktop"
}

say "Kitty Workspace Pack $PACK_VERSION"

# Kitty
if ! KITTY_BIN="$(find_kitty 2>/dev/null)"; then
  case "$INSTALL_KITTY" in
    yes) install_kitty ;;
    no) warn "Kitty is not installed. Configuration will still be installed." ;;
    ask)
      if ask_yes_no "Kitty was not found. Install it now?" "Y"; then
        install_kitty
      else
        warn "Skipping Kitty installation."
      fi
      ;;
  esac
fi
KITTY_BIN="$(find_kitty 2>/dev/null || true)"

# kitty 0.49.2 is the verified stable upstream release as of 2026-10-30.
# Fedora 44 may ship an older version; never bypass its package manager
# without the user's explicit request.
if [[ -n "$KITTY_BIN" ]]; then
  CURRENT_KITTY_VERSION="$(kitty_version "$KITTY_BIN")"
  if [[ -n "$CURRENT_KITTY_VERSION" ]] && version_lt "$CURRENT_KITTY_VERSION" "0.49.2"; then
    DO_UPDATE="no"
    if [[ "$UPDATE_KITTY" == "yes" ]]; then
      DO_UPDATE="yes"
    fi
    if [[ "$DO_UPDATE" == "yes" ]]; then
      "$SCRIPT_DIR/update-kitty.sh" --dnf
      KITTY_BIN="$(find_kitty 2>/dev/null || true)"
    fi
  fi
fi

# Font
CONFIGURE_FONT="no"
if font_available; then
  CONFIGURE_FONT="yes"
elif [[ "$INSTALL_FONT" == "yes" ]]; then
  install_jetbrains_mono
  font_available && CONFIGURE_FONT="yes" || true
elif [[ "$INSTALL_FONT" == "ask" ]] && ask_yes_no "JetBrains Mono was not found. Install it for Kitty?" "Y"; then
  install_jetbrains_mono
  font_available && CONFIGURE_FONT="yes" || true
fi

# Zsh
CONFIGURE_ZSH="no"
if command -v zsh >/dev/null 2>&1; then
  CONFIGURE_ZSH="yes"
elif [[ "$INSTALL_ZSH" == "yes" ]]; then
  install_zsh_package
  CONFIGURE_ZSH="yes"
elif [[ "$INSTALL_ZSH" == "ask" ]] && ask_yes_no "Zsh is missing. Install Zsh + Oh My Zsh now?" "Y"; then
  install_zsh_package
  CONFIGURE_ZSH="yes"
else
  warn "Zsh setup skipped. Kitty will keep its current shell."
fi

# Extras
CONFIGURE_EXTRAS="no"
case "$INSTALL_EXTRAS" in
  yes) CONFIGURE_EXTRAS="yes" ;;
  no) CONFIGURE_EXTRAS="no" ;;
  ask)
    if ask_yes_no "Install developer extras (fzf, zoxide, direnv, ripgrep, fd, Atuin)?" "Y"; then
      CONFIGURE_EXTRAS="yes"
    fi
    ;;
esac

if [[ "$CONFIGURE_EXTRAS" == "yes" ]]; then
  install_system_extras
  install_atuin
  configure_atuin
fi

# CLI polish
CONFIGURE_CLI_POLISH="no"
case "$INSTALL_CLI_POLISH" in
  yes) CONFIGURE_CLI_POLISH="yes" ;;
  no) CONFIGURE_CLI_POLISH="no" ;;
  ask)
    if ask_yes_no "Install CLI polish (eza, bat, delta)?" "Y"; then
      CONFIGURE_CLI_POLISH="yes"
    fi
    ;;
esac

if [[ "$CONFIGURE_CLI_POLISH" == "yes" ]]; then
  install_cli_polish
fi

# Lazygit stays optional by default.
CONFIGURE_LAZYGIT="no"
case "$INSTALL_LAZYGIT" in
  yes) CONFIGURE_LAZYGIT="yes" ;;
  no) CONFIGURE_LAZYGIT="no" ;;
  ask)
    if ask_yes_no "Install optional lazygit TUI?" "N"; then
      CONFIGURE_LAZYGIT="yes"
    fi
    ;;
esac

if [[ "$CONFIGURE_LAZYGIT" == "yes" ]]; then
  install_lazygit_optional
fi

# Backups
say "Backing up files that this pack may replace"
for f in \
  "$KITTY_CONFIG" "$MANAGED_CONFIG" "$MANAGED_THEME" \
  "$CHOOSE_FILES_CONF" "$QUICK_ACCESS_CONF" "$QUICK_KITTY_CONF" "$AUTOSAVE_WATCHER" "$LIVE_STATE" \
  "$SESSION_DIR/melody-mind.kitty-session" \
  "$SESSION_DIR/unified-frontend.kitty-session" \
  "$APP_DIR/kitty-melody-mind.desktop" \
  "$APP_DIR/kitty-unified-frontend.desktop" \
  "$APP_DIR/kitty-quick-access.desktop" \
  "$WORKSPACE_DESKTOP" \
  "$LOCAL_BIN/kitty-quick-access" \
  "$LOCAL_BIN/git-worktree-helper" \
  "$GIT_INCLUDE" \
  "$HOME/.gitconfig" \
  "$ZSHRC" "$KW_ZSH_CONFIG" "$OMZ_THEME"
do
  backup_if_exists "$f"
done

mkdir -p "$KITTY_CONFIG_DIR" "$THEME_DIR" "$SESSION_DIR" "$APP_DIR" "$STATE_DIR" "$LOCAL_BIN" "$GIT_CONFIG_DIR"

# Kitty config
say "Installing Kitty configuration"
cp "$SCRIPT_DIR/config/local-workspaces.conf" "$MANAGED_CONFIG"
cp "$SCRIPT_DIR/config/themes/catppuccin-mocha.conf" "$MANAGED_THEME"
cp "$SCRIPT_DIR/config/choose-files.conf" "$CHOOSE_FILES_CONF"
cp "$SCRIPT_DIR/config/quick-access-terminal.conf" "$QUICK_ACCESS_CONF"
cp "$SCRIPT_DIR/config/quick-access-kitty.conf" "$QUICK_KITTY_CONF"
install -m 0755 "$SCRIPT_DIR/kitty-quick-access" "$LOCAL_BIN/kitty-quick-access"
install -m 0755 "$SCRIPT_DIR/git-worktree-helper" "$LOCAL_BIN/git-worktree-helper"
cp "$SCRIPT_DIR/config/state-autosave.py" "$AUTOSAVE_WATCHER"
# Manual save and watcher must always target the same XDG-aware file.
# Use an absolute path and escape the replacement for sed.
python3 - "$MANAGED_CONFIG" "$LIVE_STATE" <<'PYSAVE'
import pathlib, sys
conf, state = map(pathlib.Path, sys.argv[1:])
conf.write_text(conf.read_text().replace('__KITTY_LAST_STATE__', str(state)))
PYSAVE

# The live state belongs to the user. Create it only on first install/reset;
# never overwrite an existing state during upgrades.
if [[ ! -f "$LIVE_STATE" ]]; then
  cp "$SCRIPT_DIR/state/default-state.kitty-session" "$LIVE_STATE"
  if [[ ! -d "$HOME/dev/gitlab/unified-frontend" ]]; then
    warn "Unified Frontend checkout was not found; new tabs will start in HOME until you clone the repo."
    sed -i 's|^cd ~/dev/gitlab/unified-frontend$|cd ~|' "$LIVE_STATE"
  fi
fi

# Do not rewrite an existing user-maintained state during an upgrade.
# A one-time opt-in migration removes only the two verified obsolete tabs.
if [[ -f "$LIVE_STATE" ]] && grep -Eq 'Melody Mind|melody-mind' "$LIVE_STATE"; then
  warn "Saved Kitty state still contains old Melody Mind tabs. Close Kitty and run: $SCRIPT_DIR/migrate-kitty-state.py"
fi

# Retire the two old pack-managed project session files. Custom sessions stay.
rm -f "$SESSION_DIR/melody-mind.kitty-session" "$SESSION_DIR/unified-frontend.kitty-session"

# Repair known v1.4-era references before installing compatibility desktop IDs.
remove_known_legacy_session_refs

if [[ "$CONFIGURE_FONT" == "yes" ]]; then
  sed -i 's|^# __KITTY_WORKSPACE_FONT__$|font_family JetBrains Mono|' "$MANAGED_CONFIG"
else
  sed -i 's|^# __KITTY_WORKSPACE_FONT__$|font_family monospace|' "$MANAGED_CONFIG"
fi

if [[ "$CONFIGURE_ZSH" == "yes" ]]; then
  ZSH_BIN="$(command -v zsh)"
  sed -i "s|^# __KITTY_WORKSPACE_ZSH_SHELL__$|shell $ZSH_BIN|" "$MANAGED_CONFIG"
  sed -i "s|^# __KITTY_WORKSPACE_QUICK_ZSH_SHELL__$|shell $ZSH_BIN|" "$QUICK_KITTY_CONF"
fi

if [[ ! -f "$KITTY_CONFIG" ]]; then
  cat > "$KITTY_CONFIG" <<'CONFIG'
# Main Kitty configuration
include local-workspaces.conf
CONFIG
elif ! grep -Fqx 'include local-workspaces.conf' "$KITTY_CONFIG"; then
  printf '\n# Kitty Workspace Pack\ninclude local-workspaces.conf\n' >> "$KITTY_CONFIG"
fi

# Zsh + OMZ
if [[ "$CONFIGURE_ZSH" == "yes" ]]; then
  if [[ "$CONFIG_ONLY" == "yes" ]]; then
    if [[ ! -d "$OMZ_DIR" ]]; then
      warn "Config-only: Oh My Zsh fehlt, kein Download. Installiere es bei Bedarf separat."
    fi
  else
    ensure_oh_my_zsh
  fi

  say "Installing managed Zsh configuration"
  mkdir -p "$KW_ZSH_DIR" "$OMZ_CUSTOM/themes"
  cp "$SCRIPT_DIR/config/zsh/kitty-workspace.zsh" "$KW_ZSH_CONFIG"
  cp "$SCRIPT_DIR/config/zsh/themes/kitty-mocha.zsh-theme" "$OMZ_THEME"

  if [[ ! -f "$KW_SECRETS" ]]; then
    cp "$SCRIPT_DIR/config/zsh/secrets.zsh.example" "$KW_SECRETS"
    chmod 0600 "$KW_SECRETS"
  else
    chmod 0600 "$KW_SECRETS" 2>/dev/null || true
  fi

  if [[ ! -f "$ZSHRC" ]]; then
    cat > "$ZSHRC" <<'ZSHRC'
# Kitty Workspace Pack — managed Zsh entry point
source "${XDG_CONFIG_HOME:-$HOME/.config}/kitty-workspace/zsh/kitty-workspace.zsh"
ZSHRC
  elif ! grep -Fq 'kitty-workspace/zsh/kitty-workspace.zsh' "$ZSHRC"; then
    cat >> "$ZSHRC" <<'ZSHRC'

# Kitty Workspace Pack
source "${XDG_CONFIG_HOME:-$HOME/.config}/kitty-workspace/zsh/kitty-workspace.zsh"
ZSHRC
  fi
fi

# Git / delta
if command -v delta >/dev/null 2>&1; then
  configure_delta_git
fi

# Desktop launchers
if [[ -n "$KITTY_BIN" ]]; then
  say "Installing desktop launchers"
  write_workspace_desktop_entry "$KITTY_BIN"
  rm -f "$APP_DIR/kitty-melody-mind.desktop" "$APP_DIR/kitty-unified-frontend.desktop"
  write_quick_access_desktop_entry
  command -v update-desktop-database >/dev/null 2>&1 && \
    update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi

cat > "$STATE_DIR/install-info" <<INFO
version=$PACK_VERSION
installed_at=$(date -Iseconds)
backup_dir=$BACKUP_DIR
managed_config=$MANAGED_CONFIG
managed_zsh=$KW_ZSH_CONFIG
configured_zsh=$CONFIGURE_ZSH
configured_extras=$CONFIGURE_EXTRAS
configured_font=$CONFIGURE_FONT
configured_cli_polish=$CONFIGURE_CLI_POLISH
configured_lazygit=$CONFIGURE_LAZYGIT
session_dir=$SESSION_DIR
live_state=$LIVE_STATE
autosave_interval=10s
INFO

say "Checking baseline tab directories"
for path in "$HOME/dev/gitlab/unified-frontend"; do
  [[ -d "$path" ]] && printf 'OK   %s\n' "$path" || warn "Baseline directory not found: $path"
done

printf '\nInstallation complete.\n'
[[ -n "$KITTY_BIN" ]] && "$KITTY_BIN" --version 2>/dev/null || true
[[ "$CONFIGURE_ZSH" == "yes" ]] && printf 'Zsh: %s\n' "$(zsh --version)"

if [[ "$CONFIGURE_EXTRAS" == "yes" ]]; then
  printf '\nDeveloper extras:\n'
  for cmd in fzf zoxide direnv rg fd atuin; do
    if command -v "$cmd" >/dev/null 2>&1; then
      printf '  OK   %-8s %s\n' "$cmd" "$(command -v "$cmd")"
    elif [[ "$cmd" == "atuin" && -x "$HOME/.atuin/bin/atuin" ]]; then
      printf '  OK   atuin    %s\n' "$HOME/.atuin/bin/atuin"
    else
      printf '  MISS %s\n' "$cmd"
    fi
  done
fi

printf '\nCLI polish:\n'
for cmd in eza bat delta lazygit git-worktree-helper; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '  OK   %-20s %s\n' "$cmd" "$(command -v "$cmd")"
  else
    printf '  MISS %s\n' "$cmd"
  fi
done
printf '  Worktrees: gwl / gwnew / gwcd / gwrm / gwprune\n'
printf '  Lazygit: optional alias lg when installed\n'

printf '\nVisual / QoL behavior:\n'
if [[ "$CONFIGURE_FONT" == "yes" ]]; then
  printf '  Font: JetBrains Mono\n'
else
  printf '  Font: monospace fallback\n'
fi
printf '  Mouse hides while typing\n'
printf '  Long invisible commands: desktop notification after 20s\n'
printf '  Scrollback pager history: 16 MB\n'
printf '  Ctrl+Space then H: browse full scrollback\n'
printf '  Powerline tabs: round\n'

printf '\nDesktop launcher migration:\n'
printf '  Use: Kitty Workspace\n'
printf '  Retired project launchers removed; pin Kitty Workspace in GNOME\n'
printf '  Known legacy --session references are removed on upgrade\n'

printf '\nPersistent Kitty state:\n'
printf '  Initial baseline: 2x Unified Frontend; all extra tabs are user-created\n'
printf '  Autosave: every ~10 seconds + important events + confirmed quit\n'
printf '  Restore: automatic via startup_session\n'
printf '  Foreground commands: NOT replayed on restore\n'
printf '  Manual save: Ctrl+Space then S\n'
printf '  Reset helper: %s/reset-kitty-state.sh\n' "$SCRIPT_DIR"

printf '\nNVM behavior:\n'
printf '  Project .nvmrc auto-switch ON\n'
printf '  Missing Node versions are NOT installed automatically\n'
printf '  Leaving an .nvmrc project returns to NVM default\n'
printf '  Helper: %s/ensure-nvmrc.sh\n' "$SCRIPT_DIR"

printf '\nAtuin behavior:\n'
printf '  Ctrl+R = Atuin history search\n'
printf '  Up Arrow = normal Zsh history\n'
printf '  Workspace history mode enabled in Git repos\n'
printf '  Auto-sync OFF\n'
printf '  AI OFF (config + key binding)\n'

printf '\nKitty extras:\n'
printf '  Ctrl+Space then E  Choose file\n'
printf '  Ctrl+Space then D  Choose directory\n'
printf '  Ctrl+Space then Q  Toggle quick access terminal\n'
printf '  kd                   Kitty side-by-side diff\n'
printf '  img                  Show image in Kitty\n'
printf '  hg                   Hyperlinked ripgrep\n'
printf '  kssh                 Kitty SSH helper\n'

printf '\nGlobal quick terminal:\n'
printf '  Bind this command in your desktop settings, e.g. to Super+`:\n'
printf '  %s/kitty-quick-access\n' "$LOCAL_BIN"

if [[ "$CONFIGURE_ZSH" == "yes" ]]; then
  printf '\nRun the shell doctor:\n  %s/shell-doctor.sh\n' "$SCRIPT_DIR"
fi

printf '\nExisting shell history is NOT imported automatically.\n'
printf 'Optional import:\n  %s/import-history-to-atuin.sh\n' "$SCRIPT_DIR"

if [[ -d "$BACKUP_DIR" ]]; then
  printf '\nBackup: %s\n' "$BACKUP_DIR"
fi

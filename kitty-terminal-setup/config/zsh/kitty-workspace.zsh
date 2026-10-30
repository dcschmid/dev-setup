# ============================================================
# Kitty Workspace Pack - managed Zsh configuration
# v1.6.0 — Fedora developer shell
# ============================================================

# Only configure interactive shells.
[[ -o interactive ]] || return

# ------------------------------------------------------------
# Core Oh My Zsh
# ------------------------------------------------------------

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

ZSH_THEME="kitty-mocha"

# Keep user-set Kitty tab titles stable.
DISABLE_AUTO_TITLE="true"

# Friendly completion without aggressive autocorrection.
ENABLE_CORRECTION="false"
COMPLETION_WAITING_DOTS="true"
HYPHEN_INSENSITIVE="true"

# ------------------------------------------------------------
# PATH migration
# ------------------------------------------------------------

export PNPM_HOME="$HOME/.local/share/pnpm"
export NVM_DIR="$HOME/.nvm"

typeset -U path PATH

path=(
  "$HOME/.atuin/bin"
  "$HOME/.bun/bin"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/.onwatch"
  "$HOME/.opencode/bin"
  "$PNPM_HOME"
  $path
)
export PATH

# ------------------------------------------------------------
# NVM
# ------------------------------------------------------------

# Reliable automatic project Node selection.
# NVM lazy mode is intentionally NOT enabled so NVM is available immediately.
#
# We intentionally do NOT enable Oh My Zsh's native `autoload` option here:
# its current implementation runs `nvm install` when an .nvmrc version is
# missing. The safe hook below switches installed versions automatically but
# never downloads Node merely because you changed directory.

# ------------------------------------------------------------
# fzf
# ------------------------------------------------------------

# Catppuccin-Mocha-ish fzf styling. Atuin is initialized AFTER Oh My Zsh,
# so Ctrl+R belongs to Atuin while fzf keeps Ctrl+T and Alt+C.
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
  --height=40% \
  --layout=reverse \
  --border=rounded \
  --info=inline \
  --pointer='❯' \
  --marker='✓' \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

# ------------------------------------------------------------
# Plugins
# ------------------------------------------------------------

# Core plugins are always enabled.
plugins=(
  git
  gitfast
  aliases
  nvm

  sudo
  extract
  colored-man-pages
  dirhistory
  history-substring-search
)

# Enable optional plugins only when their binaries are installed.
(( $+commands[fzf] )) && plugins+=(fzf zsh-interactive-cd)
(( $+commands[zoxide] )) && plugins+=(zoxide)
(( $+commands[direnv] )) && plugins+=(direnv)

# External plugin installed by the pack.
plugins+=(zsh-autosuggestions)

# zsh-syntax-highlighting is sourced manually at the VERY END of this file,
# after Atuin and every other widget/hook has been initialized.

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  print -P "%F{red}Oh My Zsh not found at $ZSH%f"
fi

# ------------------------------------------------------------
# NVM project safety / default restore
# ------------------------------------------------------------

# NVM is a separate installation. Oh My Zsh supplies the plugin, not the
# ~/.nvm/nvm.sh executable; diagnose missing NVM in shell-doctor.sh.
autoload -U add-zsh-hook

_kitty_find_nvmrc() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -r "$dir/.nvmrc" ]]; then
      print -r -- "$dir/.nvmrc"
      return 0
    fi
    dir="${dir:h}"
  done
  return 1
}

_kitty_nvm_project_check() {
  (( $+functions[nvm] )) || return 0

  local nvmrc_path=""
  nvmrc_path="$(_kitty_find_nvmrc 2>/dev/null || true)"

  if [[ -n "$nvmrc_path" ]]; then
    local requested resolved current
    requested="$(<"$nvmrc_path")"
    requested="${requested//$'\n'/}"
    resolved="$(nvm version "$requested" 2>/dev/null || true)"
    current="$(nvm current 2>/dev/null || true)"

    if [[ "$resolved" == "N/A" ]]; then
      if [[ "${_KITTY_LAST_MISSING_NVMRC:-}" != "$nvmrc_path" ]]; then
        print -P "%F{yellow}Node version from ${nvmrc_path:t} is not installed: ${requested}%f"
        print -P "%F{yellow}Run: nvm install%f"
        _KITTY_LAST_MISSING_NVMRC="$nvmrc_path"
      fi
      _KITTY_LAST_NVMRC="$nvmrc_path"
      return 0
    fi

    unset _KITTY_LAST_MISSING_NVMRC

    if [[ -n "$resolved" && "$resolved" != "$current" ]]; then
      nvm use --silent "$requested" >/dev/null 2>&1 || true
    fi

    _KITTY_LAST_NVMRC="$nvmrc_path"
    return 0
  fi

  if [[ -n "${_KITTY_LAST_NVMRC:-}" ]]; then
    local default_version current
    default_version="$(nvm version default 2>/dev/null || true)"
    current="$(nvm current 2>/dev/null || true)"
    if [[ -n "$default_version" && "$default_version" != "N/A" && "$default_version" != "$current" ]]; then
      nvm use --silent default >/dev/null 2>&1 || true
    fi
    unset _KITTY_LAST_NVMRC
    unset _KITTY_LAST_MISSING_NVMRC
  fi
}

add-zsh-hook chpwd _kitty_nvm_project_check
_kitty_nvm_project_check

# ------------------------------------------------------------
# History
# ------------------------------------------------------------

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=20000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# ------------------------------------------------------------
# Familiar aliases migrated from Bash
# ------------------------------------------------------------

# Prefer eza when available, with GNU ls as a safe fallback.
if (( $+commands[eza] )); then
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza -lah --git --icons=auto --group-directories-first'
  alias la='eza -a --icons=auto --group-directories-first'
  alias l='eza -F --icons=auto --group-directories-first'
  alias tree='eza --tree --level=2 --icons=auto --group-directories-first'
  alias tree3='eza --tree --level=3 --icons=auto --group-directories-first'
else
  alias ls='ls --color=auto'
  alias ll='ls -alF --color=auto'
  alias la='ls -A --color=auto'
  alias l='ls -CF --color=auto'
fi

# Keep cat untouched. `b` is the explicit syntax-highlighted viewer.
if (( $+commands[bat] )); then
  alias b='bat'
  alias bp='bat --paging=always'
fi

# Lazygit is intentionally optional.
if (( $+commands[lazygit] )); then
  alias lg='lazygit'
fi

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Kitty kittens / developer helpers.
alias kd='kitten diff'
alias img='kitten icat'
alias kfiles='kitten choose-files'
alias kdir='kitten choose-files --mode=dir'
alias hg='kitten hyperlinked-grep'
alias kssh='kitten ssh'
alias ktransfer='kitten transfer'

# Native Kitty hyperlinks for modern ripgrep versions.
if (( $+commands[rg] )) && command rg --help 2>/dev/null | command grep -q -- '--hyperlink-format'; then
  alias rg='rg --hyperlink-format=kitty'
fi

# Optional desktop notification helper.
alert() {
  local exit_status=$?
  local icon="terminal"
  (( exit_status != 0 )) && icon="error"

  local last_cmd
  last_cmd="$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')"
  command -v notify-send >/dev/null 2>&1 && \
    notify-send --urgency=low -i "$icon" "${last_cmd:-Command finished}"
}

# ------------------------------------------------------------
# Git worktree helpers
# ------------------------------------------------------------

alias gwl='git worktree list'
alias gwprune='git-worktree-helper prune'

# Create a worktree and immediately enter it.
# Usage:
#   gwnew feature/my-branch
#   gwnew hotfix/main main
gwnew() {
  local target
  target="$(git-worktree-helper new "$@")" || return
  builtin cd -- "$target"
}

# Fuzzy-select an existing worktree and enter it.
gwcd() {
  local target
  target="$(git-worktree-helper choose)" || return
  builtin cd -- "$target"
}

# Safely remove a linked worktree.
# Dirty worktrees and the main/current worktree are refused.
gwrm() {
  git-worktree-helper remove "$@"
}

# ------------------------------------------------------------
# Conda / Miniconda migration
# ------------------------------------------------------------

export CONDA_CHANGEPS1=false

if [[ -x "$HOME/miniconda3/bin/conda" ]]; then
  __conda_setup="$("$HOME/miniconda3/bin/conda" shell.zsh hook 2>/dev/null)"
  if [[ $? -eq 0 ]]; then
    eval "$__conda_setup"
  elif [[ -r "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
  else
    path=("$HOME/miniconda3/bin" $path)
    export PATH
  fi
  unset __conda_setup
fi

# ------------------------------------------------------------
# Shared secrets
# ------------------------------------------------------------

KITTY_WORKSPACE_SECRETS="${XDG_CONFIG_HOME:-$HOME/.config}/kitty-workspace/secrets.zsh"
if [[ -r "$KITTY_WORKSPACE_SECRETS" ]]; then
  source "$KITTY_WORKSPACE_SECRETS"
fi
unset KITTY_WORKSPACE_SECRETS

# ------------------------------------------------------------
# Atuin — local-first history, AI OFF
# ------------------------------------------------------------

if (( $+commands[atuin] )); then
  # Fedora 44 packages can predate Atuin's AI flags. In the current Atuin
  # release we disable AI explicitly; older releases have no AI keybinding.
  if atuin init zsh --help 2>/dev/null | command grep -q -- '--disable-ai'; then
    eval "$(atuin init zsh --disable-up-arrow --disable-ai)"
  else
    eval "$(atuin init zsh --disable-up-arrow)"
  fi
fi

# ------------------------------------------------------------
# Syntax highlighting MUST be last
# ------------------------------------------------------------

_KW_ZSH_HIGHLIGHT="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
if [[ -r "$_KW_ZSH_HIGHLIGHT" ]]; then
  source "$_KW_ZSH_HIGHLIGHT"
fi
unset _KW_ZSH_HIGHLIGHT

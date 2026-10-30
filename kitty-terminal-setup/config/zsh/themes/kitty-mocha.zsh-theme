# Kitty Workspace Pack - Kitty Mocha
# Compact one-line prompt designed for Catppuccin Mocha in Kitty.

setopt PROMPT_SUBST

# Approximate Catppuccin Mocha accents in the 256-color palette.
_KW_BLUE=110
_KW_MAUVE=141
_KW_GREEN=114
_KW_RED=203
_KW_TEAL=116
_KW_TEXT=252

ZSH_THEME_GIT_PROMPT_PREFIX="%F{${_KW_MAUVE}} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_DIRTY="%F{${_KW_RED}} ✗%f"
ZSH_THEME_GIT_PROMPT_CLEAN="%F{${_KW_GREEN}} ✓%f"

kitty_workspace_conda_info() {
  [[ -n "${CONDA_DEFAULT_ENV:-}" ]] || return 0
  print -n "%F{${_KW_TEAL}}[${CONDA_DEFAULT_ENV}]%f "
}

# Show a non-zero exit code only when something failed.
kitty_workspace_exit_info() {
  local code=$?
  (( code == 0 )) && return 0
  print -n "%F{${_KW_RED}}[${code}]%f "
}

# Compact laptop prompt:
# ~/dev/project   branch ✓ [conda] ❯
PROMPT='%F{${_KW_BLUE}}%~%f $(git_prompt_info) $(kitty_workspace_conda_info)%F{${_KW_MAUVE}}❯%f '

# Keep the right side empty on a 14-inch display.
RPROMPT=''

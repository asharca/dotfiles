#!/usr/bin/env zsh
# History Configuration

HISTFILE="${HOME}/.zsh_history"
HISTSIZE=1000000
SAVEHIST=$HISTSIZE
HISTORY_IGNORE="(ls|cd|pwd|exit|date)"

# History Options
setopt BANG_HIST
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Never persist common credential assignments or GitHub token-shaped values.
# Leading-space suppression still works via HIST_IGNORE_SPACE for one-off cases.
autoload -Uz add-zsh-hook
_history_reject_secrets() {
  emulate -L zsh
  setopt localoptions nocasematch

  if [[ "$1" =~ '(^|[[:space:]])(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*(token|secret|password|api_key)[A-Za-z0-9_]*=' ]] ||
     [[ "$1" =~ '(gh[pousr]_|github_pat_)[A-Za-z0-9_]+' ]]; then
    return 1
  fi
  return 0
}
add-zsh-hook zshaddhistory _history_reject_secrets

# History search configuration
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

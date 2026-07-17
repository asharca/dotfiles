#!/usr/bin/env zsh
# History Configuration

HISTFILE="${HOME}/.zsh_history"
HISTSIZE=100000
SAVEHIST=50000
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
setopt SHARE_HISTORY
unsetopt INC_APPEND_HISTORY INC_APPEND_HISTORY_TIME

# Never persist literal credentials from assignments, headers, or common CLI forms.
# Leading-space suppression still works via HIST_IGNORE_SPACE for one-off cases.
autoload -Uz add-zsh-hook
_history_reject_secrets() {
  emulate -L zsh
  setopt localoptions nocasematch

  if [[ "$1" =~ '(^|[[:space:];|&()])(export[[:space:]]+|env[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)?(token|secret|password|passwd|passphrase|api_?key|access_?key|private_?key|client_?secret|auth_?key|jwt)(_[A-Za-z0-9_]+)?[[:space:]]*=' ]] ||
     [[ "$1" =~ '(^|[[:space:];|&()])(export[[:space:]]+|env[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*_)?pass(_[A-Za-z0-9_]+)?[[:space:]]*=' ]] ||
     [[ "$1" =~ '(^|[[:space:]])--(api[-_]?key|access[-_]?key|auth[-_]?token|client[-_]?secret|password|passwd|secret|token)(=|[[:space:]]+)[^[:space:]]+' ]] ||
     [[ "$1" =~ 'authorization[[:space:]]*:[=]?[[:space:]]*[^[:alnum:]]?(bearer|basic|token)[[:space:]]+[A-Za-z0-9._~+/=-]{8,}' ]] ||
     [[ "$1" =~ '(x-api-key|api-key|x-auth-token)[[:space:]]*:[=]?[[:space:]]*[^[:alnum:]]?[A-Za-z0-9._~+/=-]{8,}' ]] ||
     [[ "$1" =~ '(gh[pousr]_[A-Za-z0-9_]{16,}|github_pat_[A-Za-z0-9_]{16,}|(AKIA|ASIA)[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{20,}|sk-(proj-)?[A-Za-z0-9_-]{20,})' ]]; then
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
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

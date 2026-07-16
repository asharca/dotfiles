#!/usr/bin/env zsh
# FZF Configuration

if (( $+commands[fzf] )) && [[ -t 0 && -t 1 ]]; then
  # Use the installed fzf's native zsh integration. The old ~/.fzf.zsh file
  # contains a path from another user account, so it is intentionally ignored.
  source <(fzf --zsh)

  if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude ".git" --exclude "node_modules" . --color=always'
    export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude ".git" --exclude "node_modules" . --color=always'
  else
    export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/\.git/*" -not -path "*/node_modules/*"'
    export FZF_ALT_C_COMMAND='find . -type d -not -path "*/\.git/*" -not -path "*/node_modules/*"'
  fi

  export FZF_DEFAULT_OPTS='--ansi --height 40% --layout=reverse --border'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_OPTS="--preview 'ls -lah {}' --preview-window=right:50%"
elif ! (( $+commands[fzf] )) && [[ -o interactive ]]; then
  print -u2 -- "zsh: optional fzf integration skipped (fzf is unavailable)."
fi

# Keybindings:
# CTRL+R: Search command history
# CTRL+T: Search for files
# ALT+C: CD into selected directory
# **<TAB>: Fuzzy completion

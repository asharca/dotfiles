#!/usr/bin/env zsh
# File Operation Aliases

# Safer defaults with confirmations
# alias rm='echo "This is not the command you are looking for. Use tp or trash-put instead."; false'
alias cp='cp -i'
alias mv='mv -i'

# Optional tools are loaded only when already installed.
if (( $+commands[trash-put] )); then
  alias tp='trash-put'
elif [[ -o interactive ]]; then
  print -u2 -- "zsh: optional command 'trash-put' unavailable; 'tp' was not defined."
fi

(( $+commands[bat] )) && alias cat='bat'

# Modern ls alternatives
if (( $+commands[eza] )); then
  # Use eza if available (modern ls replacement)
  alias ls='eza --color=always --icons --group'
  alias ll='eza --color=always --icons --group -lh'
  alias la='eza --color=always --icons --group -lha'
  alias lt='eza --color=always --icons --group --tree'
else
  # Fallback to standard ls
  if [[ "$OSTYPE" == darwin* ]]; then
    alias ls='ls -G -F'
    alias ll='ls -G -lh'
    alias la='ls -G -lha'
  else
    alias ls='ls --color=auto -F'
    alias ll='ls --color=auto -lh'
    alias la='ls --color=auto -lha'
  fi
fi
alias lsd='ls -d */'

# Grep and diff with colors
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias diff='diff --color=auto'

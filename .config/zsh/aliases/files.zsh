#!/usr/bin/env zsh
# File Operation Aliases

# Safer defaults with confirmations
alias rm='echo "This is not the command you are looking for. Use tp or trash-put instead."; false'
alias cp='cp -i'
alias mv='mv -i'

# Trash-cli setup (安全的删除替代方案)
if ! (( $+commands[trash-put] )); then
  if (( $+commands[uv] )); then
    echo "Installing trash-cli via uv..."
    uv tool install trash-cli
  elif (( $+commands[brew] )); then
    echo "Installing trash-cli via Homebrew..."
    brew install trash-cli
  elif (( $+commands[pip3] )); then
    echo "Installing trash-cli via pip..."
    pip3 install --user trash-cli
  fi
fi

alias tp='trash-put'
alias tl='trash-list'
alias tr='trash-restore'
alias te='trash-empty'

# Modern ls alternatives
if (( $+commands[eza] )); then
  # Use eza if available (modern ls replacement)
  alias ls='eza --color=always --icons --group'
  alias ll='eza --color=always --icons --group -lh'
  alias la='eza --color=always --icons --group -lha'
  alias lt='eza --color=always --icons --group --tree'
else
  # Fallback to standard ls
  alias ls='ls --color=auto -F'
  alias ll='ls --color=auto -lh'
  alias la='ls --color=auto -lha'
fi
alias lsd='ls -d */'

# Grep and diff with colors
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias diff='diff --color=auto'

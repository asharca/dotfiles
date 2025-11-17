#!/usr/bin/env zsh
# Editor Configuration

if (( $+commands[nvim] )); then
  export EDITOR='nvim'
  export VISUAL='nvim'
  export MANPAGER='nvim +Man!'
elif (( $+commands[vim] )); then
  export EDITOR='vim'
  export VISUAL='vim'
  export MANPAGER='vim -M +MANPAGER -'
else
  export EDITOR='nano'
  export VISUAL='nano'
fi

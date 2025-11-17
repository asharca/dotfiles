#!/usr/bin/env zsh
# Docker Configuration

# Docker completions
if [[ -d "$HOME/.docker/completions" ]]; then
  fpath=("$HOME/.docker/completions" $fpath)
fi

# Laravel Sail alias
alias sail='bash vendor/bin/sail'

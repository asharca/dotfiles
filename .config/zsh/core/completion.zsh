#!/usr/bin/env zsh
# Completion System

zmodload zsh/complist

typeset -gU fpath FPATH

autoload -Uz compinit
# zplug initializes completion when available. Fall back here only when no
# earlier component has initialized `_comps`, keeping one compinit pass.
if (( ! ${+_comps} )); then
  # 只在需要时重新生成补全缓存（每24小时一次）
  if [[ -n ${HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
  else
    compinit -C
  fi
fi

# The dotfiles helper is a function (for safe quoting), so explicitly reuse
# Git's completion service instead of relying on alias expansion.
(( ${+functions[config]} )) && compdef _git config

zstyle :compinstall filename "${HOME}/.zshrc"

# Completion formatting
zstyle ':completion:*:descriptions' format '%U%B%d%b%u'
zstyle ':completion:*:warnings' format '%BSorry, no matches for: %d%b'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Completion behavior
zstyle ':completion:*' menu select
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${HOME}/.zsh/cache"
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
zstyle ':completion:*' rehash true

# Application-specific completions
zstyle ':completion:*:pacman:*' force-list always
zstyle ':completion:*:*:pacman:*' menu yes select
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:*:killall:*' menu yes select
zstyle ':completion:*:killall:*' force-list always
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:processes' command 'ps -au$USER'
zstyle ':completion:*:*:*:*:processes' menu yes select

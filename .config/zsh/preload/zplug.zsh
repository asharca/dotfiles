#!/usr/bin/env zsh
# Plugin Manager - zplug

# Load zplug only when it is already installed. Shell startup must not mutate
# the machine or pause for installation input.
if [[ -r "$HOME/.zplug/init.zsh" ]]; then
  # zplug otherwise runs an early compinit merely to discover its own
  # completion, then runs compinit again after loading plugin fpaths.
  if [[ -r "$HOME/.zplug/misc/completions/_zplug" ]]; then
    fpath=("$HOME/.zplug/misc/completions" $fpath)
    autoload -Uz _zplug
  fi

  source "$HOME/.zplug/init.zsh"
  
  # 插件列表
  zplug 'dracula/zsh', as:theme
  zplug 'zsh-users/zsh-completions'
  zplug 'supercrabtree/k'
  zplug 'MichaelAquilina/zsh-you-should-use'
  # zplug "marlonrichert/zsh-autocomplete"
  # fzf-tab must load after compinit and before plugins that wrap ZLE widgets.
  zplug "Aloxaf/fzf-tab", defer:2
  # zplug "jeffreytse/zsh-vi-mode"
  zplug 'zsh-users/zsh-autosuggestions', defer:3
  zplug 'zsh-users/zsh-syntax-highlighting', defer:3

  if [[ "${ZDOTFILES_BOOTSTRAP:-0}" == "1" ]]; then
    if ! zplug check; then
      print -- "Installing declared zplug plugins..."
      zplug install || return 1
    fi
    zplug check || return 1
  else
    zplug load
  fi
elif [[ -o interactive ]]; then
  print -u2 -- "zsh: optional zplug plugins skipped; run the dotfiles bootstrap to install zplug."
fi

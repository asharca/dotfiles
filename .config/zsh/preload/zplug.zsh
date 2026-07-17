#!/usr/bin/env zsh
# Bootstrap-only plugin declarations. Interactive startup uses plugins.zsh and
# never sources zplug itself.

if [[ "${ZDOTFILES_BOOTSTRAP:-0}" != "1" ]]; then
  return 0
fi

if [[ ! -r "$HOME/.zplug/init.zsh" ]]; then
  print -u2 -- "zsh bootstrap: zplug is not installed at $HOME/.zplug"
  return 1
fi

# Prevent zplug from running compinit merely to discover its own completion.
if [[ -r "$HOME/.zplug/misc/completions/_zplug" ]]; then
  fpath=("$HOME/.zplug/misc/completions" $fpath)
  autoload -Uz _zplug
fi

source "$HOME/.zplug/init.zsh"

zplug 'dracula/zsh', as:theme, use:'dracula.zsh-theme'
zplug 'zsh-users/zsh-completions', use:'zsh-completions.plugin.zsh'
zplug 'supercrabtree/k', use:'k.sh'
zplug 'MichaelAquilina/zsh-you-should-use', use:'you-should-use.plugin.zsh'
zplug 'Aloxaf/fzf-tab', use:'fzf-tab.plugin.zsh'
zplug 'zsh-users/zsh-autosuggestions', use:'zsh-autosuggestions.plugin.zsh'
zplug 'zsh-users/zsh-syntax-highlighting', use:'zsh-syntax-highlighting.plugin.zsh'

if ! zplug check; then
  print -- "Installing declared zplug plugins..."
  zplug install || return 1
fi

zplug check || return 1

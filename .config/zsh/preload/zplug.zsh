#!/usr/bin/env zsh
# Plugin Manager - zplug

# zplug 安装检查
if [[ ! -f ~/.zplug/init.zsh ]]; then
  echo "Installing zplug..."
  curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
fi

# 加载 zplug
if [[ -f ~/.zplug/init.zsh ]]; then
  source ~/.zplug/init.zsh
  
  # 插件列表
  zplug 'dracula/zsh', as:theme
  zplug 'zsh-users/zsh-autosuggestions'
  zplug 'zsh-users/zsh-syntax-highlighting', defer:2
  zplug 'zsh-users/zsh-completions'
  zplug 'zsh-users/zsh-history-substring-search'
  zplug 'supercrabtree/k'
  zplug 'MichaelAquilina/zsh-you-should-use'
  zplug 'junegunn/fzf'
  
  # 检查并安装缺失的插件
  if ! zplug check; then
    printf "Install missing plugins? [y/n]: "
    if read -q; then
      echo
      zplug install
    fi
  fi
  
  zplug load
else
  echo "Warning: zplug installation failed. Please restart your shell." >&2
fi

#!/usr/bin/env zsh
# FZF Configuration

# 安装 fzf（如果不存在）
if [[ ! -f ~/.fzf.zsh ]]; then
  if (( $+commands[brew] )); then
    echo "Installing fzf via Homebrew..."
    brew install fzf
    $(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc
  else
    echo "Installing fzf from source..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --key-bindings --completion --no-update-rc
  fi
fi

# 加载 fzf
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# FZF 配置
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

# Keybindings:
# CTRL+R: Search command history
# CTRL+T: Search for files
# ALT+C: CD into selected directory
# **<TAB>: Fuzzy completion

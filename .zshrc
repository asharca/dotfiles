#------------------------------------------------------------------#
# File:     .zshrc   ZSH resource file                             #
# Author: artibix                                          #
#------------------------------------------------------------------#
# zmodload zsh/zprof
# zmodload zsh/datetime
# starttime=$EPOCHREALTIME
#------------------------------
# ZSH Core Configuration
#------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if ! command -v python3 &>/dev/null; then
    echo -e "${YELLOW}正在尝试自动安装Python3, nvim${NC}"

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case $ID in
            debian|ubuntu)
                echo -e "${YELLOW}检测到 Debian/Ubuntu，使用 apt 安装 Python 3...${NC}"
                sudo apt update && sudo apt install -y python3 python3-pip nvim
                ;;
            fedora)
                echo -e "${YELLOW}检测到 Fedora，使用 dnf 安装 Python 3...${NC}"
                sudo dnf install -y python3 python3-pip nvim
                ;;
            centos|rhel)
                echo -e "${YELLOW}检测到 CentOS/RHEL，使用 yum 安装 Python 3...${NC}"
                sudo yum install -y python3 python3-pip nvim
                ;;
            arch)
                echo -e "${YELLOW}检测到 Arch Linux，使用 pacman 安装 Python 3...${NC}"
                sudo pacman -Syu --noconfirm python python-pip nvim
                ;;
            *)
                echo -e "${RED}无法识别的 Linux 发行版，无法自动安装 Python 3。${NC}"
                exit 1
                ;;
        esac
    else
        echo -e "${RED}无法检测到 Linux 发行版，无法自动安装 Python3, nvim。${NC}"
        exit 1
    fi

    if command -v python3 &>/dev/null; then
    else
        echo -e "${RED}安装失败，请检查网络或权限。${NC}"
        exit 1
    fi
fi

# History Configuration
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=1000000                          # Increased for better history retention
SAVEHIST=$HISTSIZE                        # Match HISTSIZE
HISTORY_IGNORE="(ls|cd|pwd|exit|date)"    # Commands to ignore in history

# History Options
setopt BANG_HIST                  # Treat the '!' character specially during expansion
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history
setopt HIST_FIND_NO_DUPS         # Do not display duplicates during searches
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate
setopt HIST_IGNORE_DUPS          # Don't record if same as previous command
setopt HIST_IGNORE_SPACE         # Don't record starting with a space
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry
setopt HIST_SAVE_NO_DUPS        # Don't write duplicate entries in the history file
setopt HIST_VERIFY              # Don't execute immediately upon history expansion
setopt INC_APPEND_HISTORY       # Write to the history file immediately, not when the shell exits
setopt SHARE_HISTORY            # Share history between all sessions

# History search configuration
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

#------------------------------
# Plugins and Theme Management
#------------------------------

# zplug setup
if [[ -f ~/.zplug/init.zsh ]]; then
  source ~/.zplug/init.zsh
else
  echo "Installing zplug..."
  curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
  source ~/.zplug/init.zsh
fi

# Load theme and plugins
zplug 'dracula/zsh', as:theme                     # Dracula theme
zplug 'zsh-users/zsh-autosuggestions'             # Fish-like autosuggestions
zplug 'zsh-users/zsh-syntax-highlighting', defer:2 # Syntax highlighting
zplug 'zsh-users/zsh-completions'                 # Extra completion definitions
zplug 'zsh-users/zsh-history-substring-search'    # History search with up/down arrows
zplug 'supercrabtree/k'                           # Directory listings with git features
zplug 'MichaelAquilina/zsh-you-should-use'        # Reminds you of aliases
zplug 'junegunn/fzf'                              # Fuzzy finder
zplug 'wting/autojump'

export DRACULA_DISPLAY_CONTEXT=1
export DRACULA_DISPLAY_FULL_CWD=1

if (( $+commands[brew] )); then
  # 通过 homebrew 安装的 autojump
  [[ -f $(brew --prefix)/etc/profile.d/autojump.sh ]] && . $(brew --prefix)/etc/profile.d/autojump.sh
elif [[ -f ~/.zsh/autojump/install.py ]]; then
  . ~/.autojump/etc/profile.d/autojump.sh
else
  echo "autojump 未安装，尝试通过 git 安装..."
  git clone https://github.com/wting/autojump.git ~/.zsh/autojump
  cd ~/.zsh/autojump/ && ./install.py
  . ~/.autojump/etc/profile.d/autojump.sh
  cd ~
fi

if ! zplug check; then
    printf "install missing plugins? [y/n]: "
    if read -q; then
        echo; zplug install
    fi
fi

zplug load

#------------------------------
# plugin configuration
#------------------------------

# zsh-autosuggestions
export zsh_autosuggest_highlight_style="fg=#5faf87"
export zsh_autosuggest_strategy=(history completion)
export zsh_autosuggest_buffer_max_size=20

# fzf 配置
if [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
else
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install
fi

export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude ".git" --exclude "node_modules" . --color=always'
export FZF_DEFAULT_OPTS='--ansi'
# 检查 fd 是否安装
if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --exclude ".git" --exclude "node_modules" . --color=always'
  export FZF_ALT_C_COMMAND="fd --type d --exclude .git --exclude node_modules . --color=always"
else
  export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/\.git/*" -not -path "*/node_modules/*"'
  export FZF_ALT_C_COMMAND="find . -type d -not -path '*/\.git/*' -not -path '*/node_modules/*'"
fi

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"

# fzf usage reminder in comment:
# - CTRL+R: Search command history
# - CTRL+T: Search for files
# - ALT+C: CD into selected directory
# - **<TAB>: Fuzzy completion (vim **, kill -9 **, ssh **, etc.)

#------------------------------
# Environment Variables
#------------------------------

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

# Directory colors
export LS_COLORS='rs=0:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:tw=30;42:ow=34;42:st=37;44:ex=01;32:'

#------------------------------
# Development Environment Setup
#------------------------------

# Node.js / npm
export NPM_PACKAGES="${HOME}/.npm-global"
if command -v npm >/dev/null 2>&1; then
    npm config set prefix "$NPM_PACKAGES"
fi
export PATH="$PATH:$NPM_PACKAGES/bin"

# Yarn
export PATH="$PATH:$HOME/.yarn/bin"

# Local bin directory
export PATH="$PATH:$HOME/.local/bin"

# SASS mirror for China
export SASS_BINARY_SITE=http://npm.taobao.org/mirrors/node-sass

# Java / OpenJDK
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# yao
export YAO_INSTALL="$HOME/.yao"
export PATH="$YAO_INSTALL/bin:$PATH"

# go
export PATH="$PATH:$HOME/go/bin"
#------------------------------
# Keybindings
#------------------------------

# Emacs keybindings (default in zsh)
bindkey -e

# Navigation
bindkey "^[[1;5C" forward-word                      # Ctrl+Right: next word
bindkey "^[[1;5D" backward-word                     # Ctrl+Left: previous word
bindkey "^[[H" beginning-of-line                    # Home: beginning of line
bindkey "^[[F" end-of-line                          # End: end of line
bindkey "^[[3~" delete-char                         # Delete: delete char

# History navigation
bindkey "^[[A" history-beginning-search-backward    # Up: search history backwards
bindkey "^[[B" history-beginning-search-forward     # Down: search history forwards

# Extra keybindings for history substring search (if plugin is loaded)
bindkey '^P' history-substring-search-up            # Ctrl+P: search up
bindkey '^N' history-substring-search-down          # Ctrl+N: search down

# Basic cursor movement
bindkey "^[[C" forward-char                         # Right: move forward
bindkey "^[[D" backward-char                        # Left: move backward

# Terminal specific keybindings
bindkey "\E[1~" beginning-of-line                   # Alt setup for Home
bindkey "\E[4~" end-of-line                         # Alt setup for End

# WSL-specific keybindings
if [[ "`uname -r`" == *"WSL"* ]]; then
bindkey "^A" beginning-of-line                    # Ctrl+A: beginning of line (WSL)
bindkey "^E" end-of-line                          # Ctrl+E: end of line (WSL)
fi

# Keybinding reminder:
# Ctrl+U: Clear line up to cursor
# Ctrl+K: Clear line after cursor
# Ctrl+L: Clear screen
# Ctrl+W: Delete word before cursor
# Alt+F/B: Move forward/backward one word
# Ctrl+R: Search history
# Ctrl+G: Cancel search
# Ctrl+_: Undo
# Ctrl+X Ctrl+E: Edit command in $EDITOR
# Option+f: forward word
# Option+b: backward word
# Option+d: deleted word after cursor

#------------------------------
# Aliases
#------------------------------

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# git shortcuts
alias gaa="git add --all"
alias gci='git commit -m'
alias ga='git add'
alias gst='git status'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias glog='git log --oneline --graph --decorate'
alias gdiff='git diff'

# File operations (safer defaults)
# alias rm='echo "This is not the command you are looking for. Use trash-put or rm -i instead."; false'
alias tp='trash-put'
alias cp='cp -i'
alias mv='mv -i'

# Modern replacement tools
alias ls="ls --color -F"                  # Colorized ls with indicators
alias ll="ls --color -lh"                 # Long list format
alias la="ls --color -lha"                # Show all files including hidden
alias lsd="ls -d */"                      # List directories only
alias grep="grep --color=auto"            # Colorized grep output
alias diff="diff --color=auto"            # Colorized diff output

# System management
alias spm="sudo pacman"                   # Arch/Manjaro package manager shortcut

# Windows subsystem
alias subl='subl.exe'                     # Sublime Text (Windows)
alias notepad='notepad.exe'               # Fixed typo from 'nodepad'
alias explorer='explorer.exe'             # Windows Explorer

# Development
alias sail='bash vendor/bin/sail'         # Laravel Sail
alias nv='nvim'                           # Neovim

# Networking
alias ports='netstat -tulan'             # Show open ports

# General
alias path='echo -e ${PATH//:/\\n}'       # Print path in readable format
alias now='date +"%T"'                    # Current time
alias nowdate='date +"%d-%m-%Y"'          # Current date

#------------------------------
# 文件和目录大小查看工具
#------------------------------

# macOS 专用磁盘使用查看
alias dfh='df -h'                              # 显示所有挂载点的空间使用情况
alias diskusage='df -h | grep -v "map"'        # 过滤掉 /map 相关的挂载点

# 更高级的目录大小分析
analyze-dir() {
  local dir="${1:-.}"
  local exclude="${2:-}"
  
  echo "===== 分析目录: $dir ====="
  echo ""
  
  echo "目录总大小:"
  du -sh "$dir"
  echo ""
  
  echo "一级子目录大小排序:"
  if [ -z "$exclude" ]; then
    du -h -d 1 "$dir" | sort -hr
  else
    du -h -d 1 "$dir" | grep -v "$exclude" | sort -hr
  fi
  echo ""
  
  echo "最大的10个文件:"
  find "$dir" -type f -not -path "*/\.*" -exec du -h {} \; | sort -hr | head -10
  echo ""
  
  echo "按文件类型统计:"
  find "$dir" -type f -not -path "*/\.*" | grep -o "\.[^\.]*$" | sort | uniq -c | sort -nr
}

# 显示指定目录中最近修改的大文件
recent-big-files() {
  local dir="${1:-.}"
  local days="${2:-7}"
  local size="${3:-10M}"
  
  echo "过去 $days 天内修改的大于 $size 的文件:"
  find "$dir" -type f -mtime -"$days" -size +"$size" -exec ls -lh {} \; | sort -k5hr
}

# 生成目录大小可视化报告 (需要安装 ncdu)
dirview() {
  if ! command -v ncdu &> /dev/null; then
    echo "请先安装 ncdu: brew install ncdu"
    return 1
  fi
  
  ncdu "${1:-.}"
}

# 统计指定文件类型的总大小
size-of-type() {
  if [ -z "$1" ]; then
    echo "用法: size-of-type <扩展名>"
    echo "例如: size-of-type jpg"
    return 1
  fi
  
  find . -name "*.$1" -exec du -ch {} \; | grep total$
}


# 使用 du 进行格式化输出的目录大小分析
dud() {
  du -d "${1:-1}" -h | sort -hr
}

#------------------------------
# Functions
#------------------------------

# Colorized man pages
man() {
  env \
    LESS_TERMCAP_mb=$(printf "\e[1;31m") \
    LESS_TERMCAP_md=$(printf "\e[1;31m") \
    LESS_TERMCAP_me=$(printf "\e[0m") \
    LESS_TERMCAP_se=$(printf "\e[0m") \
    LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
    LESS_TERMCAP_ue=$(printf "\e[0m") \
    LESS_TERMCAP_us=$(printf "\e[1;32m") \
    man "$@"
}

# Easy extract function for various archive types
extract() {
  if [ $# -eq 0 ]; then
    echo "用法: extract 压缩文件 [目标目录]"
    echo ""
    echo "支持的格式:"
    echo "  .tar.gz, .tgz    - tar 和 gzip 压缩"
    echo "  .tar.bz2, .tbz2  - tar 和 bzip2 压缩"
    echo "  .tar.xz, .txz    - tar 和 xz 压缩"
    echo "  .tar             - 仅 tar 归档"
    echo "  .gz              - gzip 压缩"
    echo "  .bz2             - bzip2 压缩"
    echo "  .xz              - xz 压缩"
    echo "  .zip             - zip 压缩"
    echo "  .rar             - rar 压缩"
    echo "  .7z              - 7zip 压缩"
    echo "  .Z               - compress 压缩"
    return 1
  fi

  local file="$1"
  local target_dir="${2:-.}"
  
  if [ ! -f "$file" ]; then
    echo "'$file' 不是有效文件"
    return 1
  fi

  # 创建目标目录（如果不存在）
  if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir"
  fi

  # 切换到目标目录
  cd "$target_dir"
  
  case "$file" in
    *.tar.bz2|*.tbz2)
      echo "正在解压 tar.bz2 文件..."
      tar xjf "$file"
      ;;
    *.tar.gz|*.tgz)
      echo "正在解压 tar.gz 文件..."
      tar xzf "$file"
      ;;
    *.tar.xz|*.txz)
      echo "正在解压 tar.xz 文件..."
      tar xJf "$file"
      ;;
    *.bz2)
      echo "正在解压 bzip2 文件..."
      bunzip2 -k "$file"
      ;;
    *.rar)
      echo "正在解压 rar 文件..."
      unrar x "$file"
      ;;
    *.gz)
      echo "正在解压 gzip 文件..."
      gunzip -k "$file"
      ;;
    *.tar)
      echo "正在解压 tar 文件..."
      tar xf "$file"
      ;;
    *.zip)
      echo "正在解压 zip 文件..."
      unzip "$file"
      ;;
    *.Z)
      echo "正在解压 Z 文件..."
      uncompress "$file"
      ;;
    *.7z)
      echo "正在解压 7z 文件..."
      7z x "$file"
      ;;
    *)
      echo "'$file' 无法通过 extract() 解压，未知格式"
      cd - > /dev/null
      return 1
      ;;
  esac
  
  # 返回原始目录（如果目标目录不是当前目录）
  if [ "$target_dir" != "." ]; then
    cd - > /dev/null
  fi
  
  if [ $? -eq 0 ]; then
    echo "$file 已成功解压到 $target_dir"
  else
    echo "解压 $file 失败"
    return 1
  fi
}

# Make directory and change into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Simple HTTP server in current directory
serve() {
  local port="${1:-8000}"
  python3 -m http.server "$port"
}

setproxy() {
    local host="${1:-localhost}"
    local port="${2:-8888}"

    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo "Error: Invalid port number. Must be between 1-65535"
        return 1
    fi

    export http_proxy="http://${host}:${port}"
    export https_proxy="http://${host}:${port}"
    export all_proxy="http://${host}:${port}"

    echo "Proxy enabled - http://${host}:${port}"
    echo "Environment variables set:"
    echo "  http_proxy:  $http_proxy"
    echo "  https_proxy: $https_proxy"
    echo "  all_proxy:   $all_proxy"
}

unsetproxy() {
    unset http_proxy https_proxy all_proxy
    echo "All proxy settings have been disabled"
}

checkproxy() {
    echo "Current proxy settings:"
    echo "Environment variables:"
    echo "  http_proxy:  ${http_proxy:-not set}"
    echo "  https_proxy: ${https_proxy:-not set}"
    echo "  all_proxy:   ${all_proxy:-not set}"
}

#------------------------------
# Auto-start Services (Conditionals)
#------------------------------

# Termux specific settings
if which termux-info > /dev/null; then
  echo "Termux environment detected"
  if ! pgrep crond > /dev/null; then
    echo "Starting crond..."
    crond
  else
    echo "crond is running"
  fi
  if ! pgrep -x "sshd" > /dev/null; then
    echo "Starting sshd..."
    sshd
  else
    echo "sshd is running"
  fi
fi

#------------------------------
# Completion System
#------------------------------

autoload -U promptinit
promptinit
zmodload zsh/complist
autoload -Uz compinit
compinit
zstyle :compinstall filename '${HOME}/.zshrc'

# Completion formatting
zstyle ':completion:*:descriptions' format '%U%B%d%b%u'
zstyle ':completion:*:warnings' format '%BSorry, no matches for: %d%b'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Completion behavior
zstyle ':completion:*' menu select                         # Menu-like completion
zstyle ':completion:*' use-cache on                        # Cache completions
zstyle ':completion:*' cache-path ~/.zsh/cache             # Completion cache location
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' # Case insensitive completion
zstyle ':completion:*' rehash true                         # Rehash automatically

# Application-specific completions
zstyle ':completion:*:pacman:*' force-list always
zstyle ':completion:*:*:pacman:*' menu yes select
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:*:killall:*' menu yes select
zstyle ':completion:*:killall:*' force-list always
zstyle ':completion:*:*:docker:*' option-stacking yes      # Docker command stacking
zstyle ':completion:*:processes' command 'ps -au$USER'     # Show user processes only
zstyle ':completion:*:*:*:*:processes' menu yes select

# Docker completions
fpath=($HOME/.docker/completions $fpath)

#------------------------------
# Auto running 
#------------------------------

# 智能启动 tmux
# 只在以下条件都满足时启动 tmux:
# 1. tmux 已安装
# 2. 不在现有的 tmux 会话中
# 3. 不在 nvim 等编辑器的终端中
# 4. 是交互式终端
start_tmux() {
  command -v tmux &> /dev/null || return

  [[ -n "$TMUX" ]] && return

  [[ "$TERM_PROGRAM" == "vscode" ]] && return
  [[ "$TERM" == "dumb" ]] && return
  [[ -n "$NVIM" || -n "$NVIM_LISTEN_ADDRESS" || -n "$VIM_TERMINAL" || -n "$VIMRUNTIME" ]] && return
  [[ "$TERMINAL_EMULATOR" == "JetBrains-JediTerm" ]] && return

  local parent_process
  parent_process=$(ps -o comm= -p $PPID 2>/dev/null)
  [[ "$parent_process" == *nvim* || "$parent_process" == *vim* ]] && return

  [[ -t 1 ]] || return

  if tmux ls &>/dev/null; then
    local first_session
    first_session=$(tmux ls | head -n 1 | cut -d: -f1)
    tmux attach-session -t "$first_session"
  else
    tmux
  fi
}

start_tmux

#------------------------------
# External Configs
#------------------------------

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# LM Studio CLI
export PATH="$PATH:$HOME/.lmstudio/bin"

# Initialize proxy by default (comment out if not needed)
# setproxy

# 使用asciinema录制终端会话
record-terminal() {
  if ! command -v asciinema &> /dev/null; then
    echo "请先安装 asciinema: brew install asciinema"
    return 1
  fi
  
  local filename="${1:-terminal-recording}"
  asciinema rec "$filename.cast"
  echo "录制已保存到 $filename.cast"
  echo "使用 'asciinema play $filename.cast' 回放"
  echo "或 'asciinema upload $filename.cast' 分享到网上"
}
# 快速备份文件
bak() { cp -r "$1" "$1.bak-$(date +%Y%m%d-%H%M%S)"; }

# 通用压缩函数
compress() {
  if [ $# -lt 2 ]; then
    echo "用法: compress 输出文件名.扩展名 文件或目录 [文件或目录...]"
    echo ""
    echo "支持的扩展名:"
    echo "  .tar.gz, .tgz    - 使用 tar 和 gzip 压缩"
    echo "  .tar.bz2, .tbz2  - 使用 tar 和 bzip2 压缩"
    echo "  .tar.xz, .txz    - 使用 tar 和 xz 压缩"
    echo "  .tar             - 仅 tar 归档，无压缩"
    echo "  .gz              - 使用 gzip 压缩单个文件"
    echo "  .bz2             - 使用 bzip2 压缩单个文件"
    echo "  .xz              - 使用 xz 压缩单个文件"
    echo "  .zip             - 使用 zip 压缩"
    echo "  .7z              - 使用 7zip 压缩"
    return 1
  fi
  
  local output="$1"
  shift
  
  case "$output" in
    *.tar.gz|*.tgz)
      tar -czvf "$output" "$@"
      ;;
    *.tar.bz2|*.tbz2)
      tar -cjvf "$output" "$@"
      ;;
    *.tar.xz|*.txz)
      tar -cJvf "$output" "$@"
      ;;
    *.tar)
      tar -cvf "$output" "$@"
      ;;
    *.gz)
      if [ $# -ne 1 ]; then
        echo "gzip 只能压缩单个文件，请使用 .tar.gz 来压缩多个文件"
        return 1
      fi
      gzip -c "$1" > "$output"
      ;;
    *.bz2)
      if [ $# -ne 1 ]; then
        echo "bzip2 只能压缩单个文件，请使用 .tar.bz2 来压缩多个文件"
        return 1
      fi
      bzip2 -c "$1" > "$output"
      ;;
    *.xz)
      if [ $# -ne 1 ]; then
        echo "xz 只能压缩单个文件，请使用 .tar.xz 来压缩多个文件"
        return 1
      fi
      xz -c "$1" > "$output"
      ;;
    *.zip)
      zip -r "$output" "$@"
      ;;
    *.7z)
      7z a "$output" "$@"
      ;;
    *)
      echo "不支持的格式: $output"
      echo "支持的格式: .tar.gz, .tgz, .tar.bz2, .tbz2, .tar.xz, .txz, .tar, .gz, .bz2, .xz, .zip, .7z"
      return 1
      ;;
  esac
  
  if [ $? -eq 0 ]; then
    echo "已创建: $output"
    du -sh "$output"
  else
    echo "压缩失败"
    return 1
  fi
}
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	\rm -f -- "$tmp"
}
# endtime=$EPOCHREALTIME
# loadtime=$(( $endtime - $starttime ))
#
# # 根据加载时间选择颜色和图标
# if (( $loadtime < 0.3 )); then
#   printf "\033[32m⚡ ZSH启动: %.3f秒\033[0m\n" $loadtime
# elif (( $loadtime < 0.8 )); then
#   printf "\033[36m✓ ZSH启动: %.3f秒\033[0m\n" $loadtime
# elif (( $loadtime < 2.0 )); then
#   printf "\033[33m⏱ ZSH启动: %.3f秒\033[0m\n" $loadtime
# else
#   printf "\033[31m⏰ ZSH启动: %.3f秒\033[0m\n" $loadtime
# fi

___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then . "${___MY_VMOPTIONS_SHELL_FILE}"; fi
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

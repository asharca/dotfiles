#!/usr/bin/env zsh
#------------------------------------------------------------------#
# File:     .zshrc   ZSH resource file (Modular)                   #
# Author:   ashark                                                #
#------------------------------------------------------------------#

# ZSH 配置目录
export ZSH_CONFIG_DIR="${HOME}/.config/zsh"

# 加载函数：安全加载配置文件
load_config() {
  local config_file="$1"
  if [[ -f "$config_file" ]]; then
    source "$config_file"
  fi
}

# 自动加载目录下所有 .zsh 文件
load_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    for config_file in "$dir"/*.zsh(N); do
      source "$config_file"
    done
  fi
}

# 1. 核心配置（history, options, keybindings）
load_dir "$ZSH_CONFIG_DIR/core"

# 2. 环境变量（editor, colors, paths）
load_dir "$ZSH_CONFIG_DIR/env"

# 3. 开发环境（node, java, go, docker）
load_dir "$ZSH_CONFIG_DIR/dev"

# 4. zplug
load_config "$ZSH_CONFIG_DIR/preload/zplug.zsh"
load_config "$ZSH_CONFIG_DIR/preload/theme.zsh"
load_config "$ZSH_CONFIG_DIR/preload/config.zsh"

# 5. 插件管理 
load_dir "$ZSH_CONFIG_DIR/plugins"

# 6. 函数库（system, archive, network, disk）
load_dir "$ZSH_CONFIG_DIR/functions"

# 7. 别名（navigation, git, files, system）
load_dir "$ZSH_CONFIG_DIR/aliases"

# 8. 补全系统（最后加载以确保所有命令都已定义）
load_config "$ZSH_CONFIG_DIR/core/completion.zsh"

# ============================================
# 外部工具集成
# ============================================

# LM Studio CLI
[[ -d "$HOME/.lmstudio/bin" ]] && export PATH="$PATH:$HOME/.lmstudio/bin"

# JetBrains vmoptions
[[ -f "${HOME}/.jetbrains.vmoptions.sh" ]] && source "${HOME}/.jetbrains.vmoptions.sh"

# Initialize zoxide
eval "$(zoxide init zsh)"

# Added by Antigravity
export PATH="/Users/ashark/.antigravity/antigravity/bin:$PATH"

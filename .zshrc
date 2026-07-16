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
  local skip_file="${2:-}"
  local config_file
  if [[ -d "$dir" ]]; then
    for config_file in "$dir"/*.zsh(N); do
      [[ -n "$skip_file" && "${config_file:t}" == "$skip_file" ]] && continue
      source "$config_file"
    done
  fi
}

# 1. 核心配置（history, options, keybindings）
load_dir "$ZSH_CONFIG_DIR/core" "completion.zsh"

# 2. 环境变量（editor, colors, paths）
load_dir "$ZSH_CONFIG_DIR/env"

# 3. 开发环境（node, java, go, docker）
load_dir "$ZSH_CONFIG_DIR/dev"

# 4. 插件设置与 zplug（设置必须先于插件加载）
load_config "$ZSH_CONFIG_DIR/preload/theme.zsh"
load_config "$ZSH_CONFIG_DIR/preload/config.zsh"
load_config "$ZSH_CONFIG_DIR/preload/zplug.zsh"

# 5. 插件管理 
load_dir "$ZSH_CONFIG_DIR/plugins"

# 6. 函数库（system, archive, network, disk）
load_dir "$ZSH_CONFIG_DIR/functions"

# 7. 别名（navigation, git, files, system）
load_dir "$ZSH_CONFIG_DIR/aliases"

# ============================================
# 外部工具集成
# ============================================

# JetBrains vmoptions
[[ -f "${HOME}/.jetbrains.vmoptions.sh" ]] && source "${HOME}/.jetbrains.vmoptions.sh"

# 8. 补全系统（最后加载一次，确保命令、插件和 fpath 均已就绪）
load_config "$ZSH_CONFIG_DIR/core/completion.zsh"

# fzf 的原生集成会绑定 Tab；已安装 fzf-tab 时让它接管通用补全。
(( ${+functions[fzf-tab-complete]} )) && bindkey '^I' fzf-tab-complete

unfunction load_config load_dir

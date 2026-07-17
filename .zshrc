#!/usr/bin/env zsh
#------------------------------------------------------------------#
# File:     .zshrc   ZSH resource file (Modular)                   #
# Author:   ashark                                                #
#------------------------------------------------------------------#

# ZSH 配置目录
typeset -g ZSH_CONFIG_DIR="${HOME}/.config/zsh"

# 加载函数：安全加载配置文件
load_config() {
  local config_file="$1"
  [[ -r "$config_file" ]] || return 1
  source "$config_file"
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

# 1. 核心配置。先选择 keymap，再注册依赖该 keymap 的历史快捷键。
load_config "$ZSH_CONFIG_DIR/core/options.zsh"
load_config "$ZSH_CONFIG_DIR/core/history.zsh"

# 2. 环境变量（editor, colors, paths）
load_dir "$ZSH_CONFIG_DIR/env"

# 3. 开发环境（node, java, go, docker）
load_dir "$ZSH_CONFIG_DIR/dev"

# 4. 插件设置。zplug 只在 bootstrap 中安装插件，日常启动直接加载文件。
load_config "$ZSH_CONFIG_DIR/preload/theme.zsh"
load_config "$ZSH_CONFIG_DIR/preload/config.zsh"
if ! load_config "$ZSH_CONFIG_DIR/preload/plugins.zsh"; then
  print -u2 -- "zsh: plugin loader is unavailable; run the dotfiles bootstrap."
  zsh_plugins_after_completion() { :; }
  zsh_plugins_final() { :; }
  zsh_plugins_warn_missing() { :; }
  _zsh_plugin_missing() { :; }
fi

# 5. 补全和 ZLE 插件的顺序不能交换：
#    fpath -> compinit -> fzf keybindings -> fzf-tab -> autosuggestions
load_config "$ZSH_CONFIG_DIR/core/completion.zsh"
load_config "$ZSH_CONFIG_DIR/plugins/fzf.zsh"
zsh_plugins_after_completion

# 6. 其余独立插件
load_dir "$ZSH_CONFIG_DIR/plugins" "fzf.zsh"

# 7. 函数库（system, archive, network, disk）
load_dir "$ZSH_CONFIG_DIR/functions"

# 8. 别名（navigation, git, files, system）
load_dir "$ZSH_CONFIG_DIR/aliases"

# ============================================
# 外部工具集成
# ============================================

# JetBrains vmoptions
[[ -f "${HOME}/.jetbrains.vmoptions.sh" ]] && source "${HOME}/.jetbrains.vmoptions.sh"

# Syntax highlighting 必须最后加载，避免漏掉后续创建的 widgets。
zsh_plugins_final
zsh_plugins_warn_missing

unfunction load_config load_dir zsh_plugins_after_completion zsh_plugins_final \
  zsh_plugins_warn_missing _zsh_plugin_source _zsh_plugin_missing 2>/dev/null || :

#!/usr/bin/env zsh
# Tmux Configuration

if [[ "$(uname)" == "Darwin" ]]; then
  return
fi
# 安装 tmux 插件管理器（TPM）
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
  echo "Installing tmux plugin manager..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# 智能启动 tmux
start_tmux() {
  # 检查 tmux 是否安装
  (( $+commands[tmux] )) || return

  # 已在 tmux 会话中
  [[ -n "$TMUX" ]] && return

  # 排除特殊环境
  [[ "$TERM_PROGRAM" == "vscode" ]] && return
  [[ "$TERM" == "dumb" ]] && return
  [[ -n "$NVIM" || -n "$NVIM_LISTEN_ADDRESS" || -n "$VIM_TERMINAL" || -n "$VIMRUNTIME" ]] && return
  [[ "$TERMINAL_EMULATOR" == "JetBrains-JediTerm" ]] && return

  # 检查父进程
  local parent_process=$(ps -o comm= -p $PPID 2>/dev/null)
  [[ "$parent_process" == *nvim* || "$parent_process" == *vim* ]] && return

  # 必须是交互式终端
  [[ -t 1 ]] || return

  # 连接或创建 tmux 会话
  if tmux ls &>/dev/null; then
    local first_session=$(tmux ls | head -n 1 | cut -d: -f1)
    tmux attach-session -t "$first_session"
  else
    tmux
  fi
}

start_tmux

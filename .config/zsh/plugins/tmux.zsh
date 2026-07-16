#!/usr/bin/env zsh
# Tmux Configuration

if [[ "$(uname)" == "Darwin" ]]; then
  return
fi

# TPM and its plugins are installed by bootstrap. Shell startup stays read-only.

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

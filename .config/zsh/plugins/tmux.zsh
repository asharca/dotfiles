#!/usr/bin/env zsh
# Tmux Configuration

if [[ "$OSTYPE" == darwin* ]]; then
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
  local parent_process="$(ps -o comm= -p "$PPID" 2>/dev/null)"
  [[ "$parent_process" == *nvim* || "$parent_process" == *vim* ]] && return

  # 必须是交互式终端
  [[ -t 1 ]] || return

  # 只查询一次会话列表，然后连接或创建会话。
  local first_session
  first_session="$(tmux list-sessions -F '#S' 2>/dev/null | command head -n 1)"
  if [[ -n "$first_session" ]]; then
    tmux attach-session -t "$first_session"
  else
    tmux new-session
  fi
}

# Automatic attach changes terminal ownership, so keep it explicitly opt-in.
[[ "${ZSH_AUTO_TMUX:-0}" == "1" ]] && start_tmux

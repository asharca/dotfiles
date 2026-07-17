#!/usr/bin/env zsh
# System Aliases

# Package manager shortcuts
alias spm='sudo pacman'        # Arch/Manjaro
alias sai='sudo apt install'   # Debian/Ubuntu
alias sau='sudo apt update'    # Debian/Ubuntu
alias dnfi='sudo dnf install'  # Fedora

# Editor shortcuts
unalias nv vi vim 2>/dev/null || :
if (( $+commands[nvim] )); then
  alias nv='nvim'
  alias vi='nvim'
  alias vim='nvim'
fi

# Windows subsystem (WSL)
if [[ "$OSTYPE" == linux* ]] && {
  [[ -n ${WSL_DISTRO_NAME:-} ]] || [[ -e /proc/sys/fs/binfmt_misc/WSLInterop ]]
}; then
  alias subl='subl.exe'
  alias notepad='notepad.exe'
  alias explorer='explorer.exe'
  alias code='code.exe'
fi

# Networking
unalias ports localip myip 2>/dev/null || :
if (( $+commands[curl] )); then
  alias myip='curl -fsS --max-time 10 https://ifconfig.me/ip'
fi

case "$OSTYPE" in
  darwin*)
    localip() {
      emulate -L zsh
      local interface address

      if (( $+commands[route] && $+commands[ipconfig] )); then
        interface="$(command route -n get default 2>/dev/null | command awk '/interface:/{print $2; exit}')"
        if [[ -n "$interface" ]]; then
          address="$(command ipconfig getifaddr "$interface" 2>/dev/null)"
          if [[ -n "$address" ]]; then
            print -- "$address"
            return 0
          fi
        fi
      fi

      if (( $+commands[ifconfig] )); then
        address="$(command ifconfig | command awk '/^[[:space:]]*inet / && $2 != "127.0.0.1" {print $2; exit}')"
        if [[ -n "$address" ]]; then
          print -- "$address"
          return 0
        fi
      fi

      print -u2 -- 'Error: No active IPv4 address found'
      return 1
    }

    ports() {
      emulate -L zsh
      if (( $+commands[lsof] )); then
        command lsof -nP -iTCP -sTCP:LISTEN
      elif (( $+commands[netstat] )); then
        command netstat -anv -p tcp | command awk 'NR == 1 || /LISTEN/'
      else
        print -u2 -- 'Error: Neither lsof nor netstat is installed'
        return 127
      fi
    }
    ;;
  linux*)
    localip() {
      emulate -L zsh
      local address

      if (( $+commands[ip] )); then
        address="$(command ip -o -4 addr show scope global 2>/dev/null | command awk 'NR == 1 {sub(/\/.*/, "", $4); print $4}')"
      elif (( $+commands[hostname] )); then
        address="$(command hostname -I 2>/dev/null | command awk '{print $1}')"
      else
        print -u2 -- 'Error: Neither ip nor hostname is installed'
        return 127
      fi

      if [[ -n "$address" ]]; then
        print -- "$address"
        return 0
      fi
      print -u2 -- 'Error: No active IPv4 address found'
      return 1
    }

    ports() {
      emulate -L zsh
      if (( $+commands[ss] )); then
        command ss -tuln
      elif (( $+commands[netstat] )); then
        command netstat -tuln
      else
        print -u2 -- 'Error: Neither ss nor netstat is installed'
        return 127
      fi
    }
    ;;
  *)
    localip() {
      print -u2 -- "Error: localip is not configured for $OSTYPE"
      return 1
    }

    ports() {
      print -u2 -- "Error: ports is not configured for $OSTYPE"
      return 1
    }
    ;;
esac

# General utilities
unalias path 2>/dev/null || :
path() {
  print -rl -- $path
}
alias now='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'
alias timestamp='date +"%Y%m%d_%H%M%S"'

# Process management
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias psm='ps aux | sort -k4 -r | head -10'  # Top 10 memory-consuming processes
alias psc='ps aux | sort -k3 -r | head -10'  # Top 10 CPU-consuming processes

# System monitoring
unalias freq temp 2>/dev/null || :
case "$OSTYPE" in
  darwin*) ;;
  linux*)
    [[ -r /proc/cpuinfo ]] && alias freq='grep "MHz" /proc/cpuinfo'
    (( $+commands[sensors] )) && alias temp='sensors'
    ;;
esac

case "$OSTYPE" in
  darwin*)
    unalias copy 2>/dev/null || :
    (( $+commands[pbcopy] )) && alias copy='pbcopy'
    ;;
  linux*)
    unalias copy 2>/dev/null || :
    if [[ -n ${KITTY_WINDOW_ID:-} ]] && (( $+commands[kitty] )); then
      alias copy='kitty +kitten clipboard'
    elif [[ -n ${WAYLAND_DISPLAY:-} ]] && (( $+commands[wl-copy] )); then
      alias copy='wl-copy'
    elif [[ -n ${DISPLAY:-} ]] && (( $+commands[xclip] )); then
      alias copy='xclip -selection clipboard'
    elif [[ -n ${DISPLAY:-} ]] && (( $+commands[xsel] )); then
      alias copy='xsel --clipboard --input'
    fi
    ;;
esac

ssh() {
    if command -v kitty >/dev/null 2>&1; then
        kitty +kitten ssh "$@"
    else
        command ssh "$@"
    fi
}

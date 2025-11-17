#!/usr/bin/env zsh
# System Aliases

# Package manager shortcuts
alias spm='sudo pacman'        # Arch/Manjaro
alias sai='sudo apt install'   # Debian/Ubuntu
alias sau='sudo apt update'    # Debian/Ubuntu
alias dnfi='sudo dnf install'  # Fedora

# Editor shortcuts
alias nv='nvim'
alias vi='nvim'
alias vim='nvim'

# Windows subsystem (WSL)
if [[ "$(uname -r)" == *"WSL"* ]] || [[ "$(uname -r)" == *"microsoft"* ]]; then
  alias subl='subl.exe'
  alias notepad='notepad.exe'
  alias explorer='explorer.exe'
  alias code='code.exe'
fi

# Networking
alias ports='netstat -tulan'
alias myip='curl ifconfig.me'
alias localip='hostname -I | awk "{print \$1}"'

# General utilities
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'
alias timestamp='date +"%Y%m%d_%H%M%S"'

# Process management
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias psm='ps aux | sort -k4 -r | head -10'  # Top 10 memory-consuming processes
alias psc='ps aux | sort -k3 -r | head -10'  # Top 10 CPU-consuming processes

# System monitoring
alias freq='cat /proc/cpuinfo | grep "MHz"'
alias temp='sensors 2>/dev/null || echo "lm-sensors not installed"'

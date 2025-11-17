#!/usr/bin/env zsh
# PATH Configuration

# Local bin
export PATH="$HOME/.local/bin:$PATH"


# Zoxide (smarter cd)
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# Starship prompt (如果安装了)
(( $+commands[starship] )) && eval "$(starship init zsh)"

# Dotfiles git alias
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'


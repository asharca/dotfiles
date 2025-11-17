#!/usr/bin/env zsh
# Keybindings

# Navigation
bindkey "^[[1;5C" forward-word                      # Ctrl+Right
bindkey "^[[1;5D" backward-word                     # Ctrl+Left
bindkey "^[[H" beginning-of-line                    # Home
bindkey "^[[F" end-of-line                          # End
bindkey "^[[3~" delete-char                         # Delete

# History navigation
bindkey "^[[A" up-line-or-beginning-search          # Up
bindkey "^[[B" down-line-or-beginning-search        # Down
bindkey '^P' history-substring-search-up            # Ctrl+P
bindkey '^N' history-substring-search-down          # Ctrl+N

# Basic cursor movement
bindkey "^[[C" forward-char                         # Right
bindkey "^[[D" backward-char                        # Left

# Terminal specific
bindkey "\E[1~" beginning-of-line
bindkey "\E[4~" end-of-line

# WSL-specific keybindings
if [[ "$(uname -r)" == *"WSL"* ]]; then
  bindkey "^A" beginning-of-line
  bindkey "^E" end-of-line
fi

# Fix Ubuntu 24 LTS gnome-terminal enter key
bindkey -s "^[OM" "^M"

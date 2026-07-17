#!/usr/bin/env zsh

# zsh-autosuggestions
typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#5faf87"
typeset -ga ZSH_AUTOSUGGEST_STRATEGY=(history completion)
typeset -g ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
# Bind once after every ZLE plugin is loaded instead of rebinding on each prompt.
typeset -g ZSH_AUTOSUGGEST_MANUAL_REBIND=1
typeset +x ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE \
  ZSH_AUTOSUGGEST_MANUAL_REBIND

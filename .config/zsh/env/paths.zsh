#!/usr/bin/env zsh
# PATH Configuration

typeset -gU path PATH
typeset -gU fpath FPATH

_path_prepend() {
  [[ -d "$1" ]] && path=("$1" $path)
}

_path_append() {
  [[ -d "$1" ]] && path+=("$1")
}

# Add in reverse priority order because each entry is prepended.
_path_prepend "$HOME/.bun/bin"
_path_prepend "$HOME/.npm-global/bin"
_path_prepend "$HOME/.local/bin"
[[ -n "${HOMEBREW_PREFIX:-}" ]] && \
  _path_prepend "$HOMEBREW_PREFIX/opt/trash-cli/bin"

# LM Studio is optional and belongs at the end of the user tool paths.
_path_append "$HOME/.lmstudio/bin"

if [[ -d "$HOME/.bun" ]]; then
  export BUN_INSTALL="$HOME/.bun"
  [[ -r "$BUN_INSTALL/_bun" ]] && fpath=("$BUN_INSTALL" $fpath)
fi

# Make user completions visible before the single compinit pass.
[[ -d "$HOME/.zfunc" ]] && fpath=("$HOME/.zfunc" $fpath)

unfunction _path_prepend _path_append


# Zoxide (smarter cd)
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# Dotfiles bare repository. A function preserves argument boundaries reliably.
config() {
  command git --git-dir="$HOME/.cfg" --work-tree="$HOME" "$@"
}

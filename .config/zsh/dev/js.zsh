# Deno
[[ -f ~/.deno/env ]] && source ~/.deno/env
[[ -d "$HOME/.deno/bin" ]] && path=("$HOME/.deno/bin" $path)

# Deno completions
if [[ -d "$HOME/.zsh/completions" ]]; then
  typeset -gU fpath FPATH
  fpath=("$HOME/.zsh/completions" $fpath)
fi

# Yarn
[[ -d "$HOME/.yarn/bin" ]] && path=("$HOME/.yarn/bin" $path)

export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # Always lazy-load NVM. Creating a default alias must not add ~100 ms to
  # every shell when Homebrew's Node is already available.
  nvm() {
    local -a nvm_args=("$@")
    unfunction nvm
    source "$NVM_DIR/nvm.sh" || return 1
    if (( ! $+functions[nvm] )); then
      print -u2 -- "nvm: '$NVM_DIR/nvm.sh' did not define the nvm function"
      return 127
    fi
    nvm "${nvm_args[@]}"
  }
fi

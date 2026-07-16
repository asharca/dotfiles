# Deno
[[ -f ~/.deno/env ]] && source ~/.deno/env

# Deno completions
if [[ -d "$HOME/.zsh/completions" ]]; then
  export FPATH="$HOME/.zsh/completions:$FPATH"
fi

# Yarn
[[ -d "$HOME/.yarn/bin" ]] && export PATH="$HOME/.yarn/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # No default NVM version is configured on this machine, so keep Homebrew's
  # Node fast and load NVM only when the `nvm` command is first used. If a
  # default alias is configured later, load it eagerly on subsequent shells.
  if [[ -s "$NVM_DIR/alias/default" ]]; then
    source "$NVM_DIR/nvm.sh"
  else
    nvm() {
      local -a nvm_args=("$@")
      unfunction nvm
      source "$NVM_DIR/nvm.sh"
      nvm "${nvm_args[@]}"
    }
  fi
fi

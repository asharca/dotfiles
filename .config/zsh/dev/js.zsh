# Deno
[[ -f ~/.deno/env ]] && source ~/.deno/env

# Deno completions
if [[ -d "$HOME/.zsh/completions" ]]; then
  export FPATH="$HOME/.zsh/completions:$FPATH"
fi

# Yarn
[[ -d "$HOME/.yarn/bin" ]] && export PATH="$HOME/.yarn/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


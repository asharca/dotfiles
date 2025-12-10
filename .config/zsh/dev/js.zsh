# Deno
[[ -f ~/.deno/env ]] && source ~/.deno/env

# Deno completions
if [[ -d "$HOME/.zsh/completions" ]]; then
  export FPATH="$HOME/.zsh/completions:$FPATH"
fi

# Yarn
[[ -d "$HOME/.yarn/bin" ]] && export PATH="$HOME/.yarn/bin:$PATH"


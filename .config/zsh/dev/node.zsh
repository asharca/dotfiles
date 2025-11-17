#!/usr/bin/env zsh
# Node.js / npm / Yarn Configuration

# npm global packages
export NPM_PACKAGES="${HOME}/.npm-global"
if (( $+commands[npm] )); then
  [[ -d "$NPM_PACKAGES" ]] || mkdir -p "$NPM_PACKAGES"
  npm config set prefix "$NPM_PACKAGES" 2>/dev/null
  export PATH="$NPM_PACKAGES/bin:$PATH"
fi

# Yarn
[[ -d "$HOME/.yarn/bin" ]] && export PATH="$HOME/.yarn/bin:$PATH"

# SASS mirror (for China)
export SASS_BINARY_SITE=http://npm.taobao.org/mirrors/node-sass

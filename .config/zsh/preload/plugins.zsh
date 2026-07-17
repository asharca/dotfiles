#!/usr/bin/env zsh
# Runtime plugin loader. Plugin installation remains the bootstrap's job;
# interactive shells source the already-installed files directly.

# Older revisions exported zplug internals. Do not propagate that stale runtime
# state now that zplug is used only by the bootstrap.
unset ZPLUG_HOME ZPLUG_ROOT ZPLUG_BIN ZPLUG_CACHE_DIR ZPLUG_REPOS \
  ZPLUG_LOADFILE ZPLUG_ERROR_LOG ZPLUG_PROTOCOL ZPLUG_USE_CACHE ZPLUG_THREADS \
  ZPLUG_FILTER ZPLUG_LOG_LOAD_FAILURE ZPLUG_LOG_LOAD_SUCCESS ZPLUG_SUDO_PASSWORD

typeset -g ZSH_PLUGIN_ROOT="${ZSH_PLUGIN_ROOT:-$HOME/.zplug/repos}"
typeset +x ZSH_PLUGIN_ROOT

# Reloading ~/.zshrc must not source widget-wrapping plugins a second time.
if [[ "${ZSH_DOTFILES_PLUGINS_LOADED:-0}" == "1" ]]; then
  zsh_plugins_after_completion() { :; }
  zsh_plugins_final() { :; }
  zsh_plugins_warn_missing() { :; }
  return 0
fi
typeset -g ZSH_DOTFILES_PLUGINS_LOADED=1

typeset -ga ZSH_MISSING_PLUGINS=()
typeset -gU fpath FPATH

_zsh_plugin_missing() {
  ZSH_MISSING_PLUGINS+=("$1")
}

_zsh_plugin_source() {
  local name="$1"
  local plugin_file="$2"

  if [[ ! -r "$plugin_file" ]]; then
    _zsh_plugin_missing "$name"
    return 0
  fi

  if ! source "$plugin_file"; then
    _zsh_plugin_missing "$name:failed"
  fi
  return 0
}

# Completion definitions must be on fpath before the one compinit invocation.
if [[ -d "$ZSH_PLUGIN_ROOT/zsh-users/zsh-completions/src" ]]; then
  fpath=("$ZSH_PLUGIN_ROOT/zsh-users/zsh-completions/src" $fpath)
else
  _zsh_plugin_missing zsh-completions
fi

# These plugins do not depend on compinit or ZLE wrapping order.
_zsh_plugin_source dracula \
  "$ZSH_PLUGIN_ROOT/dracula/zsh/dracula.zsh-theme"
_zsh_plugin_source k \
  "$ZSH_PLUGIN_ROOT/supercrabtree/k/k.sh"
_zsh_plugin_source zsh-you-should-use \
  "$ZSH_PLUGIN_ROOT/MichaelAquilina/zsh-you-should-use/you-should-use.plugin.zsh"

zsh_plugins_after_completion() {
  # fzf's bindings are loaded by plugins/fzf.zsh immediately before this.
  _zsh_plugin_source fzf-tab \
    "$ZSH_PLUGIN_ROOT/Aloxaf/fzf-tab/fzf-tab.plugin.zsh"
  _zsh_plugin_source zsh-autosuggestions \
    "$ZSH_PLUGIN_ROOT/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"

  # fzf's native integration binds Tab; fzf-tab owns generic completion.
  (( ${+functions[fzf-tab-complete]} )) && bindkey '^I' fzf-tab-complete
}

zsh_plugins_final() {
  _zsh_plugin_source zsh-syntax-highlighting \
    "$ZSH_PLUGIN_ROOT/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"
}

zsh_plugins_warn_missing() {
  if (( ${#ZSH_MISSING_PLUGINS[@]} )); then
    typeset -gU ZSH_MISSING_PLUGINS
    print -u2 -- \
      "zsh: optional plugins unavailable: ${(j:, :)ZSH_MISSING_PLUGINS}. Run the dotfiles bootstrap."
  fi
  unset ZSH_MISSING_PLUGINS
}

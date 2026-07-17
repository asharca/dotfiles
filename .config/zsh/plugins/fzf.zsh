#!/usr/bin/env zsh
# FZF Configuration

if [[ "${ZSH_FZF_INTEGRATION_LOADED:-0}" == "1" ]]; then
  return 0
fi
typeset -g ZSH_FZF_INTEGRATION_LOADED=1

if (( $+commands[fzf] )) && [[ -t 0 && -t 1 ]]; then
  # Prefer the installed scripts so startup does not execute `fzf --zsh`.
  # The executable-derived path covers Homebrew without invoking `brew`.
  typeset -a _fzf_shell_dirs=(
    "${commands[fzf]:A:h:h}/shell"
    "/usr/share/doc/fzf/examples"
    "/usr/share/fzf/shell"
    "/usr/share/fzf"
    "$HOME/.fzf/shell"
  )
  typeset _fzf_shell_dir=""

  for _fzf_candidate in "${_fzf_shell_dirs[@]}"; do
    if [[ -r "$_fzf_candidate/key-bindings.zsh" ]]; then
      _fzf_shell_dir="$_fzf_candidate"
      break
    fi
  done

  if [[ -n "$_fzf_shell_dir" ]]; then
    [[ -r "$_fzf_shell_dir/completion.zsh" ]] && \
      source "$_fzf_shell_dir/completion.zsh"
    source "$_fzf_shell_dir/key-bindings.zsh"
  else
    # Portable fallback for standalone fzf releases that do not ship scripts.
    typeset _fzf_init=""
    if _fzf_init="$(fzf --zsh 2>/dev/null)" && [[ -n "$_fzf_init" ]]; then
      eval "$_fzf_init"
    else
      _zsh_plugin_missing fzf-shell-integration
    fi
    unset _fzf_init
  fi

  unset _fzf_shell_dirs _fzf_shell_dir _fzf_candidate

  if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude ".git" --exclude "node_modules" . --color=always'
    export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude ".git" --exclude "node_modules" . --color=always'
  else
    export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/\.git/*" -not -path "*/node_modules/*"'
    export FZF_ALT_C_COMMAND='find . -type d -not -path "*/\.git/*" -not -path "*/node_modules/*"'
  fi

  export FZF_DEFAULT_OPTS='--ansi --height 40% --layout=reverse --border'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_OPTS="--preview 'ls -lah {}' --preview-window=right:50%"
elif ! (( $+commands[fzf] )) && [[ -o interactive ]]; then
  _zsh_plugin_missing fzf
fi

# Keybindings:
# CTRL+R: Search command history
# CTRL+T: Search for files
# ALT+C: CD into selected directory
# **<TAB>: Fuzzy completion

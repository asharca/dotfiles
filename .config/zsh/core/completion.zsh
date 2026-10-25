#!/usr/bin/env zsh
# Completion System

zmodload zsh/complist
zmodload zsh/datetime
zmodload zsh/stat

typeset -gU fpath FPATH

autoload -Uz compinit

typeset -g ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
if (( ! ${+_comps} )); then
  typeset _completion_cache_ready=1

  _zsh_completion_path_is_safe() {
    emulate -L zsh

    local expected_kind="$1"
    local target="$2"
    local -A path_stat

    [[ ! -L "$target" ]] || return 1
    case "$expected_kind" in
      (directory) [[ -d "$target" && -w "$target" && -x "$target" ]] || return 1 ;;
      (file) [[ -f "$target" && -r "$target" ]] || return 1 ;;
      (*) return 1 ;;
    esac

    zstat -H path_stat -- "$target" || return 1
    (( path_stat[uid] == EUID )) || return 1
    if [[ "$expected_kind" == directory ]]; then
      # Completion cache files are executable Zsh code; keep the whole tree private.
      (( ! (path_stat[mode] & 8#77) ))
    else
      (( ! (path_stat[mode] & 8#22) ))
    fi
  }

  if [[ ! -d "$ZSH_CACHE_DIR" ]]; then
    (umask 077; command mkdir -p -- "$ZSH_CACHE_DIR" 2>/dev/null) || \
      _completion_cache_ready=0
  fi
  if (( _completion_cache_ready )) && \
     ! _zsh_completion_path_is_safe directory "$ZSH_CACHE_DIR"; then
    _completion_cache_ready=0
  fi

  if (( _completion_cache_ready )); then
    typeset -g ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump-${ZSH_VERSION}"
    typeset _completion_dump_file
    for _completion_dump_file in "$ZSH_COMPDUMP" "$ZSH_COMPDUMP.zwc"; do
      if [[ -e "$_completion_dump_file" || -L "$_completion_dump_file" ]] && \
         ! _zsh_completion_path_is_safe file "$_completion_dump_file"; then
        _completion_cache_ready=0
        break
      fi
    done
    unset _completion_dump_file
  fi

  if (( _completion_cache_ready )); then
    typeset -A _zcompdump_stat

    # Run the security scan and regenerate the dump when it is absent or older
    # than 24 hours. A fresh cache uses -C and skips the filesystem scan.
    if [[ ! -s "$ZSH_COMPDUMP" ]] || \
       ! zstat -H _zcompdump_stat -- "$ZSH_COMPDUMP" || \
       (( EPOCHSECONDS - ${_zcompdump_stat[mtime]:-0} > 86400 )); then
      typeset _completion_old_umask="$(umask)"
      {
        umask 077
        compinit -d "$ZSH_COMPDUMP"
      } always {
        umask "$_completion_old_umask"
      }
      unset _completion_old_umask
    else
      compinit -C -d "$ZSH_COMPDUMP"
    fi
    unset _zcompdump_stat
  else
    # Keep completion usable even on a read-only or misconfigured cache path.
    print -u2 -- "zsh: completion cache at $ZSH_CACHE_DIR is unavailable or unsafe; continuing without a dump."
    typeset -g ZSH_COMPDUMP=""
    compinit -D
  fi

  unfunction _zsh_completion_path_is_safe
  unset _completion_cache_ready
fi

# zoxide may initialize before compinit, when compdef is not available yet.
(( ${+functions[__zoxide_z_complete]} )) && compdef __zoxide_z_complete z

# The dotfiles helper is a function (for safe quoting), so explicitly reuse
# Git's completion service instead of relying on alias expansion.
(( ${+functions[config]} )) && compdef _git config

zstyle :compinstall filename "${HOME}/.zshrc"

# Completion formatting
zstyle ':completion:*:descriptions' format '%U%B%d%b%u'
zstyle ':completion:*:warnings' format '%BSorry, no matches for: %d%b'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Completion behavior
zstyle ':completion:*' menu select
if [[ -n "${ZSH_COMPDUMP:-}" && -w "$ZSH_CACHE_DIR" ]]; then
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR"
else
  zstyle ':completion:*' use-cache off
fi
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'

# Application-specific completions
zstyle ':completion:*:pacman:*' force-list always
zstyle ':completion:*:*:pacman:*' menu yes select
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:*:killall:*' menu yes select
zstyle ':completion:*:killall:*' force-list always
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:processes' command 'ps -au$USER'
zstyle ':completion:*:*:*:*:processes' menu yes select

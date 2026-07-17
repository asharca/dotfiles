# Yazi shell wrapper (文件管理器)
if (( $+commands[yazi] )); then
  function y() {
    emulate -L zsh

    local tmp cwd
    local -i exit_status cleanup_status

    tmp="$(command mktemp "${TMPDIR:-/tmp}/yazi-cwd.XXXXXXXXXX")" || return $?

    command yazi "$@" --cwd-file="$tmp"
    exit_status=$?

    if (( exit_status == 0 )); then
      cwd="$(command cat -- "$tmp")"
      exit_status=$?
      if (( exit_status == 0 )) && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
        builtin cd -- "$cwd"
        exit_status=$?
      fi
    fi

    command rm -f -- "$tmp"
    cleanup_status=$?
    (( exit_status == 0 && cleanup_status != 0 )) && exit_status=$cleanup_status
    return $exit_status
  }
fi

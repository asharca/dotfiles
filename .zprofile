#!/usr/bin/env zsh

typeset -gU path PATH

# /etc/zprofile runs path_helper after .zshenv and may move user toolchains
# behind the system paths. Restore their intended order without invoking tools.
for tool_bin in \
  "$HOME/.cargo/bin" \
  "${ZEROBREW_BIN:-}" \
  "${ZEROBREW_PREFIX:+$ZEROBREW_PREFIX/bin}"; do
  [[ -n "$tool_bin" && -d "$tool_bin" ]] && path=("$tool_bin" $path)
done
unset tool_bin

if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  [[ -d "$HOMEBREW_PREFIX/sbin" ]] && path=("$HOMEBREW_PREFIX/sbin" $path)
  [[ -d "$HOMEBREW_PREFIX/bin" ]] && path=("$HOMEBREW_PREFIX/bin" $path)
fi

# Keep the currently installed python.org framework ahead of the system Python.
python_bin="/Library/Frameworks/Python.framework/Versions/3.13/bin"
[[ -d "$python_bin" ]] && path=("$python_bin" $path)
unset python_bin

# >>> Codex installer >>>
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
# <<< Codex installer <<<

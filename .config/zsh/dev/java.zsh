#!/usr/bin/env zsh
# Java Configuration

# OpenJDK from the detected Homebrew/Linuxbrew prefix, with standalone fallbacks.
for java_bin in \
  "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/openjdk/bin}" \
  /opt/homebrew/opt/openjdk/bin \
  /usr/local/opt/openjdk/bin \
  /home/linuxbrew/.linuxbrew/opt/openjdk/bin \
  "$HOME/.linuxbrew/opt/openjdk/bin"; do
  if [[ -n "$java_bin" && -d "$java_bin" ]]; then
    path=("$java_bin" $path)
    break
  fi
done
unset java_bin

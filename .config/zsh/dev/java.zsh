#!/usr/bin/env zsh
# Java Configuration

# OpenJDK (Homebrew)
if [[ -d "/opt/homebrew/opt/openjdk/bin" ]]; then
  export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
fi

#!/usr/bin/env zsh
# System Functions

# Make directory and change into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Simple HTTP server
serve() {
  local port="${1:-8000}"
  python3 -m http.server "$port"
}

# Quick file backup
bak() {
  cp -r "$1" "$1.bak-$(date +%Y%m%d-%H%M%S)"
}

# Record terminal session with asciinema
record-terminal() {
  if ! (( $+commands[asciinema] )); then
    echo "Please install asciinema first: brew install asciinema"
    return 1
  fi
  
  local filename="${1:-terminal-recording}"
  asciinema rec "$filename.cast"
  echo "Recording saved to $filename.cast"
  echo "Playback: asciinema play $filename.cast"
  echo "Upload: asciinema upload $filename.cast"
}

#!/usr/bin/env zsh
# System Functions

# Make directory and change into it
mkcd() {
  emulate -L zsh

  if (( $# != 1 )); then
    print -u2 -- 'Usage: mkcd <directory>'
    return 2
  fi

  command mkdir -p -- "$1" || return $?
  builtin cd -- "$1"
}

# Simple HTTP server
serve() {
  emulate -L zsh

  if (( $# > 3 )); then
    print -u2 -- 'Usage: serve [port] [bind_address] [directory]'
    return 2
  fi

  local port="${1:-8000}"
  local bind_address="${2:-127.0.0.1}"
  local directory="${3:-.}"

  if [[ ! "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
    print -u2 -- 'Error: Port must be an integer between 1 and 65535'
    return 2
  fi

  if [[ -z "$bind_address" || "$bind_address" == *[[:space:]]* ]]; then
    print -u2 -- 'Error: Bind address must not be empty or contain whitespace'
    return 2
  fi

  if [[ ! -d "$directory" ]]; then
    print -u2 -- "Error: Directory '$directory' does not exist"
    return 2
  fi

  if ! (( $+commands[python3] || $+functions[python3] )); then
    print -u2 -- 'Error: python3 is required to start the server'
    return 127
  fi

  (
    builtin cd -- "$directory" || return $?
    python3 -m http.server --bind "$bind_address" "$port"
  )
}

# Quick file backup
bak() {
  emulate -L zsh

  if (( $# != 1 )); then
    print -u2 -- 'Usage: bak <file-or-directory>'
    return 2
  fi

  if [[ ! -e "$1" && ! -L "$1" ]]; then
    print -u2 -- "Error: '$1' does not exist"
    return 1
  fi

  local source="${1:a}"
  local timestamp target
  if [[ "$source" == "/" ]]; then
    print -u2 -- 'Error: Refusing to back up the filesystem root'
    return 1
  fi

  timestamp="$(command date +%Y%m%d-%H%M%S)" || return $?
  target="$source.bak-$timestamp"

  if [[ -e "$target" || -L "$target" ]]; then
    print -u2 -- "Error: Backup target '$target' already exists"
    return 1
  fi

  command cp -R -p -- "$source" "$target"
}

# Record terminal session with asciinema
record-terminal() {
  emulate -L zsh

  if (( $# > 1 )); then
    print -u2 -- 'Usage: record-terminal [filename]'
    return 2
  fi

  if ! (( $+commands[asciinema] || $+functions[asciinema] )); then
    print -u2 -- 'Please install asciinema first: brew install asciinema'
    return 127
  fi

  local filename="${1:-terminal-recording}"
  local output="${filename%.cast}.cast"
  local exit_status

  if [[ -z "$filename" ]]; then
    print -u2 -- 'Error: Filename must not be empty'
    return 2
  fi

  asciinema rec "$output"
  exit_status=$?
  if (( exit_status != 0 )); then
    print -u2 -- "Recording failed: $output"
    return $exit_status
  fi

  print -- "Recording saved to $output"
  print -- "Playback: asciinema play $output"
  print -- "Upload: asciinema upload $output"
  return 0
}

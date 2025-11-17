#!/usr/bin/env zsh
# Disk Analysis Functions

# Disk usage with human-readable format
alias dfh='df -h'
alias diskusage='df -h | grep -v "map"'

# Directory size analysis
analyze-dir() {
  local dir="${1:-.}"
  local exclude="${2:-}"
  
  echo "===== Analyzing: $dir ====="
  echo ""
  
  echo "Total size:"
  du -sh "$dir"
  echo ""
  
  echo "Top-level subdirectories (sorted):"
  if [ -z "$exclude" ]; then
    du -h -d 1 "$dir" | sort -hr
  else
    du -h -d 1 "$dir" | grep -v "$exclude" | sort -hr
  fi
  echo ""
  
  echo "10 largest files:"
  find "$dir" -type f -not -path "*/\.*" -exec du -h {} \; | sort -hr | head -10
  echo ""
  
  echo "File types:"
  find "$dir" -type f -not -path "*/\.*" | grep -o "\.[^\.]*$" | sort | uniq -c | sort -nr
}

# Recent large files
recent-big-files() {
  local dir="${1:-.}"
  local days="${2:-7}"
  local size="${3:-10M}"
  
echo "Files larger than $size modified in the last $days days:"
  find "$dir" -type f -mtime -"$days" -size +"$size" -exec ls -lh {} \; | sort -k5hr
}

# Directory visualization (requires ncdu)
dirview() {
  if ! (( $+commands[ncdu] )); then
    echo "Please install ncdu first: brew install ncdu"
    return 1
  fi
  
  ncdu "${1:-.}"
}

# Calculate total size of specific file type
size-of-type() {
  if [ -z "$1" ]; then
    echo "Usage: size-of-type <extension>"
    echo "Example: size-of-type jpg"
    return 1
  fi
  
  find . -name "*.$1" -exec du -ch {} \; | grep total$
}

# Formatted du with depth limit
dud() {
  du -d "${1:-1}" -h | sort -hr
}

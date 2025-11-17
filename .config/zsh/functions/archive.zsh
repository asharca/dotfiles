#!/usr/bin/env zsh
# Archive Functions

# Extract various archive types
extract() {
  if [ $# -eq 0 ]; then
    cat << EOF
Usage: extract <archive> [target_directory]

Supported formats:
  .tar.gz, .tgz    - tar with gzip
  .tar.bz2, .tbz2  - tar with bzip2
  .tar.xz, .txz    - tar with xz
  .tar             - tar only
  .gz              - gzip
  .bz2             - bzip2
  .xz              - xz
  .zip             - zip
  .rar             - rar
  .7z              - 7zip
  .Z               - compress
EOF
    return 1
  fi

  local file="$1"
  local target_dir="${2:-.}"
  
  if [[ ! -f "$file" ]]; then
    echo "Error: '$file' is not a valid file"
    return 1
  fi

  [[ -d "$target_dir" ]] || mkdir -p "$target_dir"
  
  case "$file" in
    *.tar.bz2|*.tbz2) tar xjf "$file" -C "$target_dir" ;;
    *.tar.gz|*.tgz)   tar xzf "$file" -C "$target_dir" ;;
    *.tar.xz|*.txz)   tar xJf "$file" -C "$target_dir" ;;
    *.tar)            tar xf "$file" -C "$target_dir" ;;
    *.bz2)            bunzip2 -k "$file" ;;
    *.gz)             gunzip -k "$file" ;;
    *.rar)            unrar x "$file" "$target_dir" ;;
    *.zip)            unzip "$file" -d "$target_dir" ;;
    *.Z)              uncompress "$file" ;;
    *.7z)             7z x "$file" -o"$target_dir" ;;
    *)
      echo "Error: Unknown archive format"
      return 1
      ;;
  esac
  
  if [[ $? -eq 0 ]]; then
    echo "Successfully extracted to $target_dir"
  else
    echo "Extraction failed"
    return 1
  fi
}

# Compress files/directories
compress() {
  if [ $# -lt 2 ]; then
    cat << EOF
Usage: compress <output.ext> <file/dir> [file/dir...]

Supported formats:
  .tar.gz, .tgz    - tar with gzip
  .tar.bz2, .tbz2  - tar with bzip2
  .tar.xz, .txz    - tar with xz
  .tar             - tar only
  .gz              - gzip (single file)
  .bz2             - bzip2 (single file)
  .xz              - xz (single file)
  .zip             - zip
  .7z              - 7zip
EOF
    return 1
  fi
  
  local output="$1"
  shift
  
  case "$output" in
    *.tar.gz|*.tgz)   tar -czvf "$output" "$@" ;;
    *.tar.bz2|*.tbz2) tar -cjvf "$output" "$@" ;;
    *.tar.xz|*.txz)   tar -cJvf "$output" "$@" ;;
    *.tar)            tar -cvf "$output" "$@" ;;
    *.gz)
      [[ $# -eq 1 ]] || { echo "gzip: single file only"; return 1; }
      gzip -c "$1" > "$output"
      ;;
    *.bz2)
      [[ $# -eq 1 ]] || { echo "bzip2: single file only"; return 1; }
      bzip2 -c "$1" > "$output"
      ;;
    *.xz)
      [[ $# -eq 1 ]] || { echo "xz: single file only"; return 1; }
      xz -c "$1" > "$output"
      ;;
    *.zip) zip -r "$output" "$@" ;;
    *.7z)  7z a "$output" "$@" ;;
    *)
      echo "Error: Unsupported format"
      return 1
      ;;
  esac
  
  if [[ $? -eq 0 ]]; then
    echo "Created: $output"
    du -sh "$output"
  else
    echo "Compression failed"
    return 1
  fi
}

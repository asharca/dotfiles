#!/usr/bin/env zsh
# Archive Functions

# Extract a single-stream archive without deleting the source or overwriting a file.
_zsh_extract_stream() {
  emulate -L zsh

  local file="$1"
  local target_dir="$2"
  local suffix="$3"
  shift 3

  local name="${file:t}"
  local output_name="${name%$suffix}"
  local output="$target_dir/$output_name"
  local tmp exit_status

  {
    if [[ -z "$output_name" ]]; then
      print -u2 -- "Error: Cannot determine an output name for '$file'"
      return 1
    fi

    if [[ -e "$output" || -L "$output" ]]; then
      print -u2 -- "Error: Refusing to overwrite '$output'"
      return 1
    fi

    tmp="$(command mktemp "$target_dir/.extract.XXXXXXXXXX")" || {
      print -u2 -- "Error: Could not create a temporary file in '$target_dir'"
      return 1
    }

    command "$@" -- "$file" >| "$tmp"
    exit_status=$?
    (( exit_status == 0 )) || return $exit_status

    # A hard link publishes the completed file atomically and fails if output
    # appeared after the check above. The temporary file is on the same volume.
    if ! command ln -- "$tmp" "$output"; then
      print -u2 -- "Error: Refusing to overwrite '$output'"
      return 1
    fi
  } always {
    [[ -n "$tmp" ]] && command rm -f -- "$tmp"
  }
}

# Extract various archive types.
extract() {
  emulate -L zsh

  if (( $# < 1 || $# > 2 )); then
    command cat <<'EOF'
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
    return 2
  fi

  local file="$1"
  local target_dir="${2:-.}"
  local exit_status

  if [[ ! -f "$file" ]]; then
    print -u2 -- "Error: '$file' is not a valid file"
    return 1
  fi

  if ! command mkdir -p -- "$target_dir"; then
    print -u2 -- "Error: Could not create target directory '$target_dir'"
    return 1
  fi

  case "$file" in
    (*.tar.bz2|*.tbz2) command tar -xkjf "$file" -C "$target_dir" ;;
    (*.tar.gz|*.tgz)   command tar -xkzf "$file" -C "$target_dir" ;;
    (*.tar.xz|*.txz)   command tar -xkJf "$file" -C "$target_dir" ;;
    (*.tar)            command tar -xkf "$file" -C "$target_dir" ;;
    (*.bz2)            _zsh_extract_stream "$file" "$target_dir" '.bz2' bzip2 -dc ;;
    (*.gz)             _zsh_extract_stream "$file" "$target_dir" '.gz' gzip -dc ;;
    (*.xz)             _zsh_extract_stream "$file" "$target_dir" '.xz' xz -dc ;;
    (*.Z)              _zsh_extract_stream "$file" "$target_dir" '.Z' uncompress -c ;;
    (*.rar)            command unrar x -o- "$file" "$target_dir" ;;
    (*.zip)            command unzip -n "$file" -d "$target_dir" ;;
    (*.7z)             command 7z x -aos "$file" -o"$target_dir" ;;
    (*)
      print -u2 -- "Error: Unknown archive format"
      return 1
      ;;
  esac
  exit_status=$?

  if (( exit_status == 0 )); then
    print -- "Successfully extracted to $target_dir"
    return 0
  fi

  print -u2 -- "Extraction failed"
  return $exit_status
}

# Compress files/directories. Build outside the source tree, copy the completed
# archive into a staging directory beside the destination, then publish it with
# a same-filesystem rename.
compress() {
  emulate -L zsh

  if (( $# < 2 )); then
    command cat <<'EOF'
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
    return 2
  fi

  local output="$1"
  shift

  case "$output" in
    (*.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.txz|*.tar|*.zip|*.7z) ;;
    (*.gz|*.bz2|*.xz)
      if (( $# != 1 )); then
        print -u2 -- "Error: ${output:e} compression accepts exactly one file"
        return 2
      fi
      ;;
    (*)
      print -u2 -- "Error: Unsupported format"
      return 1
      ;;
  esac

  local output_dir="${output:h}"
  local output_name="${output:t}"
  local build_root="${TMPDIR:-/tmp}"
  local build_dir tmp_output stage_dir stage_output exit_status
  local input input_abs output_abs build_root_abs

  if [[ -z "$output_name" || ! -d "$output_dir" || -d "$output" ]]; then
    print -u2 -- "Error: Invalid output path '$output'"
    return 1
  fi

  if [[ ! -d "$build_root" || ! -w "$build_root" ]]; then
    print -u2 -- "Error: Temporary directory '$build_root' is not writable"
    return 1
  fi

  build_root_abs="${build_root:A}"
  output_abs="${output:A}"
  for input in "$@"; do
    if [[ ! -e "$input" && ! -L "$input" ]]; then
      print -u2 -- "Error: Input '$input' does not exist"
      return 1
    fi

    input_abs="${input:A}"
    if [[ "$input_abs" == "$output_abs" ]]; then
      print -u2 -- "Error: Output must not be one of the inputs: '$input'"
      return 1
    fi

    # Avoid creating the archive workspace inside a directory being archived.
    if [[ -d "$input" ]]; then
      if [[ "$input_abs" == / ]]; then
        print -u2 -- 'Error: Refusing to archive the filesystem root'
        return 1
      fi
      if [[ ( -e "$output" || -L "$output" ) && "$output_abs" == "$input_abs"/* ]]; then
        print -u2 -- "Error: Existing output is inside archived directory '$input'"
        print -u2 -- 'Move the output outside the input tree before replacing it.'
        return 1
      fi
      if [[ "$build_root_abs" == "$input_abs" || "$build_root_abs" == "$input_abs"/* ]]; then
        print -u2 -- "Error: TMPDIR must be outside archived directory '$input'"
        return 1
      fi
    fi
  done

  {
    build_dir="$(command mktemp -d "${build_root%/}/zsh-compress.XXXXXXXXXX")" || {
      print -u2 -- "Error: Could not create a temporary build directory"
      return 1
    }
    tmp_output="$build_dir/$output_name"

    case "$output" in
      (*.tar.gz|*.tgz)   command tar -czf "$tmp_output" -- "$@" ;;
      (*.tar.bz2|*.tbz2) command tar -cjf "$tmp_output" -- "$@" ;;
      (*.tar.xz|*.txz)   command tar -cJf "$tmp_output" -- "$@" ;;
      (*.tar)            command tar -cf "$tmp_output" -- "$@" ;;
      (*.gz)             command gzip -c -- "$1" >| "$tmp_output" ;;
      (*.bz2)            command bzip2 -c -- "$1" >| "$tmp_output" ;;
      (*.xz)             command xz -c -- "$1" >| "$tmp_output" ;;
      (*.zip)            command zip -r "$tmp_output" -- "$@" ;;
      (*.7z)             command 7z a "$tmp_output" -- "$@" ;;
    esac
    exit_status=$?

    if (( exit_status != 0 )); then
      print -u2 -- "Compression failed"
      return $exit_status
    fi

    stage_dir="$(command mktemp -d "$output_dir/.compress-stage.XXXXXXXXXX")" || {
      print -u2 -- "Error: Could not create a staging directory beside '$output'"
      return 1
    }
    stage_output="$stage_dir/$output_name"

    if ! command cp -p -- "$tmp_output" "$stage_output"; then
      print -u2 -- "Compression failed while staging '$output'"
      return 1
    fi

    if ! command mv -f -- "$stage_output" "$output"; then
      print -u2 -- "Compression failed while replacing '$output'"
      return 1
    fi

    print -- "Created: $output"
    command du -sh "$output" 2>/dev/null || :
    return 0
  } always {
    local cleanup_failed=0
    if [[ -n "$build_dir" && -e "$build_dir" ]]; then
      command rm -rf -- "$build_dir" || cleanup_failed=1
    fi
    if [[ -n "$stage_dir" && -e "$stage_dir" ]]; then
      command rm -rf -- "$stage_dir" || cleanup_failed=1
    fi
    (( cleanup_failed == 0 )) || print -u2 -- 'Warning: Could not remove a compression temporary directory'
  }
}

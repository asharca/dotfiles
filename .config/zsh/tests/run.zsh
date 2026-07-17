#!/usr/bin/env zsh

emulate -R zsh
setopt pipefail

typeset -gr TEST_DIR="${0:A:h}"
typeset -gr ZSH_ROOT="${TEST_DIR:h}"
typeset -gr ZSH_BIN="${commands[zsh]:A}"
typeset -gr TEST_ZSH_VERSION="$ZSH_VERSION"
typeset -gr SSH_FUNCTION_SHA256='9bc4fd93496b9d327f8fc82f82bf5a1da957ca67f948ad4dbddf89e4f58aa6b1'
typeset -g TEST_TMP=""
typeset -g _test_tmp_root="${TMPDIR:-/tmp}"
TEST_TMP="$(mktemp -d "${_test_tmp_root%/}/zsh-config-tests.XXXXXXXXXX")" || {
  print -u2 -- 'Could not create the test workspace'
  exit 1
}
unset _test_tmp_root
if [[ -z "$TEST_TMP" || ! -d "$TEST_TMP" ]]; then
  print -u2 -- 'Test workspace creation returned an invalid path'
  exit 1
fi
readonly TEST_TMP
typeset -gi TEST_COUNT=0
typeset -gi TEST_FAILURES=0

trap 'command rm -rf -- "$TEST_TMP"' EXIT

fail() {
  print -u2 -- "$*"
  return 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="${3:-values differ}"
  [[ "$actual" == "$expected" ]] || fail "$message: expected ${(qqq)expected}, got ${(qqq)actual}"
}

run_test() {
  local name="$1"
  shift
  (( TEST_COUNT += 1 ))
  if (setopt errreturn; "$@"); then
    print -- "ok $TEST_COUNT - $name"
  else
    print -- "not ok $TEST_COUNT - $name"
    (( TEST_FAILURES += 1 ))
  fi
}

test_history_secret_filter() (
  HOME="$TEST_TMP/history-home"
  mkdir -p -- "$HOME"
  source "$ZSH_ROOT/core/history.zsh"

  local line
  for line in \
    'TOKEN=dummy' \
    'GITHUBTOKEN=dummy' \
    'JWT=header.payload.signature' \
    'export API_KEY=dummy' \
    'Password=dummy' \
    'DB_PASS=dummy' \
    'curl -H "Authorization: Bearer header.payload.signature" https://example.invalid' \
    'http GET example.invalid Authorization:"Bearer header.payload.signature"' \
    'http GET example.invalid Authorization:="Bearer header.payload.signature"' \
    'http GET example.invalid Authorization:"token abcdefghijklmnop"'; do
    _history_reject_secrets "$line" && fail "history accepted sensitive command: $line"
  done

  _history_reject_secrets 'echo bearer token documentation' || fail 'history rejected a normal command'
  _history_reject_secrets 'COMPASS=west' || fail 'history rejected a normal variable ending in pass'
  [[ -o sharehistory ]] || fail 'SHARE_HISTORY should be enabled'
  [[ ! -o incappendhistory ]] || fail 'INC_APPEND_HISTORY must be disabled when SHARE_HISTORY is enabled'
)

test_compress_failure_is_atomic() (
  local case_dir="$TEST_TMP/compress-failure"
  local fake_bin="$case_dir/bin"
  local tmp_root="$case_dir/tmp"
  local output="$case_dir/existing.gz"
  local input="$case_dir/input.txt"
  local -a leftovers
  mkdir -p -- "$fake_bin" "$tmp_root"
  local TMPDIR="$tmp_root"
  print -rl -- '#!/bin/sh' 'printf partial-output' 'exit 42' >| "$fake_bin/gzip"
  chmod +x "$fake_bin/gzip"
  print -r -- 'original-output' >| "$output"
  print -r -- 'input-data' >| "$input"

  source "$ZSH_ROOT/functions/archive.zsh"
  path=("$fake_bin" $path)
  rehash

  if compress "$output" "$input" >/dev/null 2>&1; then
    fail 'compress unexpectedly succeeded'
  fi
  assert_eq 'original-output' "$(<"$output")" 'compress changed an existing output after failure'

  output="$case_dir/new.gz"
  if compress "$output" "$input" >/dev/null 2>&1; then
    fail 'compress unexpectedly succeeded for a failing compressor'
  fi
  [[ ! -e "$output" ]] || fail 'compress left a partial output after failure'

  leftovers=("$tmp_root"/zsh-compress.*(N) "$case_dir"/.compress-stage.*(N))
  (( ${#leftovers[@]} == 0 )) || fail 'compress left temporary paths after compressor failure'
)

test_compress_stage_failures_cleanup() (
  local case_dir="$TEST_TMP/compress-stage-failure"
  local cp_bin="$case_dir/cp-bin"
  local mv_bin="$case_dir/mv-bin"
  local tmp_root="$case_dir/tmp"
  local input="$case_dir/input.txt"
  local output="$case_dir/output.gz"
  local -a original_path=($path)
  local -a leftovers
  mkdir -p -- "$cp_bin" "$mv_bin" "$tmp_root"
  print -r -- 'input-data' >| "$input"
  print -r -- 'original-output' >| "$output"
  print -rl -- '#!/bin/sh' 'exit 43' >| "$cp_bin/cp"
  print -rl -- '#!/bin/sh' 'exit 44' >| "$mv_bin/mv"
  chmod +x "$cp_bin/cp" "$mv_bin/mv"

  source "$ZSH_ROOT/functions/archive.zsh"
  local TMPDIR="$tmp_root"

  path=("$cp_bin" $original_path)
  rehash
  compress "$output" "$input" >/dev/null 2>&1 && fail 'compress succeeded when staging copy failed'
  assert_eq 'original-output' "$(<"$output")" 'copy failure replaced the existing output'

  path=("$mv_bin" $original_path)
  rehash
  compress "$output" "$input" >/dev/null 2>&1 && fail 'compress succeeded when final rename failed'
  assert_eq 'original-output' "$(<"$output")" 'rename failure replaced the existing output'

  leftovers=("$tmp_root"/zsh-compress.*(N) "$case_dir"/.compress-stage.*(N))
  (( ${#leftovers[@]} == 0 )) || fail 'compress left temporary paths after staging failure'
)

test_compress_rejects_output_as_input() (
  local case_dir="$TEST_TMP/compress-same-path"
  local archive="$case_dir/report.gz"
  mkdir -p -- "$case_dir"
  print -r -- 'original archive bytes' >| "$archive"

  source "$ZSH_ROOT/functions/archive.zsh"
  compress "$archive" "$archive" >/dev/null 2>&1 && \
    fail 'compress accepted the output path as an input'
  assert_eq 'original archive bytes' "$(<"$archive")" 'same-path rejection changed the input'

  local root_output="$case_dir/root.tar.gz"
  compress "$root_output" / >/dev/null 2>&1 && \
    fail 'compress accepted the filesystem root as an input'
  [[ ! -e "$root_output" ]] || fail 'root-directory rejection created an archive'
)

test_compress_success_replaces_atomically() (
  local case_dir="$TEST_TMP/compress-success"
  local input="$case_dir/input.txt"
  local output="$case_dir/output.gz"
  mkdir -p -- "$case_dir"
  print -r -- 'new payload' >| "$input"
  print -r -- 'old payload' >| "$output"

  source "$ZSH_ROOT/functions/archive.zsh"
  compress "$output" "$input" >/dev/null || fail 'compress failed for a valid gzip input'
  assert_eq 'new payload' "$(command gzip -dc -- "$output")" 'compressed payload is incorrect'
)

test_compress_excludes_its_temporary_workspace() (
  local case_dir="$TEST_TMP/compress-tree"
  mkdir -p -- "$case_dir"
  print -r -- 'tree payload' >| "$case_dir/input.txt"

  source "$ZSH_ROOT/functions/archive.zsh"
  builtin cd -- "$case_dir" || return 1
  compress archive.tar.gz . >/dev/null 2>&1 || fail 'compress failed while archiving the current directory'
  local listing
  listing="$(command tar -tzf archive.tar.gz)" || return 1
  [[ "$listing" != *'.compress.'* && "$listing" != *'zsh-compress.'* ]] ||
    fail 'compress included its temporary workspace in the archive'

  local before_checksum
  before_checksum="$(cksum < archive.tar.gz)" || return 1
  compress archive.tar.gz . >/dev/null 2>&1 && \
    fail 'compress accepted an existing output from inside the input tree'
  assert_eq "$before_checksum" "$(cksum < archive.tar.gz)" \
    'rejected self-containing archive changed the existing output'
)

test_stream_extract_uses_target_directory() (
  (( $+commands[xz] )) || return 0

  local case_dir="$TEST_TMP/extract-xz"
  local archive_dir="$case_dir/archive"
  local target_dir="$case_dir/target"
  local input="$archive_dir/name with space.txt"
  local archive="$input.xz"
  mkdir -p -- "$archive_dir" "$target_dir"
  print -r -- 'xz payload' >| "$input"
  command xz -k -- "$input" || return 1
  command rm -f -- "$input"

  source "$ZSH_ROOT/functions/archive.zsh"
  extract "$archive" "$target_dir" >/dev/null || fail 'extract rejected a valid xz archive'
  [[ -f "$target_dir/name with space.txt" ]] || fail 'extract did not write into the target directory'
  assert_eq 'xz payload' "$(<"$target_dir/name with space.txt")" 'extracted xz payload is incorrect'
  [[ -f "$archive" ]] || fail 'extract removed the source archive'
)

test_stream_extract_failure_cleans_temporary_file() (
  local case_dir="$TEST_TMP/extract-failure"
  local fake_bin="$case_dir/bin"
  local target_dir="$case_dir/target"
  local archive="$case_dir/payload.xz"
  local -a leftovers
  mkdir -p -- "$fake_bin" "$target_dir"
  print -r -- 'not-an-archive' >| "$archive"
  print -rl -- '#!/bin/sh' 'printf partial-output' 'exit 42' >| "$fake_bin/xz"
  chmod +x "$fake_bin/xz"

  source "$ZSH_ROOT/functions/archive.zsh"
  path=("$fake_bin" $path)
  rehash
  extract "$archive" "$target_dir" >/dev/null 2>&1 && \
    fail 'extract succeeded when the stream decoder failed'
  [[ ! -e "$target_dir/payload" ]] || fail 'extract published a partial stream output'
  leftovers=("$target_dir"/.extract.*(N))
  (( ${#leftovers[@]} == 0 )) || fail 'extract left a temporary file after decoder failure'
)

test_serve_defaults_to_loopback() (
  local capture="$TEST_TMP/serve-args"
  local directory="$TEST_TMP/serve-directory"
  mkdir -p -- "$directory"
  source "$ZSH_ROOT/functions/system.zsh"
  python3() { print -rl -- "$PWD" "$@" >| "$capture"; }

  builtin cd -- "$directory" || return 1
  serve >/dev/null || fail 'serve failed with default arguments'
  local -a args=("${(@f)$(<"$capture")}")
  [[ "$args[1]" -ef "$directory" ]] || fail 'serve did not use the requested directory'
  [[ " ${(j: :)args} " == *' -m http.server '* ]] || fail 'serve did not invoke http.server'
  [[ " ${(j: :)args} " == *' --bind 127.0.0.1 '* ]] || fail 'serve did not bind to loopback by default'
  [[ " ${(j: :)args} " == *' 8000 '* ]] || fail 'serve did not use port 8000 by default'
  [[ " ${(j: :)args} " != *' --directory '* ]] || fail 'serve requires a newer Python --directory option'
)

run_completion_case() {
  local state="$1"
  local expected="$2"
  local case_dir="$TEST_TMP/completion-$state"
  local cache_dir="$case_dir/cache/zsh"
  local dump="$cache_dir/zcompdump-$TEST_ZSH_VERSION"
  local capture="$case_dir/compinit-args"
  mkdir -p -- "$case_dir/cache"

  case "$state" in
    fresh)
      mkdir -p -- "$cache_dir"
      chmod 0700 "$cache_dir"
      print -r -- 'cached completion data' >| "$dump"
      ;;
    stale)
      mkdir -p -- "$cache_dir"
      chmod 0700 "$cache_dir"
      print -r -- 'cached completion data' >| "$dump"
      touch -t 202001010000 "$dump"
      ;;
  esac

  HOME="$case_dir/home" \
  XDG_CACHE_HOME="$case_dir/cache" \
  CAPTURE="$capture" \
  COMPLETION_FILE="$ZSH_ROOT/core/completion.zsh" \
    "$ZSH_BIN" -dfc '
      before_umask="$(umask)"
      autoload() {
        if [[ " $* " == *" compinit "* ]]; then
          compinit() {
            print -r -- "$*" >| "$CAPTURE"
            typeset -gA _comps=()
          }
        else
          builtin autoload "$@"
        fi
      }
      source "$COMPLETION_FILE"
      [[ "$(umask)" == "$before_umask" ]]
    ' || return 1

  assert_eq "$expected" "$(<"$capture")" "unexpected compinit arguments for $state cache"
}

run_rejected_completion_cache_case() {
  local state="$1"
  local case_dir="$TEST_TMP/completion-rejected-$state"
  local cache_dir="$case_dir/cache/zsh"
  local dump="$cache_dir/zcompdump-$TEST_ZSH_VERSION"
  local capture="$case_dir/compinit-args"
  mkdir -p -- "$cache_dir"

  case "$state" in
    unsafe-directory)
      chmod 0755 "$cache_dir"
      ;;
    unsafe-zwc)
      chmod 0700 "$cache_dir"
      print -r -- 'safe text dump' >| "$dump"
      print -r -- 'unsafe compiled dump' >| "$dump.zwc"
      chmod 0666 "$dump.zwc"
      ;;
    *) return 2 ;;
  esac

  HOME="$case_dir/home" XDG_CACHE_HOME="$case_dir/cache" \
  CAPTURE="$capture" COMPLETION_FILE="$ZSH_ROOT/core/completion.zsh" \
    "$ZSH_BIN" -dfc '
      autoload() {
        if [[ " $* " == *" compinit "* ]]; then
          compinit() {
            print -r -- "$*" >| "$CAPTURE"
            typeset -gA _comps=()
          }
        else
          builtin autoload "$@"
        fi
      }
      source "$COMPLETION_FILE"
    ' 2>/dev/null || return 1

  assert_eq '-D' "$(<"$capture")" "unsafe $state cache did not use compinit -D"
}

test_completion_cache_policy() {
  run_completion_case missing "-d $TEST_TMP/completion-missing/cache/zsh/zcompdump-$TEST_ZSH_VERSION" || return 1
  run_completion_case fresh "-C -d $TEST_TMP/completion-fresh/cache/zsh/zcompdump-$TEST_ZSH_VERSION" || return 1
  run_completion_case stale "-d $TEST_TMP/completion-stale/cache/zsh/zcompdump-$TEST_ZSH_VERSION"
  run_rejected_completion_cache_case unsafe-directory || return 1
  run_rejected_completion_cache_case unsafe-zwc || return 1

  local capture="$TEST_TMP/completion-preinitialized"
  CAPTURE="$capture" COMPLETION_FILE="$ZSH_ROOT/core/completion.zsh" "$ZSH_BIN" -dfc '
    autoload() {
      if [[ " $* " == *" compinit "* ]]; then
        compinit() { print called >| "$CAPTURE"; }
      else
        builtin autoload "$@"
      fi
    }
    typeset -gA _comps=()
    source "$COMPLETION_FILE"
  ' || return 1
  [[ ! -e "$capture" ]] || fail 'completion initialized compinit twice'

  local blocked="$TEST_TMP/completion-blocked"
  local blocked_capture="$blocked/compinit-args"
  local blocked_style="$blocked/use-cache"
  mkdir -p -- "$blocked"
  print -r -- 'not a directory' >| "$blocked/cache-root"
  HOME="$blocked/home" XDG_CACHE_HOME="$blocked/cache-root" \
  CAPTURE="$blocked_capture" STYLE_CAPTURE="$blocked_style" \
  COMPLETION_FILE="$ZSH_ROOT/core/completion.zsh" "$ZSH_BIN" -dfc '
    autoload() {
      if [[ " $* " == *" compinit "* ]]; then
        compinit() {
          print -r -- "$*" >| "$CAPTURE"
          typeset -gA _comps=()
        }
      else
        builtin autoload "$@"
      fi
    }
    source "$COMPLETION_FILE"
    local cache_setting
    zstyle -s ":completion:*" use-cache cache_setting
    print -r -- "$cache_setting" >| "$STYLE_CAPTURE"
  ' 2>/dev/null || return 1
  assert_eq '-D' "$(<"$blocked_capture")" 'unwritable cache did not use compinit -D' || return 1
  assert_eq 'off' "$(<"$blocked_style")" 'unwritable cache left completion caching enabled'
}

test_nvm_remains_lazy_with_default_alias() (
  local case_dir="$TEST_TMP/nvm"
  local home="$case_dir/home"
  local sentinel="$case_dir/sourced"
  local args_file="$case_dir/args"
  mkdir -p -- "$home/.nvm/alias"
  print -r -- 'node' >| "$home/.nvm/alias/default"
  print -rl -- \
    'print -r -- sourced >> "$NVM_SENTINEL"' \
    'nvm() { print -r -- "$*" >| "$NVM_ARGS"; return "${NVM_FAKE_STATUS:-0}"; }' \
    >| "$home/.nvm/nvm.sh"

  HOME="$home" NVM_SENTINEL="$sentinel" NVM_ARGS="$args_file" NVM_FAKE_STATUS=37 \
  JS_FILE="$ZSH_ROOT/dev/js.zsh" "$ZSH_BIN" -dfc '
    source "$JS_FILE"
    (( $+functions[nvm] )) && [[ ! -e "$NVM_SENTINEL" ]] || exit 1
    nvm use 20
    rc=$?
    [[ $rc -eq 37 ]] || exit 2
    [[ "$(wc -l < "$NVM_SENTINEL" | tr -d " ")" == 1 ]] || exit 3
    [[ "$(<"$NVM_ARGS")" == "use 20" ]]
  ' ||
    fail 'NVM was loaded eagerly despite the lazy-loading contract'

  local bad_home="$case_dir/bad-home"
  mkdir -p -- "$bad_home/.nvm"
  print -r -- 'return 0' >| "$bad_home/.nvm/nvm.sh"
  HOME="$bad_home" JS_FILE="$ZSH_ROOT/dev/js.zsh" "$ZSH_BIN" -dfc '
    source "$JS_FILE"
    nvm >/dev/null 2>&1
    [[ $? -eq 127 ]]
  ' || fail 'NVM wrapper did not reject a broken nvm.sh'
)

test_zplug_bootstrap_rejects_broken_init() (
  local home="$TEST_TMP/zplug-broken-home"
  mkdir -p -- "$home/.zplug"
  print -rl -- \
    'zplug() { return 0; }' \
    'return 42' \
    >| "$home/.zplug/init.zsh"

  if HOME="$home" ZDOTFILES_BOOTSTRAP=1 ZPLUG_FILE="$ZSH_ROOT/preload/zplug.zsh" \
    "$ZSH_BIN" -dfc 'source "$ZPLUG_FILE"' >/dev/null 2>&1; then
    fail 'zplug bootstrap accepted an init script that returned failure'
  fi
  return 0
)

test_linux_fallbacks_do_not_require_optional_tools() {
  local empty_bin="$TEST_TMP/linux-empty-bin"
  mkdir -p -- "$empty_bin"
  EMPTY_BIN="$empty_bin" SYSTEM_ALIASES="$ZSH_ROOT/aliases/system.zsh" "$ZSH_BIN" -dfc '
    typeset -h OSTYPE=linux-gnu
    path=("$EMPTY_BIN")
    rehash
    source "$SYSTEM_ALIASES"
    (( ! ${+aliases[vi]} ))
    (( ! ${+aliases[copy]} ))
  ' || fail 'Linux fallback aliases reference unavailable nvim or clipboard tools'
}

test_homebrew_java_path_uses_detected_prefix() {
  local prefix="$TEST_TMP/linuxbrew"
  mkdir -p -- "$prefix/opt/openjdk/bin"
  HOMEBREW_PREFIX="$prefix" JAVA_FILE="$ZSH_ROOT/dev/java.zsh" "$ZSH_BIN" -dfc '
    typeset -gU path PATH
    path=(/usr/bin)
    source "$JAVA_FILE"
    [[ "$path[1]" == "$HOMEBREW_PREFIX/opt/openjdk/bin" ]]
  ' || fail 'Java path ignored the detected Homebrew/Linuxbrew prefix'
}

test_deno_user_bin_keeps_priority() {
  local home="$TEST_TMP/deno-home"
  mkdir -p -- "$home/.deno/bin"
  print -r -- 'path+=("$HOME/.deno/bin")' >| "$home/.deno/env"
  HOME="$home" JS_FILE="$ZSH_ROOT/dev/js.zsh" "$ZSH_BIN" -dfc '
    typeset -gU path PATH
    path=(/usr/bin "$HOME/.deno/bin")
    source "$JS_FILE"
    [[ "$path[1]" == "$HOME/.deno/bin" ]]
  ' || fail 'Deno user binaries remained behind system paths'
}

test_bak_trailing_slash_creates_sibling() (
  local parent="$TEST_TMP/bak"
  local directory="$parent/source"
  local -a backups nested
  mkdir -p -- "$directory"
  print -r -- 'payload' >| "$directory/file.txt"
  source "$ZSH_ROOT/functions/system.zsh"

  bak "$directory/" >/dev/null || fail 'bak rejected a directory with a trailing slash'
  backups=("$directory".bak-*(N/))
  nested=("$directory"/.bak-*(N/))
  (( ${#backups[@]} == 1 )) || fail 'bak did not create exactly one sibling backup'
  (( ${#nested[@]} == 0 )) || fail 'bak created the backup inside its source directory'
  assert_eq 'payload' "$(<"$backups[1]/file.txt")" 'bak sibling has incorrect content'
)

test_darwin_network_helpers_are_native() {
  SYSTEM_ALIASES="$ZSH_ROOT/aliases/system.zsh" "$ZSH_BIN" -dfc '
    typeset -h OSTYPE=darwin
    source "$SYSTEM_ALIASES"
    (( $+functions[localip] && $+functions[ports] ))
    [[ "$functions[localip]" != *"hostname -I"* ]]
    [[ "$functions[ports]" != *"netstat -tulan"* ]]
  ' || fail 'Darwin networking helpers use Linux-only commands'
}

test_proxy_cleanup_and_ipv6() (
  source "$ZSH_ROOT/functions/network.zsh"
  HTTP_PROXY=old HTTPS_PROXY=old ALL_PROXY=old
  export HTTP_PROXY HTTPS_PROXY ALL_PROXY
  unsetproxy >/dev/null
  [[ -z ${HTTP_PROXY+x}${HTTPS_PROXY+x}${ALL_PROXY+x} ]] || fail 'unsetproxy left uppercase proxy variables set'

  setproxy '::1' 8080 >/dev/null || fail 'setproxy rejected a valid IPv6 loopback address'
  assert_eq 'http://[::1]:8080' "$http_proxy" 'setproxy produced an invalid IPv6 proxy URL'
)

test_yazi_preserves_failure_status() (
  local case_dir="$TEST_TMP/yazi"
  local fake_bin="$case_dir/bin"
  mkdir -p -- "$fake_bin"
  print -rl -- '#!/bin/sh' 'exit 42' >| "$fake_bin/yazi"
  chmod +x "$fake_bin/yazi"

  PATH="$fake_bin:/usr/bin:/bin" YAZI_FILE="$ZSH_ROOT/plugins/yazi.zsh" "$ZSH_BIN" -dfc '
    source "$YAZI_FILE"
    y
    [[ $? -eq 42 ]]
  ' >/dev/null 2>&1 || fail 'yazi wrapper swallowed the yazi process failure status'
)

test_ssh_function_is_unchanged() {
  local file="$ZSH_ROOT/aliases/system.zsh"
  local actual
  if (( $+commands[shasum] )); then
    actual="$(sed -n '/^ssh() {$/,/^}$/p' "$file" | shasum -a 256 | awk '{print $1}')"
  elif (( $+commands[sha256sum] )); then
    actual="$(sed -n '/^ssh() {$/,/^}$/p' "$file" | sha256sum | awk '{print $1}')"
  else
    fail 'neither shasum nor sha256sum is available'
  fi
  assert_eq "$SSH_FUNCTION_SHA256" "$actual" 'ssh() changed despite the explicit exclusion'

  local runtime_definition
  runtime_definition="$("$ZSH_BIN" -i -c 'functions ssh' 2>/dev/null)" || return 1
  [[ "$runtime_definition" == *'kitty +kitten ssh "$@"'* ]] ||
    fail 'runtime startup replaced the requested Kitty ssh behavior'
  [[ "$runtime_definition" == *'command ssh "$@"'* ]] ||
    fail 'runtime startup replaced the OpenSSH fallback'
}

test_runtime_loads_plugins_without_zplug() {
  local output
  output="$("$ZSH_BIN" -i -c '
    print -r -- "zplug=$+functions[zplug]"
    print -r -- "zplug_env=$(( ${+parameters[ZPLUG_HOME]} + ${+parameters[ZPLUG_REPOS]} + ${+parameters[ZPLUG_LOADFILE]} ))"
    print -r -- "fzf_tab=$+functions[fzf-tab-complete]"
    print -r -- "autosuggest=$+functions[_zsh_autosuggest_start]"
    print -r -- "highlight=$+functions[_zsh_highlight]"
    print -r -- "k=$+functions[k]"
    print -r -- "dracula=$([[ $PROMPT == *dracula_* ]] && print 1 || print 0)"
    local -a ysu_hooks=( ${(M)preexec_functions:#_check_*aliases} )
    print -r -- "ysu_hooks=${#ysu_hooks}"
    print -r -- "completions_fpath=$(( ${fpath[(Ie)$HOME/.zplug/repos/zsh-users/zsh-completions/src]} > 0 ))"
    print -r -- "zoxide_function=$+functions[__zoxide_z_complete]"
    print -r -- "zoxide_completion=${_comps[z]-}"
    bindkey "^I"
    bindkey "^[[A"
  ' 2>/dev/null)" || return 1

  [[ "$output" == *$'zplug=0'* ]] || fail 'interactive startup still loads the zplug runtime'
  [[ "$output" == *$'zplug_env=0'* ]] || fail 'interactive startup retained stale exported zplug state'
  [[ "$output" == *$'fzf_tab=1'* ]] || fail 'fzf-tab was not loaded'
  [[ "$output" == *$'autosuggest=1'* ]] || fail 'zsh-autosuggestions was not loaded'
  [[ "$output" == *$'highlight=1'* ]] || fail 'zsh-syntax-highlighting was not loaded'
  [[ "$output" == *$'k=1'* ]] || fail 'k was not loaded'
  [[ "$output" == *$'dracula=1'* ]] || fail 'Dracula was not loaded'
  [[ "$output" == *$'ysu_hooks=3'* ]] || fail 'zsh-you-should-use hooks were not loaded exactly once'
  [[ "$output" == *$'completions_fpath=1'* ]] || fail 'zsh-completions was not added to fpath'
  if [[ "$output" == *$'zoxide_function=1'* ]]; then
    [[ "$output" == *$'zoxide_completion=__zoxide_z_complete'* ]] || \
      fail 'zoxide initialized before compinit but its completion was not registered'
  fi
  [[ "$output" == *'fzf-tab-complete'* ]] || fail 'Tab is not bound to fzf-tab'
  [[ "$output" == *'up-line-or-beginning-search'* ]] || fail 'Up arrow is not bound to prefix history search'
}

test_startup_does_not_write_zplug_trace() {
  local trace="$HOME/.zplug/log/trace.log"
  local existed=0 before_checksum=""
  if [[ -f "$trace" ]]; then
    existed=1
    before_checksum="$(cksum < "$trace")" || return 1
  fi

  "$ZSH_BIN" -i -c exit >/dev/null 2>&1 || return 1

  if (( existed )); then
    [[ -f "$trace" ]] || fail 'interactive startup removed the zplug trace log'
    local after_checksum
    after_checksum="$(cksum < "$trace")" || return 1
    assert_eq "$before_checksum" "$after_checksum" 'interactive startup changed the zplug trace log'
  else
    [[ ! -e "$trace" ]] || fail 'interactive startup created a zplug trace log'
  fi
}

test_missing_plugins_degrade_gracefully() {
  local stdout="$TEST_TMP/missing-plugins.stdout"
  local stderr="$TEST_TMP/missing-plugins.stderr"
  ZSH_PLUGIN_ROOT="$TEST_TMP/no-plugins" "$ZSH_BIN" -i -c 'print -r -- shell-alive' \
    >| "$stdout" 2>| "$stderr" || fail 'shell failed when optional plugins were absent'
  assert_eq 'shell-alive' "$(<"$stdout")" 'shell did not finish startup without plugins'
  local warning_count="$(command grep -c 'optional plugins unavailable' "$stderr" 2>/dev/null || :)"
  assert_eq 1 "${warning_count:-0}" 'missing plugins were not summarized in one warning'
  local plugin
  for plugin in zsh-completions dracula k zsh-you-should-use fzf-tab zsh-autosuggestions zsh-syntax-highlighting; do
    command grep -q -- "$plugin" "$stderr" || fail "missing-plugin warning omitted $plugin"
  done
}

run_test 'history rejects exact secret names and Bearer credentials' test_history_secret_filter
run_test 'compress failures preserve existing output' test_compress_failure_is_atomic
run_test 'compress stage failures preserve output and clean temporary paths' test_compress_stage_failures_cleanup
run_test 'compress rejects using its output as an input' test_compress_rejects_output_as_input
run_test 'compress success replaces output with valid data' test_compress_success_replaces_atomically
run_test 'compress does not archive its own temporary workspace' test_compress_excludes_its_temporary_workspace
run_test 'single-stream extraction honors the target directory' test_stream_extract_uses_target_directory
run_test 'failed stream extraction removes temporary output' test_stream_extract_failure_cleans_temporary_file
run_test 'serve binds to loopback by default' test_serve_defaults_to_loopback
run_test 'completion cache selects full or cached compinit correctly' test_completion_cache_policy
run_test 'NVM remains lazy when a default alias exists' test_nvm_remains_lazy_with_default_alias
run_test 'zplug bootstrap rejects a broken init script' test_zplug_bootstrap_rejects_broken_init
run_test 'Linux fallbacks require only installed tools' test_linux_fallbacks_do_not_require_optional_tools
run_test 'Java uses the detected Homebrew or Linuxbrew prefix' test_homebrew_java_path_uses_detected_prefix
run_test 'Deno user binaries stay ahead of system paths' test_deno_user_bin_keeps_priority
run_test 'bak handles a trailing directory slash safely' test_bak_trailing_slash_creates_sibling
run_test 'Darwin network helpers use native commands' test_darwin_network_helpers_are_native
run_test 'proxy helpers clean both cases and support IPv6' test_proxy_cleanup_and_ipv6
run_test 'Yazi wrapper preserves command failures' test_yazi_preserves_failure_status
run_test 'ssh function remains unchanged' test_ssh_function_is_unchanged
run_test 'runtime loads plugins without zplug' test_runtime_loads_plugins_without_zplug
run_test 'interactive startup does not write zplug logs' test_startup_does_not_write_zplug_trace
run_test 'missing plugins degrade with one warning' test_missing_plugins_degrade_gracefully

print -- "1..$TEST_COUNT"
if (( TEST_FAILURES > 0 )); then
  print -u2 -- "$TEST_FAILURES test(s) failed"
  exit 1
fi

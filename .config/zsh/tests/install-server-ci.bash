#!/usr/bin/env bash

set -Eeuo pipefail
umask 077

fail() {
  printf 'install-server-ci: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || fail "expected '$text' in $file"
}

assert_not_contains() {
  local file="$1"
  local text="$2"
  if grep -Fq -- "$text" "$file"; then
    fail "unexpected '$text' in $file"
  fi
}

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd)"
INSTALLER="${1:-}"

[[ -n "$INSTALLER" && -r "$INSTALLER" ]] || \
  fail 'usage: install-server-ci.bash <cfg-install.sh>'

if [[ "$(uname -s)" == Darwin && -x /bin/bash ]]; then
  REAL_BASH=/bin/bash
else
  REAL_BASH="$(command -v bash)"
fi
REAL_GIT="$(command -v git)"
REAL_ZSH="$(command -v zsh)"
[[ -x "$REAL_BASH" && -x "$REAL_GIT" && -x "$REAL_ZSH" ]] || \
  fail 'bash, git, and zsh are required'

TEST_PARENT="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
TEST_ROOT="$(mktemp -d "${TEST_PARENT%/}/dotfiles-server-ci.XXXXXXXXXX")"

cleanup() {
  case "$TEST_ROOT" in
    (*/dotfiles-server-ci.*) rm -rf -- "$TEST_ROOT" ;;
    (*) printf 'install-server-ci: refusing to remove %s\n' "$TEST_ROOT" >&2 ;;
  esac
}
trap cleanup EXIT

mkdir -p -- "$TEST_ROOT/tmp"

if "$REAL_GIT" -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  SOURCE_GIT=("$REAL_GIT" -C "$REPO_ROOT")
else
  DOTFILES_GIT_DIR="${DOTFILES_GIT_DIR:-$HOME/.cfg}"
  SOURCE_GIT=("$REAL_GIT" --git-dir="$DOTFILES_GIT_DIR" --work-tree="$REPO_ROOT")
fi

SOURCE_COMMIT="$("${SOURCE_GIT[@]}" rev-parse HEAD)"
SOURCE_REPO="$TEST_ROOT/source.git"
"$REAL_GIT" init --bare --quiet "$SOURCE_REPO"
"${SOURCE_GIT[@]}" push --quiet "$SOURCE_REPO" \
  "$SOURCE_COMMIT:refs/heads/main"
"$REAL_GIT" --git-dir="$SOURCE_REPO" symbolic-ref HEAD refs/heads/main

create_fake_prefix() {
  local prefix="$1"
  local omitted_tool="${2:-}"
  local tool

  mkdir -p -- "$prefix/bin" "$prefix/shell"

  command cat > "$prefix/bin/tool-shim" <<'EOF'
#!/bin/sh
name=${0##*/}

audit_forbidden() {
  printf '%s %s\n' "$name" "$*" >> "${CFG_CI_AUDIT_LOG:?}"
  exit 97
}

case "$name" in
  column)
    cat
    ;;
  python3)
    printf 'Python 3.12.0\n'
    ;;
  nvim)
    printf 'NVIM v0.11.0\n'
    ;;
  tmux)
    if [ "${1:-}" = '-V' ]; then
      printf 'tmux 3.5\n'
    else
      audit_forbidden "$@"
    fi
    ;;
  go)
    printf 'go version go1.24.0 ci\n'
    ;;
  node)
    printf 'v22.0.0\n'
    ;;
  npm)
    if [ "${1:-}" = 'install' ]; then
      audit_forbidden "$@"
    fi
    printf '10.0.0\n'
    ;;
  fd)
    printf 'fd 10.0.0\n'
    ;;
  fzf)
    printf '0.60.0\n'
    ;;
  uv)
    if [ "${1:-}" = 'tool' ] && [ "${2:-}" = 'install' ]; then
      audit_forbidden "$@"
    elif [ "${1:-}" = '--version' ]; then
      printf 'uv 0.8.0\n'
    fi
    ;;
  zoxide)
    # Runtime initialization is intentionally empty in this fixture.
    ;;
  *)
    ;;
esac
EOF
  chmod 0755 "$prefix/bin/tool-shim"

  for tool in \
    make python3 nvim tmux unzip go node npm fd fzf wget \
    rg bat eza zoxide tldr tree jq yazi lazygit delta duf procs dust btop \
    httpie glow fastfetch hyperfine croc ncdu luarocks uv trash-put column; do
    [[ "$tool" == "$omitted_tool" ]] && continue
    ln -s tool-shim "$prefix/bin/$tool"
  done

  command cat > "$prefix/bin/brew" <<'EOF'
#!/bin/sh
prefix=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

case "${1:-}" in
  shellenv)
    printf 'export HOMEBREW_PREFIX="%s"\n' "$prefix"
    printf 'export HOMEBREW_CELLAR="%s/Cellar"\n' "$prefix"
    printf 'export HOMEBREW_REPOSITORY="%s"\n' "$prefix"
    printf 'export PATH="%s/bin:$PATH"\n' "$prefix"
    ;;
  --version)
    printf 'Homebrew 4.0.0-ci\n'
    ;;
  list)
    ;;
  install)
    printf 'brew install %s\n' "${2:-missing}" >> "${CFG_CI_AUDIT_LOG:?}"
    if [ -n "${CFG_CI_FAIL_FORMULA:-}" ] && \
       [ "${2:-}" = "$CFG_CI_FAIL_FORMULA" ]; then
      exit 42
    fi
    if [ -n "${CFG_CI_ALLOW_FORMULA:-}" ] && \
       [ "${2:-}" = "$CFG_CI_ALLOW_FORMULA" ]; then
      ln -s tool-shim "$prefix/bin/$2"
      exit 0
    fi
    exit 96
    ;;
  *)
    printf 'unexpected brew invocation: %s\n' "$*" >> "${CFG_CI_AUDIT_LOG:?}"
    exit 95
    ;;
esac
EOF
  chmod 0755 "$prefix/bin/brew"

  command cat > "$prefix/bin/guard-shim" <<'EOF'
#!/bin/sh
printf '%s %s\n' "${0##*/}" "$*" >> "${CFG_CI_AUDIT_LOG:?}"
exit 94
EOF
  chmod 0755 "$prefix/bin/guard-shim"
  ln -s guard-shim "$prefix/bin/chsh"
  ln -s guard-shim "$prefix/bin/sudo"

  : > "$prefix/shell/completion.zsh"
  : > "$prefix/shell/key-bindings.zsh"
}

create_plugin_fixture() {
  local home="$1"
  local repos="$home/.zplug/repos"

  mkdir -p -- \
    "$home/.zplug" \
    "$repos/dracula/zsh" \
    "$repos/zsh-users/zsh-completions/src" \
    "$repos/supercrabtree/k" \
    "$repos/MichaelAquilina/zsh-you-should-use" \
    "$repos/Aloxaf/fzf-tab" \
    "$repos/zsh-users/zsh-autosuggestions" \
    "$repos/zsh-users/zsh-syntax-highlighting" \
    "$home/.tmux/plugins/tpm/bin"

  command cat > "$home/.zplug/init.zsh" <<'EOF'
if [[ -p /dev/stdin ]]; then
  print -u2 -- 'zplug fixture received FIFO stdin'
  return 90
fi
zplug() {
  case "${1:-}" in
    (check) [[ -f "$ZPLUG_HOME/ci-install-complete" ]] ;;
    (install) : > "$ZPLUG_HOME/ci-install-complete" ;;
    (*) return 0 ;;
  esac
}
EOF

  command cat > "$repos/dracula/zsh/dracula.zsh-theme" <<'EOF'
PROMPT='dracula_ci '
EOF
  command cat > "$repos/supercrabtree/k/k.sh" <<'EOF'
k() { :; }
EOF
  command cat > "$repos/MichaelAquilina/zsh-you-should-use/you-should-use.plugin.zsh" <<'EOF'
_check_global_aliases() { :; }
_check_aliases() { :; }
_check_git_aliases() { :; }
typeset -ga preexec_functions
preexec_functions+=(
  _check_global_aliases
  _check_aliases
  _check_git_aliases
)
EOF
  command cat > "$repos/Aloxaf/fzf-tab/fzf-tab.plugin.zsh" <<'EOF'
fzf-tab-complete() { :; }
EOF
  command cat > "$repos/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" <<'EOF'
_zsh_autosuggest_start() { :; }
EOF
  command cat > "$repos/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh" <<'EOF'
_zsh_highlight() { :; }
EOF

  command cat > "$home/.tmux/plugins/tpm/tpm" <<'EOF'
#!/bin/sh
exit 0
EOF
  command cat > "$home/.tmux/plugins/tpm/bin/install_plugins" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod 0755 \
    "$home/.tmux/plugins/tpm/tpm" \
    "$home/.tmux/plugins/tpm/bin/install_plugins"
}

case_environment() {
  local home="$1"
  local prefix="$2"

  CASE_ENV=(
    "HOME=$home"
    "PATH=$prefix/bin:/usr/bin:/bin"
    "SHELL=$REAL_ZSH"
    "TERM=xterm-256color"
    "TMPDIR=$TEST_ROOT/tmp"
    "XDG_CACHE_HOME=$home/.cache"
    "HOMEBREW_PREFIX=$prefix"
    "CFG_CI_AUDIT_LOG=$prefix/audit.log"
    "CFG_REPO_URL=$SOURCE_REPO"
    "CFG_EXPECTED_COMMIT=$SOURCE_COMMIT"
  )
}

PIPE_HOME="$TEST_ROOT/pipe-home"
PIPE_PREFIX="$TEST_ROOT/pipe-brew"
PIPE_LOG="$TEST_ROOT/pipe-install.log"
RERUN_LOG="$TEST_ROOT/file-rerun.log"
STARTUP_LOG="$TEST_ROOT/startup.log"
TEST_LOG="$TEST_ROOT/zsh-tests.log"

mkdir -p -- "$PIPE_HOME" "$PIPE_HOME/.cache"
create_fake_prefix "$PIPE_PREFIX" croc
create_plugin_fixture "$PIPE_HOME"
: > "$PIPE_PREFIX/audit.log"
case_environment "$PIPE_HOME" "$PIPE_PREFIX"
CASE_ENV+=("CFG_CI_ALLOW_FORMULA=croc")

assert_contains "$INSTALLER" \
  'run_with_isolated_git_config "$zsh_bin" "$bootstrap_file" "$MODE" </dev/null'

if ! command cat "$INSTALLER" | \
  env "${CASE_ENV[@]}" "$REAL_BASH" -s -- server > "$PIPE_LOG" 2>&1; then
  command cat "$PIPE_LOG" >&2
  fail 'curl-pipe style server installation failed'
fi

assert_contains "$PIPE_LOG" 'Mode: server'
assert_contains "$PIPE_LOG" '[server mode]'
assert_not_contains "$PIPE_LOG" 'Dev-only Tools'
assert_not_contains "$PIPE_LOG" 'zplug fixture received FIFO stdin'
[[ "$(<"$PIPE_PREFIX/audit.log")" == 'brew install croc' ]] || {
  command cat "$PIPE_PREFIX/audit.log" >&2
  fail 'server installation did not perform only the expected fake brew install'
}
[[ -f "$PIPE_HOME/.zplug/ci-install-complete" ]] || \
  fail 'server installation did not exercise zplug install'

[[ "$("$REAL_GIT" --git-dir="$PIPE_HOME/.cfg" rev-parse --is-bare-repository)" == true ]] || \
  fail 'installer did not publish a bare ~/.cfg'
[[ "$("$REAL_GIT" --git-dir="$PIPE_HOME/.cfg" rev-parse HEAD)" == "$SOURCE_COMMIT" ]] || \
  fail 'installed commit does not match CFG_EXPECTED_COMMIT'
[[ "$("$REAL_GIT" --git-dir="$PIPE_HOME/.cfg" config --get remote.origin.url)" == "$SOURCE_REPO" ]] || \
  fail 'installed origin does not match CFG_REPO_URL'
[[ -r "$PIPE_HOME/.zshrc" && -r "$PIPE_HOME/.config/zsh/preload/plugins.zsh" ]] || \
  fail 'dotfiles checkout is incomplete'
[[ ! -e "$PIPE_HOME/.cfg-install.lock" ]] || fail 'installer lock was not cleaned up'

shopt -s nullglob
leftovers=("$PIPE_HOME"/.cfg-install.*)
(( ${#leftovers[@]} == 0 )) || fail 'installer left temporary directories behind'
shopt -u nullglob

if ! env "${CASE_ENV[@]}" "$REAL_BASH" "$INSTALLER" server > "$RERUN_LOG" 2>&1; then
  command cat "$RERUN_LOG" >&2
  fail 'file-based idempotent server rerun failed'
fi
assert_contains "$RERUN_LOG" 'Using existing dotfiles repository'
assert_not_contains "$RERUN_LOG" 'Dev-only Tools'
[[ "$(<"$PIPE_PREFIX/audit.log")" == 'brew install croc' ]] || \
  fail 'idempotent rerun invoked an additional package or guarded command'

if ! env "${CASE_ENV[@]}" "$REAL_ZSH" -lic exit > "$STARTUP_LOG" 2>&1; then
  command cat "$STARTUP_LOG" >&2
  fail 'installed login shell failed to start'
fi
assert_not_contains "$STARTUP_LOG" 'optional plugins unavailable'

if ! env "${CASE_ENV[@]}" \
  "$REAL_ZSH" "$PIPE_HOME/.config/zsh/tests/run.zsh" > "$TEST_LOG" 2>&1; then
  command cat "$TEST_LOG" >&2
  fail 'installed Zsh regression suite failed'
fi
grep -Eq '^1\.\.[1-9][0-9]*$' "$TEST_LOG" || \
  fail 'Zsh regression suite did not report a nonzero TAP plan'

# The repository bootstrap must also be safe when called by another piped wrapper.
DIRECT_HOME="$TEST_ROOT/direct-home"
DIRECT_PREFIX="$TEST_ROOT/direct-brew"
DIRECT_LOG="$TEST_ROOT/direct-bootstrap.log"
mkdir -p -- "$DIRECT_HOME/.config"
ln -s "$REPO_ROOT/.config/zsh" "$DIRECT_HOME/.config/zsh"
create_fake_prefix "$DIRECT_PREFIX"
create_plugin_fixture "$DIRECT_HOME"
: > "$DIRECT_PREFIX/audit.log"
case_environment "$DIRECT_HOME" "$DIRECT_PREFIX"

if ! printf '' | env "${CASE_ENV[@]}" "$REAL_ZSH" \
  "$REPO_ROOT/.config/zsh/bootstrap/install.zsh" server > "$DIRECT_LOG" 2>&1; then
  command cat "$DIRECT_LOG" >&2
  fail 'repository bootstrap failed with FIFO stdin'
fi
assert_not_contains "$DIRECT_LOG" 'zplug fixture received FIFO stdin'
[[ ! -s "$DIRECT_PREFIX/audit.log" ]] || {
  command cat "$DIRECT_PREFIX/audit.log" >&2
  fail 'direct repository bootstrap invoked a forbidden command'
}

# Required tools must make the bootstrap fail rather than print a false success.
FAIL_HOME="$TEST_ROOT/failure-home"
FAIL_PREFIX="$TEST_ROOT/failure-brew"
FAIL_LOG="$TEST_ROOT/required-failure.log"
failure_tool=''
failure_formula=''
for candidate in 'nvim:neovim' 'fd:fd' 'fzf:fzf' 'go:go' 'node:node'; do
  tool=${candidate%%:*}
  formula=${candidate#*:}
  if ! PATH=/usr/bin:/bin command -v "$tool" >/dev/null 2>&1; then
    failure_tool="$tool"
    failure_formula="$formula"
    break
  fi
done
[[ -n "$failure_tool" ]] || fail 'could not find an isolated required-tool failure case'

mkdir -p -- "$FAIL_HOME/.config"
ln -s "$REPO_ROOT/.config/zsh" "$FAIL_HOME/.config/zsh"
create_fake_prefix "$FAIL_PREFIX" "$failure_tool"
create_plugin_fixture "$FAIL_HOME"
: > "$FAIL_PREFIX/audit.log"
case_environment "$FAIL_HOME" "$FAIL_PREFIX"
CASE_ENV+=("CFG_CI_FAIL_FORMULA=$failure_formula")

if env "${CASE_ENV[@]}" "$REAL_ZSH" \
  "$REPO_ROOT/.config/zsh/bootstrap/install.zsh" server > "$FAIL_LOG" 2>&1; then
  command cat "$FAIL_LOG" >&2
  fail "bootstrap succeeded after required $failure_tool installation failed"
fi
assert_contains "$FAIL_LOG" 'Failed to install required tools'
assert_contains "$FAIL_LOG" "$failure_tool"

printf 'install-server-ci: ok (%s, %s)\n' "$(uname -s)" "$SOURCE_COMMIT"

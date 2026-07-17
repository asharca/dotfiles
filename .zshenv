# Keep search paths deterministic across every zsh invocation, including
# non-interactive shells.
typeset -gU path PATH
typeset -gU fpath FPATH

_zshenv_path_prepend() {
  [[ -d "$1" ]] && path=("$1" $path)
}

# zerobrew
export ZEROBREW_DIR="$HOME/.zerobrew"
export ZEROBREW_BIN="$ZEROBREW_DIR/bin"
export ZEROBREW_ROOT="/opt/zerobrew"
export ZEROBREW_PREFIX="$ZEROBREW_ROOT/prefix"

if [[ -d "$ZEROBREW_PREFIX/lib/pkgconfig" ]]; then
  case ":${PKG_CONFIG_PATH:-}:" in
    *:"$ZEROBREW_PREFIX/lib/pkgconfig":*) ;;
    *) export PKG_CONFIG_PATH="$ZEROBREW_PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}" ;;
  esac
fi

# SSL/TLS certificates (only if ca-certificates is installed)
if [ -f "$ZEROBREW_PREFIX/opt/ca-certificates/share/ca-certificates/cacert.pem" ]; then
  export CURL_CA_BUNDLE="$ZEROBREW_PREFIX/opt/ca-certificates/share/ca-certificates/cacert.pem"
  export SSL_CERT_FILE="$ZEROBREW_PREFIX/opt/ca-certificates/share/ca-certificates/cacert.pem"
elif [ -f "$ZEROBREW_PREFIX/etc/ca-certificates/cacert.pem" ]; then
  export CURL_CA_BUNDLE="$ZEROBREW_PREFIX/etc/ca-certificates/cacert.pem"
  export SSL_CERT_FILE="$ZEROBREW_PREFIX/etc/ca-certificates/cacert.pem"
elif [ -f "$ZEROBREW_PREFIX/share/ca-certificates/cacert.pem" ]; then
  export CURL_CA_BUNDLE="$ZEROBREW_PREFIX/share/ca-certificates/cacert.pem"
  export SSL_CERT_FILE="$ZEROBREW_PREFIX/share/ca-certificates/cacert.pem"
fi

if [ -d "$ZEROBREW_PREFIX/etc/ca-certificates" ]; then
  export SSL_CERT_DIR="$ZEROBREW_PREFIX/etc/ca-certificates"
elif [ -d "$ZEROBREW_PREFIX/share/ca-certificates" ]; then
  export SSL_CERT_DIR="$ZEROBREW_PREFIX/share/ca-certificates"
fi

# Static tool paths avoid sourcing scripts or executing `brew shellenv` in
# every shell. Later additions intentionally receive higher priority.
_zshenv_path_prepend "$HOME/.cargo/bin"
_zshenv_path_prepend "$ZEROBREW_BIN"
_zshenv_path_prepend "$ZEROBREW_PREFIX/bin"

# Homebrew supports four common layouts: Apple Silicon, Intel macOS,
# system-wide Linuxbrew, and a per-user Linuxbrew install.
typeset _homebrew_prefix=""
for _homebrew_candidate in \
  "${HOMEBREW_PREFIX:-}" \
  /opt/homebrew \
  /usr/local \
  /home/linuxbrew/.linuxbrew \
  "$HOME/.linuxbrew"; do
  if [[ -x "$_homebrew_candidate/bin/brew" ]]; then
    _homebrew_prefix="$_homebrew_candidate"
    break
  fi
done

if [[ -n "$_homebrew_prefix" ]]; then
  export HOMEBREW_PREFIX="$_homebrew_prefix"
  export HOMEBREW_CELLAR="$_homebrew_prefix/Cellar"
  if [[ -d "$_homebrew_prefix/Homebrew" ]]; then
    export HOMEBREW_REPOSITORY="$_homebrew_prefix/Homebrew"
  else
    export HOMEBREW_REPOSITORY="$_homebrew_prefix"
  fi

  _zshenv_path_prepend "$_homebrew_prefix/sbin"
  _zshenv_path_prepend "$_homebrew_prefix/bin"
  [[ -d "$_homebrew_prefix/share/zsh/site-functions" ]] && \
    fpath=("$_homebrew_prefix/share/zsh/site-functions" $fpath)
  case ":${INFOPATH:-}:" in
    *:"$_homebrew_prefix/share/info":*) ;;
    *) export INFOPATH="$_homebrew_prefix/share/info:${INFOPATH:-}" ;;
  esac
fi

# uv installs executables here on current releases.
_zshenv_path_prepend "$HOME/.local/bin"

unset _homebrew_prefix _homebrew_candidate
unfunction _zshenv_path_prepend

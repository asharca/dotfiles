#!/usr/bin/env zsh
# Bootstrap installation script for essential tools

typeset -gU path PATH

echo "==================================="
echo "  ZSH Configuration Bootstrap"
echo "==================================="
echo ""

# ============================================
# 0. Determine install mode
# ============================================
INSTALL_MODE="${1:-}"

if [[ -z "$INSTALL_MODE" ]]; then
  echo "Select installation mode:"
  echo "  server  - All tools except dev-only (no claude-code / rtk / yt-dlp)"
  echo "  dev     - Full setup, all tools"
  echo ""
  printf "Mode [server/dev]: "
  read INSTALL_MODE
  echo ""
fi

case "$INSTALL_MODE" in
  server|dev) ;;
  *)
    echo "Error: Invalid mode '$INSTALL_MODE'. Use 'server' or 'dev'."
    exit 1
    ;;
esac

echo "Mode: $INSTALL_MODE"
echo ""

# ============================================
# 1. Install Homebrew
# ============================================
activate_homebrew() {
  local prefix
  local -a candidates=(
    "${HOMEBREW_PREFIX:-}"
    /opt/homebrew
    /usr/local
    /home/linuxbrew/.linuxbrew
    "$HOME/.linuxbrew"
  )

  for prefix in "${candidates[@]}"; do
    [[ -n "$prefix" && -x "$prefix/bin/brew" ]] || continue

    export HOMEBREW_PREFIX="$prefix"
    export HOMEBREW_CELLAR="$prefix/Cellar"
    if [[ -d "$prefix/Homebrew" ]]; then
      export HOMEBREW_REPOSITORY="$prefix/Homebrew"
    else
      export HOMEBREW_REPOSITORY="$prefix"
    fi
    [[ -d "$prefix/sbin" ]] && path=("$prefix/sbin" $path)
    path=("$prefix/bin" $path)
    case ":${INFOPATH:-}:" in
      *:"$prefix/share/info":*) ;;
      *) export INFOPATH="$prefix/share/info:${INFOPATH:-}" ;;
    esac
    rehash
    return 0
  done

  return 1
}

install_homebrew() {
  activate_homebrew >/dev/null 2>&1

  if (( $+commands[brew] )); then
    echo "✓ Homebrew already installed"
    brew --version
    return 0
  fi

  echo "Installing Homebrew..."
  echo ""

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # The installer cannot alter this already-running zsh. Activate the standard
  # prefix immediately; future shells use the static setup in ~/.zshenv.
  activate_homebrew

  if (( $+commands[brew] )); then
    echo "✓ Homebrew installed successfully"
    brew --version
    return 0
  else
    echo "✗ Homebrew installation failed"
    return 1
  fi
}

echo "Checking Homebrew installation..."
install_homebrew
if [[ $? -ne 0 ]]; then
  echo ""
  echo "Error: Homebrew installation failed. Exiting."
  exit 1
fi

echo ""

# ============================================
# 2. Helper: install a brew tool
# ============================================
install_tool() {
  local tool="$1"
  local brew_name="${2:-$tool}"

  if (( $+commands[$tool] )); then
    echo "✓ $tool already installed"
    return 0
  fi

  echo "Installing $tool..."
  if brew install "$brew_name"; then
    rehash
    echo "✓ $tool installed"
    return 0
  else
    echo "✗ Failed to install $tool"
    return 1
  fi
}

# ============================================
# 3. Essential Tools (both modes)
# ============================================
echo "==================================="
echo "  Essential Tools"
echo "==================================="
echo ""

declare -A ESSENTIAL_TOOLS=(
  ["git"]="git"
  ["make"]="make"
  ["python3"]="python3"
  ["nvim"]="neovim"
  ["tmux"]="tmux"
  ["zsh"]="zsh"
  ["unzip"]="unzip"
  ["go"]="go"
  ["node"]="node"
  ["npm"]="node"
  ["fd"]="fd"
  ["fzf"]="fzf"
  ["curl"]="curl"
  ["wget"]="wget"
)

for cmd in ${(k)ESSENTIAL_TOOLS}; do
  [[ "$cmd" == "npm" ]] && continue
  install_tool "$cmd" "${ESSENTIAL_TOOLS[$cmd]}"
done

echo ""

# ============================================
# 4. Verify Essential Tools
# ============================================
echo "==================================="
echo "  Verifying Essential Tools"
echo "==================================="
echo ""

MISSING_TOOLS=()

for cmd in ${(k)ESSENTIAL_TOOLS}; do
  if (( $+commands[$cmd] )); then
    case $cmd in
      git)     version=$(git --version 2>/dev/null | cut -d' ' -f3) ;;
      python3) version=$(python3 --version 2>/dev/null | cut -d' ' -f2) ;;
      nvim)    version=$(nvim --version 2>/dev/null | head -n1 | cut -d' ' -f2 | sed 's/v//') ;;
      tmux)    version=$(tmux -V 2>/dev/null | cut -d' ' -f2) ;;
      zsh)     version=$(zsh --version 2>/dev/null | cut -d' ' -f2) ;;
      go)      version=$(go version 2>/dev/null | cut -d' ' -f3 | sed 's/go//') ;;
      node)    version=$(node --version 2>/dev/null | sed 's/v//') ;;
      npm)     version=$(npm --version 2>/dev/null) ;;
      fd)      version=$(fd --version 2>/dev/null | cut -d' ' -f2) ;;
      fzf)     version=$(fzf --version 2>/dev/null | cut -d' ' -f1) ;;
      *)       version="installed" ;;
    esac
    echo "✓ $cmd - v$version"
  else
    echo "✗ $cmd - FAILED"
    MISSING_TOOLS+=("$cmd")
  fi
done

echo ""

if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
  echo "⚠️  Failed to install: ${(j:, :)MISSING_TOOLS}"
  echo "   Try manually: brew install ${(j: :)MISSING_TOOLS}"
  echo ""
fi

# ============================================
# 5. Common Recommended Tools (both modes)
# ============================================
echo "==================================="
echo "  Recommended Tools"
echo "==================================="
echo ""

declare -A COMMON_TOOLS=(
  ["rg"]="ripgrep"
  ["bat"]="bat"
  ["eza"]="eza"
  ["zoxide"]="zoxide"
  ["tldr"]="tlrc"
  ["tree"]="tree"
  ["jq"]="jq"
  ["yazi"]="yazi"
  ["lazygit"]="lazygit"
  ["delta"]="git-delta"
  ["duf"]="duf"
  ["procs"]="procs"
  ["dust"]="dust"
  ["btop"]="btop"
  ["httpie"]="httpie"
  ["glow"]="glow"
  ["fastfetch"]="fastfetch"
  ["hyperfine"]="hyperfine"
  ["croc"]="croc"
  ["ncdu"]="ncdu"
  ["luarocks"]="luarocks"
)

for cmd in ${(k)COMMON_TOOLS}; do
  install_tool "$cmd" "${COMMON_TOOLS[$cmd]}"
done

echo ""

# ============================================
# 6. Dev-only Tools
# ============================================
if [[ "$INSTALL_MODE" == "dev" ]]; then
  echo "==================================="
  echo "  Dev-only Tools"
  echo "==================================="
  echo ""

  install_tool "yt-dlp" "yt-dlp"
  install_tool "rtk" "rtk"

  if (( $+commands[claude] )); then
    echo "✓ claude already installed"
  else
    echo "Installing claude-code..."
    if npm install -g @anthropic-ai/claude-code; then
      echo "✓ claude-code installed"
    else
      echo "✗ Failed to install claude-code"
    fi
  fi

  echo ""
fi

# ============================================
# 7. UV (both modes)
# ============================================
echo "==================================="
echo "  Python Tools"
echo "==================================="
echo ""

if (( $+commands[uv] )); then
  echo "✓ UV already installed - $(uv --version)"
else
  echo "Installing UV..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  [[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)
  [[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
  rehash
  if (( $+commands[uv] )); then
    echo "✓ UV installed - $(uv --version)"
  else
    echo "✗ UV installation failed"
  fi
fi

echo ""

# ============================================
# 8. trash-cli (both modes)
# ============================================
if (( $+commands[trash-put] )); then
  echo "✓ trash-cli already installed"
else
  echo "Installing trash-cli..."
  if (( $+commands[uv] )); then
    uv tool install trash-cli && rehash
  else
    if brew install trash-cli; then
      [[ -d "$HOMEBREW_PREFIX/opt/trash-cli/bin" ]] && \
        path=("$HOMEBREW_PREFIX/opt/trash-cli/bin" $path)
      rehash
    fi
  fi
  rehash

  if (( $+commands[trash-put] )); then
    echo "✓ trash-cli installed"
  else
    echo "⚠ trash-cli: ensure ~/.local/bin is in PATH"
  fi
fi

echo ""

# ============================================
# 9. Post-installation Setup
# ============================================
echo "==================================="
echo "  Post-installation Setup"
echo "==================================="
echo ""

install_shell_plugins() {
  local zplug_dir="$HOME/.zplug"
  local zplug_init="$zplug_dir/init.zsh"
  local zplug_config="$HOME/.config/zsh/preload/zplug.zsh"
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  local source_rc=0
  local plugin_file
  local ZPLUG_HOME="$zplug_dir"
  local ZPLUG_BIN="$zplug_dir/bin"
  local ZPLUG_CACHE_DIR="$zplug_dir/cache"
  local ZPLUG_REPOS="$zplug_dir/repos"
  local ZPLUG_LOADFILE=/dev/null
  local ZPLUG_ERROR_LOG="$zplug_dir/.error_log"
  local ZPLUG_PROTOCOL=HTTPS
  local ZPLUG_USE_CACHE=false
  export ZPLUG_HOME ZPLUG_BIN ZPLUG_CACHE_DIR ZPLUG_REPOS ZPLUG_LOADFILE
  export ZPLUG_ERROR_LOG ZPLUG_PROTOCOL ZPLUG_USE_CACHE
  local -a runtime_plugin_files=(
    "$HOME/.zplug/repos/dracula/zsh/dracula.zsh-theme"
    "$HOME/.zplug/repos/supercrabtree/k/k.sh"
    "$HOME/.zplug/repos/MichaelAquilina/zsh-you-should-use/you-should-use.plugin.zsh"
    "$HOME/.zplug/repos/Aloxaf/fzf-tab/fzf-tab.plugin.zsh"
    "$HOME/.zplug/repos/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
    "$HOME/.zplug/repos/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"
  )

  if [[ ! -r "$zplug_init" ]]; then
    if [[ -e "$zplug_dir" ]]; then
      echo "✗ $zplug_dir exists but does not contain a readable init.zsh"
      return 1
    fi
    echo "Installing zplug..."
    git clone --depth 1 https://github.com/zplug/zplug.git "$zplug_dir" || return 1
  else
    echo "✓ zplug already installed"
  fi

  [[ -r "$zplug_config" ]] || {
    echo "✗ Missing zplug declarations: $zplug_config"
    return 1
  }

  export ZDOTFILES_BOOTSTRAP=1
  source "$zplug_config"
  source_rc=$?
  unset ZDOTFILES_BOOTSTRAP
  (( source_rc == 0 )) || return "$source_rc"

  for plugin_file in "${runtime_plugin_files[@]}"; do
    if [[ ! -r "$plugin_file" ]]; then
      echo "✗ Missing runtime plugin entrypoint: $plugin_file"
      echo "  Remove the damaged plugin repository and rerun this bootstrap."
      return 1
    fi
  done
  if [[ ! -d "$HOME/.zplug/repos/zsh-users/zsh-completions/src" ]]; then
    echo "✗ Missing runtime plugin directory: $HOME/.zplug/repos/zsh-users/zsh-completions/src"
    echo "  Remove the damaged plugin repository and rerun this bootstrap."
    return 1
  fi
  echo "✓ zplug plugins installed"

  # Plugin completions changed; force the next shell to build a fresh dump.
  local completion_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  command rm -f -- "$completion_cache"/zcompdump-*(N) \
    "$completion_cache"/zcompdump-*.zwc(N)

  if [[ ! -x "$tpm_dir/tpm" ]]; then
    if [[ -e "$tpm_dir" ]]; then
      echo "✗ $tpm_dir exists but does not contain an executable TPM"
      return 1
    fi
    echo "Installing tmux plugin manager..."
    mkdir -p "${tpm_dir:h}"
    git clone --depth 1 https://github.com/tmux-plugins/tpm.git "$tpm_dir" || return 1
  else
    echo "✓ tmux plugin manager already installed"
  fi

  if [[ -x "$tpm_dir/bin/install_plugins" ]]; then
    "$tpm_dir/bin/install_plugins" || return 1
    echo "✓ tmux plugins installed"
  fi
}

if ! install_shell_plugins; then
  echo ""
  echo "Error: shell plugin installation failed."
  exit 1
fi
unset -f install_shell_plugins

echo ""

if (( $+commands[fzf] )); then
  echo "✓ FZF native shell integration is loaded by the modular zsh config"
fi

if (( $+commands[zoxide] )); then
  echo "✓ Zoxide is loaded by the modular zsh config"
fi

if [[ "${SHELL:t}" != "zsh" ]]; then
  echo "Setting zsh as default shell..."
  target_shell="${commands[zsh]:-/bin/zsh}"

  # chsh normally accepts only entries from /etc/shells. Prefer the system zsh
  # when a newly installed Homebrew path has not been registered there.
  if [[ -r /etc/shells ]] && ! grep -Fxq "$target_shell" /etc/shells; then
    if [[ -x /bin/zsh ]] && grep -Fxq /bin/zsh /etc/shells; then
      target_shell=/bin/zsh
    else
      echo "⚠ Cannot set default shell: $target_shell is not listed in /etc/shells"
      target_shell=""
    fi
  fi

  shell_changed=0
  if [[ -n "$target_shell" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      chsh -s "$target_shell" && shell_changed=1
    else
      sudo chsh -s "$target_shell" "$USER" && shell_changed=1
    fi
  fi

  if (( shell_changed )); then
    echo "✓ Default shell set to $target_shell (restart terminal to take effect)"
  elif [[ -n "$target_shell" ]]; then
    echo "⚠ Default shell was not changed; run: chsh -s $target_shell"
  else
    echo "⚠ Default shell was not changed; register zsh in /etc/shells and retry chsh"
  fi
  unset target_shell shell_changed
else
  echo "✓ Zsh is already the default shell"
fi

echo ""

# ============================================
# 10. Summary
# ============================================
echo "==================================="
echo "  Installation Summary"
echo "==================================="
echo ""

echo "📦 Essential tools:"
for cmd in ${(k)ESSENTIAL_TOOLS}; do
  (( $+commands[$cmd] )) && echo "  ✓ $cmd"
done | column -c 80
echo ""

echo "📦 All Homebrew packages:"
brew list --formula 2>/dev/null | sort | column -c 80
echo ""

if (( $+commands[uv] )); then
  echo "🐍 UV tools:"
  uv tool list 2>/dev/null || echo "  No tools installed yet"
  echo ""
fi

echo "==================================="
echo "  Bootstrap Complete! ✨  [$INSTALL_MODE mode]"
echo "==================================="
echo ""
echo "📋 Next steps:"
echo "  1. Restart terminal or run: exec zsh"
echo "  2. Verify: which git python3 node nvim"
echo "  3. Shell config: ~/.config/zsh/"
echo ""

unfunction activate_homebrew

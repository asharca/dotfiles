#!/usr/bin/env zsh
# Bootstrap installation script for essential tools

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
install_homebrew() {
  if (( $+commands[brew] )); then
    echo "✓ Homebrew already installed"
    brew --version
    return 0
  fi

  echo "Installing Homebrew..."
  echo ""

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ "$OSTYPE" != "darwin"* ]]; then
    if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zprofile
    elif [[ -d "$HOME/.linuxbrew" ]]; then
      eval "$($HOME/.linuxbrew/bin/brew shellenv)"
      echo 'eval "$($HOME/.linuxbrew/bin/brew shellenv)"' >> ~/.zprofile
    fi
  fi

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
  ["pueue"]="pueue"
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
  export PATH="$HOME/.cargo/bin:$PATH"
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
    uv tool install trash-cli
  else
    brew install trash-cli
  fi

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

if (( $+commands[fzf] )) && [[ ! -f ~/.fzf.zsh ]]; then
  echo "Setting up FZF key bindings..."
  $(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc
  echo "✓ FZF configured"
elif (( $+commands[fzf] )); then
  echo "✓ FZF already configured"
fi

if (( $+commands[zoxide] )) && ! grep -q "zoxide init" ~/.zshrc 2>/dev/null; then
  echo "" >> ~/.zshrc
  echo "# Initialize zoxide" >> ~/.zshrc
  echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
  echo "✓ zoxide initialization added to .zshrc"
elif (( $+commands[zoxide] )); then
  echo "✓ zoxide already configured"
fi

if [[ "$SHELL" != *"zsh"* ]]; then
  echo "Setting zsh as default shell..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    chsh -s $(which zsh)
  else
    sudo chsh -s $(which zsh) $USER
  fi
  echo "✓ Default shell set to zsh (restart terminal to take effect)"
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

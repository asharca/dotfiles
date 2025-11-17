#!/usr/bin/env zsh
# Bootstrap installation script for essential tools

echo "==================================="
echo "  ZSH Configuration Bootstrap"
echo "==================================="
echo ""

# ============================================
# 1. Install Homebrew first (on all systems)
# ============================================
install_homebrew() {
  if (( $+commands[brew] )); then
    echo "✓ Homebrew already installed"
    brew --version
    return 0
  fi
  
  echo "Installing Homebrew..."
  echo ""
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    # Linux
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Linux
    if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zprofile
    elif [[ -d "$HOME/.linuxbrew" ]]; then
      eval "$($HOME/.linuxbrew/bin/brew shellenv)"
      echo 'eval "$($HOME/.linuxbrew/bin/brew shellenv)"' >> ~/.zprofile
    fi
  fi
  
  # Verify installation
  if (( $+commands[brew] )); then
    echo "✓ Homebrew installed successfully"
    brew --version
    return 0
  else
    echo "✗ Homebrew installation failed"
    return 1
  fi
}

# Install Homebrew
echo "Checking Homebrew installation..."
install_homebrew
if [[ $? -ne 0 ]]; then
  echo ""
  echo "Error: Homebrew installation failed. Exiting."
  exit 1
fi

echo ""

# ============================================
# 2. Helper function to install via brew
# ============================================
install_tool() {
  local tool="$1"
  local brew_name="${2:-$tool}"
  
  if (( $+commands[$tool] )); then
    echo "✓ $tool already installed"
    return 0
  else
    echo "Installing $tool..."
    if brew install "$brew_name"; then
      echo "✓ $tool installed successfully"
      return 0
    else
      echo "✗ Failed to install $tool"
      return 1
    fi
  fi
}

# ============================================
# 3. Install Essential Tools (必装)
# ============================================
echo "==================================="
echo "  Installing Essential Tools"
echo "==================================="
echo ""

# 定义必需工具：command_name:brew_package_name
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
  ["npm"]="node"  # npm comes with node
  ["fd"]="fd"
  ["fzf"]="fzf"
  ["curl"]="curl"
  ["wget"]="wget"
)

echo "Installing required tools automatically..."
echo ""

for cmd in ${(k)ESSENTIAL_TOOLS}; do
  brew_name="${ESSENTIAL_TOOLS[$cmd]}"
  
  # Skip npm check since it comes with node
  if [[ "$cmd" == "npm" ]]; then
    if (( $+commands[npm] )); then
      echo "✓ npm already available (installed with node)"
    fi
    continue
  fi
  
  install_tool "$cmd" "$brew_name"
done

echo ""

# ============================================
# 4. Verify Essential Tools Installation
# ============================================
echo "==================================="
echo "  Verifying Installation"
echo "==================================="
echo ""

MISSING_TOOLS=()

for cmd in ${(k)ESSENTIAL_TOOLS}; do
  if (( $+commands[$cmd] )); then
    # Get version info
    case $cmd in
      git)
        version=$(git --version 2>/dev/null | cut -d' ' -f3)
        echo "✓ $cmd - v$version"
        ;;
      python3)
        version=$(python3 --version 2>/dev/null | cut -d' ' -f2)
        echo "✓ $cmd - v$version"
        ;;
      nvim)
        version=$(nvim --version 2>/dev/null | head -n1 | cut -d' ' -f2 | sed 's/v//')
        echo "✓ $cmd - v$version"
        ;;
      tmux)
        version=$(tmux -V 2>/dev/null | cut -d' ' -f2)
        echo "✓ $cmd - v$version"
        ;;
      zsh)
        version=$(zsh --version 2>/dev/null | cut -d' ' -f2)
        echo "✓ $cmd - v$version"
        ;;
      go)
        version=$(go version 2>/dev/null | cut -d' ' -f3 | sed 's/go//')
        echo "✓ $cmd - v$version"
        ;;
      node)
        version=$(node --version 2>/dev/null | sed 's/v//')
        echo "✓ $cmd - v$version"
        ;;
      npm)
        version=$(npm --version 2>/dev/null)
        echo "✓ $cmd - v$version"
        ;;
      fd)
        version=$(fd --version 2>/dev/null | cut -d' ' -f2)
        echo "✓ $cmd - v$version"
        ;;
      fzf)
        version=$(fzf --version 2>/dev/null | cut -d' ' -f1)
        echo "✓ $cmd - v$version"
        ;;
      *)
        echo "✓ $cmd - installed"
        ;;
    esac
  else
    echo "✗ $cmd - FAILED TO INSTALL"
    MISSING_TOOLS+=("$cmd")
  fi
done

echo ""

if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
  echo "⚠️  Warning: The following tools failed to install:"
  for tool in "${MISSING_TOOLS[@]}"; do
    echo "   - $tool"
  done
  echo ""
  echo "Please try installing them manually with:"
  echo "   brew install ${(j: :)MISSING_TOOLS}"
  echo ""
fi

# ============================================
# 5. Install Recommended Tools (可选)
# ============================================
echo "==================================="
echo "  Recommended Tools (Optional)"
echo "==================================="
echo ""

# 定义推荐工具数组：command_name:brew_package_name:description
declare -A RECOMMENDED_TOOLS=(
  ["rg"]="ripgrep:Fast grep alternative"
  ["bat"]="bat:Cat with syntax highlighting"
  ["eza"]="eza:Modern ls replacement"
  ["autojump"]="autojump:Smart directory jumper"
  ["zoxide"]="zoxide:Smarter cd command"
  ["ncdu"]="ncdu:Disk usage analyzer"
  ["htop"]="htop:Interactive process viewer"
  ["tldr"]="tldr:Simplified man pages"
  ["tree"]="tree:Directory tree viewer"
  ["jq"]="jq:JSON processor"
  ["yazi"]="yazi:Terminal file manager"
  ["lazygit"]="lazygit:Terminal UI for git"
  ["delta"]="git-delta:Syntax-highlighting pager for git"
  ["duf"]="duf:Better df alternative"
  ["procs"]="procs:Modern ps alternative"
  ["dust"]="dust:Modern du alternative with better visualization"
  ["btop"]="btop:Advanced resource monitor"
  ["httpie"]="httpie:User-friendly HTTP client (curl alternative)"
  ["glow"]="glow:Render markdown in the terminal"
  ["neofetch"]="neofetch:System info display"
  ["fastfetch"]="fastfetch:Faster neofetch alternative"
  ["yt-dlp"]="yt-dlp:Video downloader (youtube-dl successor)"
  ["bottom"]="bottom:Graphical system monitor (like htop/btop)"
  ["gdu"]="gdu:Fast disk usage analyzer written in Go"
  ["choose"]="choose:Human-friendly cut alternative"
  ["hyperfine"]="hyperfine:Benchmarking tool for CLI commands"
  ["pueue"]="pueue:Task scheduler for commands in background"
)

for cmd in ${(k)RECOMMENDED_TOOLS}; do
  IFS=':' read -r brew_name description <<< "${RECOMMENDED_TOOLS[$cmd]}"
  
  if (( $+commands[$cmd] )); then
    echo "✓ $cmd already installed - $description"
  else
    printf "Install $cmd ($description)? [y/N]: "
    if read -q; then
      echo ""
      install_tool "$cmd" "$brew_name"
    else
      echo " - Skipped"
    fi
  fi
done

echo ""

# ============================================
# 6. Install UV (Python package manager)
# ============================================
echo "==================================="
echo "  Python Tools"
echo "==================================="
echo ""

if (( $+commands[uv] )); then
  echo "✓ UV already installed"
  uv --version
else
  printf "Install UV (Python package manager)? [y/N]: "
  if read -q; then
    echo ""
    echo "Installing UV..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Add UV to PATH for current session
    export PATH="$HOME/.cargo/bin:$PATH"
    
    if (( $+commands[uv] )); then
      echo "✓ UV installed successfully"
      uv --version
    else
      echo "✗ UV installation failed"
    fi
  else
    echo " - Skipped"
  fi
fi

echo ""

# ============================================
# 7. Install trash-cli (via UV or brew)
# ============================================
if (( $+commands[trash-put] )); then
  echo "✓ trash-cli already installed"
else
  printf "Install trash-cli (safe rm alternative)? [y/N]: "
  if read -q; then
    echo ""
    if (( $+commands[uv] )); then
      echo "Installing trash-cli via UV..."
      uv tool install trash-cli
      
      if (( $+commands[trash-put] )); then
        echo "✓ trash-cli installed successfully"
      else
        echo "⚠ trash-cli installed but not in PATH. Add ~/.local/bin to PATH"
      fi
    else
      echo "Installing trash-cli via Homebrew..."
      brew install trash-cli
      
      if (( $+commands[trash-put] )); then
        echo "✓ trash-cli installed successfully"
      else
        echo "✗ trash-cli installation failed"
      fi
    fi
  else
    echo " - Skipped"
  fi
fi

echo ""

# ============================================
# 8. Post-installation Setup
# ============================================
echo "==================================="
echo "  Post-installation Setup"
echo "==================================="
echo ""

# FZF key bindings and completion
if (( $+commands[fzf] )); then
  if [[ ! -f ~/.fzf.zsh ]]; then
    echo "Setting up FZF key bindings..."
    $(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc
    echo "✓ FZF configured"
  else
    echo "✓ FZF already configured"
  fi
fi

# Initialize zoxide if installed
if (( $+commands[zoxide] )); then
  if ! grep -q "zoxide init" ~/.zshrc 2>/dev/null; then
    echo ""
    printf "Add zoxide initialization to .zshrc? [y/N]: "
    if read -q; then
      echo ""
      echo "" >> ~/.zshrc
      echo "# Initialize zoxide" >> ~/.zshrc
      echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
      echo "✓ zoxide initialization added to .zshrc"
    else
      echo ""
    fi
  else
    echo "✓ zoxide already configured"
  fi
fi

# Make zsh the default shell if not already
if [[ "$SHELL" != *"zsh"* ]]; then
  echo ""
  printf "Set zsh as default shell? [y/N]: "
  if read -q; then
    echo ""
    if [[ "$OSTYPE" == "darwin"* ]]; then
      chsh -s $(which zsh)
    else
      sudo chsh -s $(which zsh) $USER
    fi
    echo "✓ Default shell changed to zsh (restart terminal to take effect)"
  else
    echo ""
  fi
else
  echo "✓ Zsh is already the default shell"
fi

echo ""

# ============================================
# 9. Installation Summary
# ============================================
echo "==================================="
echo "  Installation Summary"
echo "==================================="
echo ""

echo "📦 Essential tools installed:"
for cmd in ${(k)ESSENTIAL_TOOLS}; do
  if (( $+commands[$cmd] )); then
    echo "  ✓ $cmd"
  fi
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
echo "  Bootstrap Complete! ✨"
echo "==================================="
echo ""
echo "📋 Next steps:"
echo "  1. Restart your terminal or run: exec zsh"
echo "  2. Verify installation: run 'which git python3 node nvim'"
echo "  3. Configure your shell in ~/.config/zsh/"
echo ""
echo "🔧 Useful commands:"
echo "  brew update          - Update Homebrew"
echo "  brew upgrade         - Upgrade all packages"
echo "  brew cleanup         - Remove old versions"
echo "  brew doctor          - Check for issues"
echo ""
echo "💡 Tips:"
echo "  - Use 'fzf' with CTRL+R for command history search"
echo "  - Use 'fd' for fast file searching"
echo "  - Use 'nvim' for text editing"
echo "  - Use 'tmux' for terminal multiplexing"
echo ""

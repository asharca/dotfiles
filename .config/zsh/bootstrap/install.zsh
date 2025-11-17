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
  local brew_name="${2:-$tool}"  # 使用第二个参数作为 brew 包名，默认同 tool
  
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
# 3. Install Essential Tools
# ============================================
echo "==================================="
echo "  Checking Essential Tools"
echo "==================================="
echo ""

ESSENTIAL_TOOLS=(
  "git"
  "curl"
  "wget"
  "zsh"
)

for tool in "${ESSENTIAL_TOOLS[@]}"; do
  install_tool "$tool"
done

echo ""

# ============================================
# 4. Install Recommended Tools
# ============================================
echo "==================================="
echo "  Checking Recommended Tools"
echo "==================================="
echo ""

# 定义工具数组：command_name:brew_package_name:description
declare -A RECOMMENDED_TOOLS=(
  ["fzf"]="fzf:Fuzzy finder for files and commands"
  ["fd"]="fd:Fast find alternative"
  ["rg"]="ripgrep:Fast grep alternative"
  ["bat"]="bat:Cat with syntax highlighting"
  ["eza"]="eza:Modern ls replacement"
  ["autojump"]="autojump:Smart directory jumper"
  ["zoxide"]="zoxide:Smarter cd command"
  ["tmux"]="tmux:Terminal multiplexer"
  ["nvim"]="neovim:Modern vim editor"
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
# 5. Install UV (Python package manager)
# ============================================
echo "==================================="
echo "  Checking Python Tools"
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
# 6. Install trash-cli (via UV or brew)
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
# 7. Install Node.js tools
# ============================================
echo "==================================="
echo "  Checking Node.js Tools"
echo "==================================="
echo ""

if (( $+commands[node] )); then
  echo "✓ Node.js already installed"
  node --version
else
  printf "Install Node.js? [y/N]: "
  if read -q; then
    echo ""
    brew install node
    if (( $+commands[node] )); then
      echo "✓ Node.js installed successfully"
      node --version
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

echo "📦 Installed packages via Homebrew:"
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
echo "  2. Run 'zsh-doctor' to check your setup"
echo "  3. Run 'checkproxy' to configure proxy if needed"
echo "  4. Customize your configuration in ~/.config/zsh/"
echo ""
echo "🔧 Useful commands:"
echo "  brew update          - Update Homebrew"
echo "  brew upgrade         - Upgrade all packages"
echo "  brew cleanup         - Remove old versions"
echo "  brew doctor          - Check for issues"
echo "  brew list            - List installed packages"
echo ""
echo "💡 Tips:"
echo "  - Use 'fzf' with CTRL+R for command history search"
echo "  - Use 'z <directory>' for smart directory jumping (zoxide)"
echo "  - Use 'bat' instead of 'cat' for syntax highlighting"
echo "  - Use 'eza' or 'ls' for better directory listings"
echo "  - Use '(tp)trash-put' instead of 'rm' for safe file deletion"

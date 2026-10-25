#!/usr/bin/env bash
# Android/Termux native dependency bootstrap. No Homebrew, sudo, or /etc/shells.
set -Eeuo pipefail

usage() { printf 'Usage: bash install-termux.sh [--dry-run] [server|dev]\n'; }
dry_run=0
if [[ "${1:-}" == "--dry-run" ]]; then
  dry_run=1
  shift
fi
mode="${1:-server}"
if [[ $# -gt 1 || ( "$mode" != server && "$mode" != dev ) ]]; then
  usage >&2
  exit 2
fi

essential=(git zsh bash curl wget make coreutils findutils python nodejs neovim tmux unzip go fd fzf ripgrep)
recommended=(openssh tree jq bat eza zoxide git-delta git-lfs btop ncdu lua-language-server)
development=(clang cmake rust)

if (( dry_run )); then
  printf 'Termux bootstrap plan (%s):\n' "$mode"
  printf 'pkg update -y\n'
  printf 'pkg install -y'
  printf ' %s' "${essential[@]}"
  printf '\n'
  printf 'Optional:'
  printf ' %s' "${recommended[@]}"
  printf '\n'
  if [[ "$mode" == dev ]]; then
    printf 'Development-only:'
    printf ' %s' "${development[@]}"
    printf '\n'
  fi
  printf 'Then initialize zplug, tmux TPM and Termux zsh shell.\n'
  exit 0
fi

[[ "${PREFIX:-}" == */com.termux/files/usr ]] &&
  command -v pkg >/dev/null 2>&1 ||
  { printf 'install-termux: native Termux PREFIX and pkg are required.\n' >&2; exit 1; }
[[ -f "$HOME/.zshrc" && -r "$HOME/.config/zsh/preload/zplug.zsh" ]] ||
  { printf 'install-termux: first deploy the termux dotfiles into HOME (see TERMUX.md).\n' >&2; exit 1; }

printf 'Installing Termux essentials (%s)...\n' "$mode"
pkg update -y
pkg install -y "${essential[@]}"
for tool in git zsh bash curl make python3 node npm nvim tmux unzip go fd fzf rg; do
  command -v "$tool" >/dev/null 2>&1 ||
    { printf 'Missing essential command: %s\n' "$tool" >&2; exit 1; }
done

printf 'Installing optional Termux tools (unavailable packages will be skipped)...\n'
for package in "${recommended[@]}"; do
  if ! pkg install -y "$package"; then
    printf 'Optional package unavailable: %s\n' "$package" >&2
  fi
done
if [[ "$mode" == dev ]]; then
  for package in "${development[@]}"; do
    if ! pkg install -y "$package"; then
      printf 'Development package unavailable: %s\n' "$package" >&2
    fi
  done
fi

# zplug is only used for installation. Runtime ~/.zshrc loads plugin files
# directly, so network outages do not prevent a new interactive shell.
zplug_dir="$HOME/.zplug"
if [[ ! -r "$zplug_dir/init.zsh" ]]; then
  [[ ! -e "$zplug_dir" && ! -L "$zplug_dir" ]] ||
    { printf 'Incomplete zplug directory: %s\n' "$zplug_dir" >&2; exit 1; }
  git clone --depth 1 https://github.com/zplug/zplug.git "$zplug_dir"
fi
printf 'Installing declared Zsh plugins...\n'
export ZDOTFILES_BOOTSTRAP=1
zsh -f "$HOME/.config/zsh/preload/zplug.zsh" </dev/null
unset ZDOTFILES_BOOTSTRAP
for entry in \
  "$zplug_dir/repos/dracula/zsh/dracula.zsh-theme" \
  "$zplug_dir/repos/Aloxaf/fzf-tab/fzf-tab.plugin.zsh" \
  "$zplug_dir/repos/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" \
  "$zplug_dir/repos/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"; do
  [[ -r "$entry" ]] ||
    { printf 'Missing installed Zsh plugin: %s\n' "$entry" >&2; exit 1; }
done

tpm_dir="$HOME/.tmux/plugins/tpm"
if [[ ! -x "$tpm_dir/tpm" ]]; then
  [[ ! -e "$tpm_dir" && ! -L "$tpm_dir" ]] ||
    { printf 'Incomplete tmux TPM directory: %s\n' "$tpm_dir" >&2; exit 1; }
  mkdir -p "$HOME/.tmux/plugins"
  git clone --depth 1 https://github.com/tmux-plugins/tpm.git "$tpm_dir"
fi
if [[ -x "$tpm_dir/bin/install_plugins" ]]; then
  "$tpm_dir/bin/install_plugins"
fi

# Termux uses ~/.termux/shell, not sudo chsh or Linux /etc/shells.
mkdir -p "$HOME/.termux"
target_shell="$PREFIX/bin/zsh"
if [[ "$(readlink "$HOME/.termux/shell" 2>/dev/null || :)" != "$target_shell" ]]; then
  if command -v chsh >/dev/null 2>&1; then
    chsh -s zsh
  else
    ln -sfn "$target_shell" "$HOME/.termux/shell"
  fi
fi
if command -v termux-reload-settings >/dev/null 2>&1; then
  termux-reload-settings
fi

printf '\nTermux bootstrap complete (%s). Try: exec zsh\n' "$mode"
printf 'Optional GUI features need their own Termux or Android packages (see TERMUX.md).\n'


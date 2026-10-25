#!/usr/bin/env bash
# First-time, non-destructive Termux deployment from a normal termux branch clone.
set -Eeuo pipefail

die() { printf 'termux-setup: %s\n' "$*" >&2; exit 1; }

mode="${1:-server}"
[[ $# -le 1 && ( "$mode" == server || "$mode" == dev ) ]] ||
  die "Usage: bash termux-setup.sh [server|dev]"
[[ "${PREFIX:-}" == */com.termux/files/usr ]] && command -v pkg >/dev/null 2>&1 ||
  die "Run this script inside the native Termux app, not proot/SSH/Linux."
[[ -n "${HOME:-}" && "$HOME" != "/" ]] || die "Unsafe HOME."
src="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
[[ "$src" != "$HOME" && -d "$src/.git" ]] ||
  die "First git clone the termux branch into a separate directory."
[[ "$(git -C "$src" branch --show-current)" == termux ]] ||
  die "Source must be checked out on the termux branch."
[[ ! -e "$HOME/.cfg" && ! -L "$HOME/.cfg" ]] ||
  die "~/.cfg already exists. This first-install command will not replace it; use the update instructions in TERMUX.md."

repo_url=https://github.com/asharca/dotfiles.git
printf 'Updating Termux and installing deployment dependencies...\n'
pkg update -y
pkg install -y git zsh bash rsync

# Prepare the bare repository before touching HOME files; do not replace an
# existing bare repository or silently mix source and remote revisions.
# Clone the exact reviewed local revision; switch origin back to GitHub for future pulls.
git clone --bare --single-branch --branch termux "$src" "$HOME/.cfg"
git --git-dir="$HOME/.cfg" remote set-url origin "$repo_url"
source_sha="$(git -C "$src" rev-parse HEAD)"
bare_sha="$(git --git-dir="$HOME/.cfg" rev-parse HEAD)"
[[ "$source_sha" == "$bare_sha" ]] ||
  die "Bare clone SHA did not match the reviewed source. HOME was not modified; inspect ~/.cfg."

mkdir -p -- "$HOME/.config-backup"
backup_dir="$(mktemp -d "$HOME/.config-backup/termux.XXXXXXXXXX")"
printf 'Backing up replaced files to %s\n' "$backup_dir"

# Keep the complete main-based tree, including hidden files, Android settings,
# and symlinks. Existing files are backed up, never deleted wholesale.
# A normal clone's .git directory must never be copied to HOME.
rsync -a --backup --backup-dir="$backup_dir" --exclude='/.git/' \
  "$src/" "$HOME/"

git --git-dir="$HOME/.cfg" config --local status.showUntrackedFiles no
printf 'Installed branch termux at %s\n' "$bare_sha"
printf 'Running native Termux package and plugin bootstrap...\n'
bash "$HOME/.config/zsh/bootstrap/install-termux.sh" "$mode"

printf '\nSetup complete. Restart Termux or run: exec zsh\n'
printf 'Your saved file backups are in: %s\n' "$backup_dir"
printf 'The dotfiles Git helper will be available as: config\n'


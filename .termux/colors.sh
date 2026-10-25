#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
shopt -s nullglob
themes=("$dir"/colors/*.colors)
(( ${#themes[@]} > 0 )) || { printf 'No color schemes found.\n' >&2; exit 1; }

printf 'Available Termux color schemes (blank keeps the current theme):\n'
for ((i=0; i<${#themes[@]}; ++i)); do
  printf '(%d) %s\n' "$i" "$(basename -- "${themes[i]}")"
done

while true; do
  read -r -p 'Theme number: ' choice || exit 0
  [[ -n "$choice" ]] || exit 0
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( ${#choice} < 8 )); then
    index=$((10#$choice))
    if (( index < ${#themes[@]} )); then
      cp -- "${themes[index]}" "$dir/colors.properties"
      if command -v termux-reload-settings >/dev/null 2>&1; then
        termux-reload-settings
      fi
      exit 0
    fi
  fi
  printf 'Please enter a valid number.\n' >&2
done


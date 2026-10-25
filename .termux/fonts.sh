#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
shopt -s nullglob
fonts=()
for folder in "$dir"/fonts/*; do
  [[ -d "$folder" ]] || continue
  for font in "$folder"/*.ttf "$folder"/*.otf; do
    [[ -f "$font" ]] && fonts+=("$font")
  done
done
(( ${#fonts[@]} > 0 )) || { printf 'No fonts found.\n' >&2; exit 1; }

printf 'Available Termux fonts (blank keeps the current font):\n'
for ((i=0; i<${#fonts[@]}; ++i)); do
  printf '(%d) %s\n' "$i" "${fonts[i]#"$dir"/fonts/}"
done

while true; do
  read -r -p 'Font number: ' choice || exit 0
  [[ -n "$choice" ]] || exit 0
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( ${#choice} < 8 )); then
    index=$((10#$choice))
    if (( index < ${#fonts[@]} )); then
      cp -- "${fonts[index]}" "$dir/font.ttf"
      if command -v termux-reload-settings >/dev/null 2>&1; then
        termux-reload-settings
      fi
      exit 0
    fi
  fi
  printf 'Please enter a valid number.\n' >&2
done


#!/usr/bin/env zsh
# Network Functions

# Set proxy
setproxy() {
  local host="${1:-localhost}"
  local port="${2:-8888}"

  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    echo "Error: Invalid port number (1-65535)"
    return 1
  fi

  export http_proxy="http://${host}:${port}"
  export https_proxy="http://${host}:${port}"
  export all_proxy="http://${host}:${port}"

  echo "Proxy enabled: http://${host}:${port}"
}

# Unset proxy
unsetproxy() {
  unset http_proxy https_proxy all_proxy
  echo "Proxy disabled"
}

# Check proxy settings
checkproxy() {
  echo "Current proxy settings:"
  echo "  http_proxy:  ${http_proxy:-not set}"
  echo "  https_proxy: ${https_proxy:-not set}"
  echo "  all_proxy:   ${all_proxy:-not set}"
}

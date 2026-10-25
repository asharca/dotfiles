#!/usr/bin/env zsh
# Network Functions

# Set proxy
setproxy() {
  emulate -L zsh

  if (( $# > 2 )); then
    print -u2 -- 'Usage: setproxy [host] [port]'
    return 2
  fi

  local host="${1:-localhost}"
  local port="${2:-8888}"
  local url_host="$host"

  if [[ -z "$host" || "$host" == *[[:space:]/@]* || "$host" == *://* ]]; then
    print -u2 -- 'Error: Host must be a hostname or IP address without a scheme'
    return 2
  fi

  if [[ ! "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
    print -u2 -- 'Error: Invalid port number (1-65535)'
    return 2
  fi

  # URI authorities require brackets around IPv6 literals.
  if [[ "$host" == *:* && "$host" != \[*\] ]]; then
    url_host="[$host]"
  fi

  export http_proxy="http://${url_host}:${port}"
  export https_proxy="$http_proxy"
  export all_proxy="$http_proxy"
  export HTTP_PROXY="$http_proxy"
  export HTTPS_PROXY="$https_proxy"
  export ALL_PROXY="$all_proxy"

  print -- "Proxy enabled: $http_proxy"
}

# Unset proxy
unsetproxy() {
  emulate -L zsh
  unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
  print -- 'Proxy disabled'
}

# Check proxy settings
checkproxy() {
  emulate -L zsh
  print -- 'Current proxy settings:'
  print -- "  http_proxy:  ${http_proxy:-not set}"
  print -- "  https_proxy: ${https_proxy:-not set}"
  print -- "  all_proxy:   ${all_proxy:-not set}"
  print -- "  HTTP_PROXY:  ${HTTP_PROXY:-not set}"
  print -- "  HTTPS_PROXY: ${HTTPS_PROXY:-not set}"
  print -- "  ALL_PROXY:   ${ALL_PROXY:-not set}"
}

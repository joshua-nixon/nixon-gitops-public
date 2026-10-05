
set -euo pipefail

source $WORKSPACE/.bash/fn-azure.sh
source $WORKSPACE/.bash/fn-logging.sh

get_netbird_ip_from_public_ip() {
  local public_ip="$1"

  local netbird_token
  netbird_token=$(get_secret "kvnixongitops" "netbird-token")

  local response
  if ! response=$(
    curl --silent --show-error -w "\n%{http_code}" -X GET "https://api.netbird.io/api/peers" \
      -H "Authorization: Bearer $netbird_token" \
      -H "Accept: application/json"
  ); then
    log_error "Network request failed completely while connecting to NetBird API."
    return 1
  fi

  local http_code
  http_code=$(echo "$response" | tail -n1)

  local response_body
  response_body=$(echo "$response" | sed '$d')

  log_debug "NetBird API HTTP Status: $http_code"

  if [[ "$http_code" -ne 200 ]]; then
    log_debug "NetBird API returned non-200 HTTP status ($http_code)."
    log_debug "Response Payload: $response_body"
    return 1
  fi

  local netbird_ip
  netbird_ip=$(
    echo "$response_body" | jq -e -r --arg public_ip "$public_ip" \
      '.[] | select(.connection_ip == $public_ip) | .ip' 2>/dev/null
  ) || {
    log_debug "Could not parse NetBird IP for public IP '$public_ip'."
    log_debug "Full API Response Body: $response_body"
    return 1
  }

  echo "$netbird_ip"
  return 0

}
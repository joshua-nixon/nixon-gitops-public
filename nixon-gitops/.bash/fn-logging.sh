
log_debug(){
  local message="$1"

  echo "[DEBUG] $message" >&2
}

log_error(){
  local message="$1"

  echo "[ERROR] $message" >&2
}

log_info(){
  local message="$1"

  echo "[INFO] $message" >&2
}
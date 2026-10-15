
source $WORKSPACE/.bash/fn-netbird.sh

SSH_PATH="$WORKSPACE/.config/id_hetzer_ed25519"

KUBECONFIG_PATH="$WORKSPACE/.config/kubeconfig-k3sup"

CONTROLPLANE_K3S_ARGS=(
  "--disable traefik"
  "--disable metrics-server"
  "--write-kubeconfig-mode 0644"
  "--node-taint node-role.kubernetes.io/control-plane=:PreferNoSchedule"
  "--flannel-iface wt0"
  "--kubelet-arg kube-reserved=cpu=100m,memory=200Mi,ephemeral-storage=5Gi"
  "--kubelet-arg system-reserved=cpu=100m,memory=200Mi,ephemeral-storage=5Gi"
  "--kubelet-arg cloud-provider=external"
)

AGENT_K3S_ARGS=(
  "--flannel-iface wt0"
  "--kubelet-arg kube-reserved=cpu=100m,memory=200Mi,ephemeral-storage=3Gi"
  "--kubelet-arg system-reserved=cpu=100m,memory=200Mi,ephemeral-storage=3Gi"
)

function ssh_exec() {
  local ssh_target="$1"
  local command="$2"

  ssh -i "$SSH_PATH" -o StrictHostKeyChecking=accept-new "$ssh_target" "$command"
}

function join_args() {
  local IFS=" "

  echo "$*"
}

# parses --key=value style args into an associative array, e.g:
#   parse_named_args args "$@" -> ${args[public_ip]}
function parse_named_args() {
  local -n _parsed="$1"; shift

  local arg key value
  for arg in "$@"; do
    key="${arg%%=*}"
    key="${key#--}"
    value="${arg#*=}"
    _parsed["${key//-/_}"]="$value"
  done
}

function build_controlplane_k3s_args() {
  local -n _out="$1"
  local oidc_issuer="$2"

  _out=("${CONTROLPLANE_K3S_ARGS[@]}")

  if [[ -n "$oidc_issuer" ]]; then
    _out+=(
      "--kube-apiserver-arg service-account-issuer=${oidc_issuer}"
      "--kube-apiserver-arg service-account-max-token-expiration=24h"
    )
  fi
}

function install_controlplane() {
  local -A args=()
  parse_named_args args "$@"

  local public_ip="${args[public_ip]}"
  local oidc_issuer="${args[oidc_issuer]:-}"

  local private_ip
  private_ip="$(get_netbird_ip_from_public_ip "$public_ip")"

  local cp_args=()
  build_controlplane_k3s_args cp_args "$oidc_issuer"

  local k3s_args=(
    "--node-ip $private_ip"
    "--node-external-ip $public_ip"
    "--advertise-address $private_ip"
    "${cp_args[@]}"
  )

  k3sup install \
    --ip "$private_ip" \
    --user root \
    --ssh-key "$SSH_PATH" \
    --cluster \
    --k3s-version "$K3S_VERSION" \
    --local-path "$KUBECONFIG_PATH" \
    --context k3s-hetzner \
    --tls-san "$public_ip" \
    --tls-san "$private_ip" \
    --k3s-extra-args "$(join_args "${k3s_args[@]}")"

  sed -i "s#server: https://.*:6443#server: https://$private_ip:6443#" "$KUBECONFIG_PATH"
}

function join_agent() {
  local -A args=()
  parse_named_args args "$@"

  local public_server_ip="${args[server_public_ip]}"
  local public_agent_ip="${args[public_ip]}"

  local private_agent_ip
  local private_server_ip

  private_agent_ip="$(get_netbird_ip_from_public_ip "$public_agent_ip")"
  private_server_ip="$(get_netbird_ip_from_public_ip "$public_server_ip")"

  local k3s_args=(
    "--node-ip $private_agent_ip"
    "--node-external-ip $public_agent_ip"
    "${AGENT_K3S_ARGS[@]}"
  )

  k3sup join \
    --ip "$private_agent_ip" \
    --user root \
    --ssh-key "$SSH_PATH" \
    --server-ip "$private_server_ip" \
    --server-user root \
    --server-url "https://$private_server_ip:6443" \
    --k3s-version "$K3S_VERSION" \
    --k3s-extra-args "$(join_args "${k3s_args[@]}")"
}

function join_controlplane() {
  local -A args=()
  parse_named_args args "$@"

  local public_server_ip="${args[server_public_ip]}"
  local public_controlplane_ip="${args[public_ip]}"
  local oidc_issuer="${args[oidc_issuer]:-}"

  local private_controlplane_ip
  local private_server_ip

  private_controlplane_ip="$(get_netbird_ip_from_public_ip "$public_controlplane_ip")"
  private_server_ip="$(get_netbird_ip_from_public_ip "$public_server_ip")"

  local cp_args=()
  build_controlplane_k3s_args cp_args "$oidc_issuer"

  local k3s_args=(
    "--node-ip $private_controlplane_ip"
    "--node-external-ip $public_controlplane_ip"
    "--advertise-address $private_controlplane_ip"
    "${cp_args[@]}"
  )

  k3sup join \
    --ip "$private_controlplane_ip" \
    --user root \
    --ssh-key "$SSH_PATH" \
    --server \
    --server-ip "$private_server_ip" \
    --server-user root \
    --server-url "https://$private_server_ip:6443" \
    --k3s-version "$K3S_VERSION" \
    --tls-san "$public_controlplane_ip" \
    --tls-san "$private_controlplane_ip" \
    --k3s-extra-args "$(join_args "${k3s_args[@]}")"
}

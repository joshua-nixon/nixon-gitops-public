SSH_PATH="/$WORKSPACE/.ssh/ssh_key"

KUBECONFIG_PATH="$WORKSPACE/.config/kubeconfig-k3sup"

CONTROLPLANE_K3S_ARGS=(
  "--disable-cloud-controller"
  "--disable traefik"
  "--disable metrics-server"
  "--write-kubeconfig-mode 0644"
  "--node-taint node-role.kubernetes.io/control-plane=:PreferNoSchedule"
  "--flannel-iface wt0"
  "--kubelet-arg kube-reserved=cpu=100m,memory=200Mi,ephemeral-storage=3Gi"
  "--kubelet-arg system-reserved=cpu=100m,memory=200Mi,ephemeral-storage=3Gi"
)

AGENT_K3S_ARGS=(
  "--flannel-iface wt0"
  "--kubelet-arg kube-reserved=cpu=100m,memory=200Mi,ephemeral-storage=3Gi"
  "--kubelet-arg system-reserved=cpu=100m,memory=200Mi,ephemeral-storage=3Gi"
)

chmod 600 "/$WORKSPACE/.ssh/ssh_key"

if ! command -v k3sup >/dev/null 2>&1; then
  curl -sLS https://get.k3sup.dev | sh
fi

function ssh_exec() {
  local ssh_target="$1"
  local command="$2"

  ssh -i "$SSH_PATH" -o StrictHostKeyChecking=accept-new "$ssh_target" "$command"
}

function join_args() {
  local IFS=" "

  echo "$*"
}

function get_netbird_peer_ip() {
  local ssh_target="$1"

  ssh_exec "$ssh_target" "ip -4 addr show wt0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'"
}

function install_controlplane() {
  local public_ip="$1"
  local private_ip

  private_ip="$(get_netbird_peer_ip "$public_ip")"

  local k3s_args=(
    "--node-ip $private_ip"
    "--node-external-ip $public_ip"
    "${CONTROLPLANE_K3S_ARGS[@]}"
  )

  k3sup install \
    --ip "$private_ip" \
    --user root \
    --ssh-key "$SSH_PATH" \
    --cluster \
    --k3s-version "$K3S_VERSION" \
    --local-path "$KUBECONFIG_PATH" \
    --context k3sup-test \
    --tls-san "$public_ip" \
    --tls-san "$private_ip" \
    --k3s-extra-args "$(join_args "${k3s_args[@]}")"

  sed -i "s#server: https://.*:6443#server: https://$private_ip:6443#" "$KUBECONFIG_PATH"
}

function join_agent() {
  local public_server_ip="$1"
  local public_agent_ip="$2"

  local private_agent_ip
  local private_server_ip

  private_agent_ip="$(get_netbird_peer_ip "$public_agent_ip")"
  private_server_ip="$(get_netbird_peer_ip "$public_server_ip")"

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
  local public_server_ip="$1"
  local public_controlplane_ip="$2"

  local private_controlplane_ip
  local private_server_ip

  private_controlplane_ip="$(get_netbird_peer_ip "$public_controlplane_ip")"
  private_server_ip="$(get_netbird_peer_ip "$public_server_ip")"

  local k3s_args=(
    "--node-ip $private_controlplane_ip"
    "--node-external-ip $public_controlplane_ip"
    "${CONTROLPLANE_K3S_ARGS[@]}"
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

#!/usr/bin/env bash

set -uo pipefail

CERTS_DIR="${CERTS_DIR:-/var/lib/rancher/k3s/server/tls/etcd}"
ETCD_ENDPOINT="${ETCD_ENDPOINT:-https://127.0.0.1:2379}"
LOG_FILE="${LOG_FILE:-}"
issues=0

if [[ -n "$LOG_FILE" ]]; then
  exec > >(tee -a "$LOG_FILE") 2>&1
fi

section() {
  printf '\n== %s ==\n' "$1"
}

warn() {
  printf 'WARNING: %s\n' "$1"
  issues=$((issues + 1))
}

run_check() {
  local description="$1"
  shift

  if ! "$@"; then
    warn "$description failed"
  fi
}

echo "K3s single-node diagnostic: $(date --iso-8601=seconds)"
echo "Host: $(hostname --fqdn 2>/dev/null || hostname)"

section "Dependencies"
for command in etcdctl jq k3s journalctl ss systemctl; do
  if ! command -v "$command" >/dev/null 2>&1; then
    warn "missing command: $command"
  fi
done

section "K3s service configuration"
if systemctl is-active --quiet k3s; then
  echo "k3s service: active"
else
  warn "k3s service is not active"
fi

exec_start="$(systemctl show k3s -p ExecStart --value 2>/dev/null || true)"
if [[ -n "$exec_start" ]]; then
  echo "$exec_start" | sed -E 's/ --kube-apiserver-arg service-account-issuer=[^ ]+/ --kube-apiserver-arg service-account-issuer=[REDACTED]/g'
  if grep -q -- '--server ' <<<"$exec_start"; then
    bootstrap_endpoint="$(sed -nE 's/.*--server[[:space:]]+([^ ]+).*/\1/p' <<<"$exec_start")"
    warn "k3s still has a remote --server endpoint: ${bootstrap_endpoint:-unknown}"
  fi
else
  warn "could not read the k3s systemd configuration"
fi

for environment_file in /etc/systemd/system/k3s.service.env /etc/default/k3s /etc/sysconfig/k3s; do
  if [[ -r "$environment_file" ]] && grep -q '^K3S_URL=' "$environment_file"; then
    endpoint="$(sed -nE 's/^K3S_URL=['\''"]?([^'\''"]+).*/\1/p' "$environment_file")"
    warn "K3S_URL is still configured in ${environment_file}: ${endpoint:-unknown}"
  fi
done

section "Node networking"
ip -4 addr show wt0 2>/dev/null || warn "NetBird interface wt0 is unavailable"
ip -4 route 2>/dev/null | sed -n '1,20p'

section "K3s ports"
if command -v ss >/dev/null 2>&1; then
  ss -ltnp | grep -E ':(6443|10248|10250|2379|2380)\b' || warn "expected K3s ports are not listening"
fi

section "Kubernetes API"
run_check "Kubernetes node query" k3s kubectl get nodes -o wide
if ! readyz="$(k3s kubectl get --raw=/readyz 2>&1)"; then
  warn "Kubernetes API readiness check failed: $readyz"
else
  echo "$readyz"
fi

section "Kubernetes service network"
kubernetes_service_ip="$(
  k3s kubectl get service kubernetes \
    --namespace default \
    --output jsonpath='{.spec.clusterIP}' 2>/dev/null || true
)"
kubernetes_service_port="$(
  k3s kubectl get service kubernetes \
    --namespace default \
    --output jsonpath='{.spec.ports[?(@.name=="https")].port}' 2>/dev/null || true
)"
if [[ -z "$kubernetes_service_ip" || -z "$kubernetes_service_port" ]]; then
  warn "could not determine the Kubernetes Service IP and HTTPS port"
else
  echo "Kubernetes Service: ${kubernetes_service_ip}:${kubernetes_service_port}"
  if ! service_probe="$(
    curl --silent --show-error --insecure \
      --connect-timeout 3 \
      --max-time 5 \
      "https://${kubernetes_service_ip}:${kubernetes_service_port}/readyz" 2>&1
  )"; then
    warn "Kubernetes Service IP is unreachable: $service_probe"
  else
    echo "Kubernetes Service probe: reachable"
  fi
fi

section "etcd membership and health"
if [[ ! -r "${CERTS_DIR}/server-ca.crt" ||
      ! -r "${CERTS_DIR}/server-client.crt" ||
      ! -r "${CERTS_DIR}/server-client.key" ]]; then
  warn "k3s etcd client certificates are missing from ${CERTS_DIR}"
else
  export ETCDCTL_API=3
  member_json="$(
    etcdctl \
      --endpoints="$ETCD_ENDPOINT" \
      --cacert="${CERTS_DIR}/server-ca.crt" \
      --cert="${CERTS_DIR}/server-client.crt" \
      --key="${CERTS_DIR}/server-client.key" \
      member list --write-out=json 2>&1
  )"
  if [[ "$member_json" == member\ list\ failed:* ]] || ! jq empty <<<"$member_json" 2>/dev/null; then
    warn "etcd member list failed: $member_json"
  else
    jq -r '.members[] | [.name, (.peerURLs | join(",")), (.clientURLs | join(",")), .status] | @tsv' <<<"$member_json"
    member_count="$(jq '.members | length' <<<"$member_json")"
    echo "etcd member count: $member_count"
    if [[ "$member_count" -ne 1 ]]; then
      warn "expected one etcd member for this single-node cluster, found ${member_count}"
    fi
  fi

  run_check "etcd endpoint status" etcdctl \
    --endpoints="$ETCD_ENDPOINT" \
    --cacert="${CERTS_DIR}/server-ca.crt" \
    --cert="${CERTS_DIR}/server-client.crt" \
    --key="${CERTS_DIR}/server-client.key" \
    endpoint status --write-out=table
  run_check "etcd endpoint health" etcdctl \
    --endpoints="$ETCD_ENDPOINT" \
    --cacert="${CERTS_DIR}/server-ca.crt" \
    --cert="${CERTS_DIR}/server-client.crt" \
    --key="${CERTS_DIR}/server-client.key" \
    endpoint health
fi

section "Recent relevant logs"
journalctl -u k3s -b --no-pager -n 120 2>/dev/null |
  grep -E 'remote datastore|not a member|address already in use|runtime core not ready|too many requests|failed to publish|503 response|readiness|service.*endpoint|endpoint.*service' ||
  echo "No matching recent K3s warnings found."

if journalctl -u k3s -b --no-pager -n 500 2>/dev/null |
  grep -Eq 'Unable to reconcile with remote datastore|runtime core not ready|Sending HTTP/[^ ]+ 503|poststarthook/[^ ]+ failed|Error removing old endpoints'; then
  warn "recent k3s startup or Kubernetes service disruption was detected in the journal"
fi

if [[ "$issues" -eq 0 ]]; then
  echo
  echo "RESULT: no known single-node K3s issues detected."
else
  echo
  echo "RESULT: ${issues} issue(s) detected; review the warnings above."
fi

exit "$([[ "$issues" -eq 0 ]] && echo 0 || echo 1)"

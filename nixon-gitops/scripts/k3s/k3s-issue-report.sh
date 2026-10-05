#!/usr/bin/env bash

set -uo pipefail

REPORT_DIR="${REPORT_DIR:-k3s-issue-report-$(hostname -s)-$(date -u +%Y%m%dT%H%M%SZ)}"
mkdir -p "$REPORT_DIR"

run_report() {
  local name="$1"
  shift

  {
    echo "# $name"
    echo "# collected: $(date --iso-8601=seconds)"
    echo
    "$@"
  } >"$REPORT_DIR/$name.txt" 2>&1 || true
}

run_shell_report() {
  local name="$1"
  local command="$2"

  {
    echo "# $name"
    echo "# collected: $(date --iso-8601=seconds)"
    echo
    bash -c "$command"
  } >"$REPORT_DIR/$name.txt" 2>&1 || true
}

run_report "system" bash -c '
  hostname --fqdn 2>/dev/null || hostname
  date --iso-8601=seconds
  uptime
  uname -a
  free -h
  df -h / /var/lib/rancher/k3s
'

run_report "k3s-service" systemctl status k3s --no-pager -l
run_shell_report "k3s-unit" '
  systemctl show k3s -p MainPID -p NRestarts -p ExecMainStartTimestamp -p ExecStart --no-pager |
    sed -E "s/(K3S_TOKEN|token|password|secret|key)=([^ ;]+)/\1=[REDACTED]/Ig"
  sed -E "s/(K3S_TOKEN|token|password|secret|key)=['\''\"]?[^'\''\" ;]+['\''\"]?/\1=[REDACTED]/Ig" \
    /etc/systemd/system/k3s.service /etc/systemd/system/k3s.service.env 2>/dev/null
'

run_report "interfaces-and-routes" bash -c '
  ip -4 addr
  echo
  ip -4 route
  echo
  ip link show wt0
'

run_report "k3s-restarts-and-node-ip" bash -c '
  journalctl -u k3s -b --no-pager -o short-iso-precise |
    grep -E "NodeIPs changed|Main process exited|Failed with result|remote datastore|runtime core not ready|503 response"
'

run_shell_report "k3s-journal" '
  journalctl -u k3s -b --no-pager --since "2 hours ago" |
    grep -E "NodeIPs changed|Main process exited|Failed with result|remote datastore|runtime core not ready|503 response|too many requests|failed to publish|address already in use|starting"
'

run_report "netbird-service" systemctl status netbird --no-pager -l
run_shell_report "netbird-journal" '
  journalctl -u netbird -b --no-pager --since "2 hours ago" |
    grep -Ei "wt0|interface|address|route|disconnect|connect|error|failure"
'

run_shell_report "kubernetes-state" '
  k3s kubectl get nodes -o wide
  echo
  k3s kubectl get pods -A -o wide
  echo
  k3s kubectl get events -A --sort-by=.lastTimestamp | tail -100
'

run_shell_report "node-object" '
  k3s kubectl get node -o json |
    jq "{
      metadata: {
        name: .metadata.name,
        annotations: (.metadata.annotations | with_entries(
          select(.key != \"k3s.io/node-env\") |
          if (.key | test(\"token|secret|password|key\"; \"i\")) then .value = \"[REDACTED]\" else . end
        ))
      },
      status: .status
    }"
'

run_shell_report "hcloud-and-traefik" '
  k3s kubectl get deployment -n kube-system hcloud-cloud-controller-manager -o yaml |
    sed -E "s/(token|password|secret|key):.*/\1: [REDACTED]/Ig"
  echo
  k3s kubectl get service -n traefik traefik -o yaml |
    sed -E "s/(token|password|secret|key):.*/\1: [REDACTED]/Ig"
'

run_shell_report "api-and-service-health" '
  k3s kubectl get --raw=/readyz
  echo
  service_ip=$(k3s kubectl get service kubernetes -o jsonpath="{.spec.clusterIP}")
  curl --silent --show-error --insecure --connect-timeout 3 \
    "https://${service_ip}:443/readyz" -o /dev/null -w "service_http_status=%{http_code}\n"
'

run_shell_report "etcd-health" '
  export ETCDCTL_API=3
  export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379
  export ETCDCTL_CACERT=/var/lib/rancher/k3s/server/tls/etcd/server-ca.crt
  export ETCDCTL_CERT=/var/lib/rancher/k3s/server/tls/etcd/server-client.crt
  export ETCDCTL_KEY=/var/lib/rancher/k3s/server/tls/etcd/server-client.key
  etcdctl endpoint health
  etcdctl endpoint status --write-out=table
  etcdctl member list --write-out=table
'

tar -czf "${REPORT_DIR}.tar.gz" "$REPORT_DIR"
echo "Created ${REPORT_DIR}.tar.gz"
echo "Review the archive for secrets before uploading it to GitHub."

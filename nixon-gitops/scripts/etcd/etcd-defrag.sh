#!/bin/bash
# defrag-etcd.sh - Run on each K3s server node

CERTS_DIR="/var/lib/rancher/k3s/server/tls/etcd"
ETCD_ENDPOINT="https://127.0.0.1:2379"

# Check size before defrag
echo "=== Size before defragmentation ==="
ETCDCTL_API=3 etcdctl endpoint status \
    --endpoints="${ETCD_ENDPOINT}" \
    --cacert="${CERTS_DIR}/server-ca.crt" \
    --cert="${CERTS_DIR}/server-client.crt" \
    --key="${CERTS_DIR}/server-client.key" \
    --write-out=table

# Create a snapshot before defrag as a safety measure
echo "=== Creating pre-defrag snapshot ==="
sudo k3s etcd-snapshot save --name pre-defrag-$(date +%Y%m%d-%H%M%S)

# Run defragmentation
echo "=== Running defragmentation ==="
ETCDCTL_API=3 etcdctl defrag \
    --endpoints="${ETCD_ENDPOINT}" \
    --cacert="${CERTS_DIR}/server-ca.crt" \
    --cert="${CERTS_DIR}/server-client.crt" \
    --key="${CERTS_DIR}/server-client.key"

# Check size after defrag
echo "=== Size after defragmentation ==="
ETCDCTL_API=3 etcdctl endpoint status \
    --endpoints="${ETCD_ENDPOINT}" \
    --cacert="${CERTS_DIR}/server-ca.crt" \
    --cert="${CERTS_DIR}/server-client.crt" \
    --key="${CERTS_DIR}/server-client.key" \
    --write-out=table
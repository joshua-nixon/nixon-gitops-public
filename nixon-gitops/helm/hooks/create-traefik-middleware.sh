#!/usr/bin/env bash

KUBE_CONTEXT="$1"

echo "Creating VPN middleware in context: $KUBE_CONTEXT"

TEMPLATE="templates/vpn-middleware.yaml"

IPV4=$(curl --fail --silent --show-error --ipv4 https://api.ipify.org)

YAML=$(sed "s/\${IPV4}/$IPV4/g" $TEMPLATE)

echo "IPV4 address: $IPV4"

kubectl --context "$KUBE_CONTEXT" apply -f <(echo "$YAML")
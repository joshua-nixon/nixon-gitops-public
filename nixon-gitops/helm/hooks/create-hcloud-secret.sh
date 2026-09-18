#!/usr/bin/env bash

KUBE_CONTEXT="$1"

echo "Configuring hcloud external secret in context: $KUBE_CONTEXT"

TEMPLATE="templates/hcloud.yaml"

kubectl --context "$KUBE_CONTEXT" apply -f "$TEMPLATE"
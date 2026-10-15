#!/usr/bin/env bash

set -euo pipefail

CONTEXT="default"

ENVIRONMENTS=(
    "tier9:production"
)

for entry in "${ENVIRONMENTS[@]}"; do
    IFS=":" read -r PROJECT ENV_NAME <<< "$entry"

    NAMESPACE="${PROJECT}-${ENV_NAME}"

    PG_NAME="${PROJECT}-postgresql-${ENV_NAME}"

    SECRET_NAME="${PG_NAME}-postgres"
    
    GUID="$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)"

    kubectl label secret "$SECRET_NAME" cnpg.io/reload="$GUID" \
        --namespace "$NAMESPACE" \
        --overwrite
done
set -euo pipefail

source $WORKSPACE/.bash/fn-logging.sh

get_secret() {
    local vault_name="$1"
    local secret_name="$2"

    local secret_value
    secret_value=$(
        az keyvault secret show \
            --vault-name "$vault_name" \
            --name "$secret_name" \
            --query "value" \
            -o tsv 2>/dev/null
    )

    if [[ $? -eq 0 && -n "$secret_value" ]]; then
        echo "$secret_value"
        log_debug "Retrieved secret '$secret_name' from vault '$vault_name'"
        return 0
    fi

    log_error "Failed to retrieve secret '$secret_name' from vault '$vault_name'."
    return 1
}
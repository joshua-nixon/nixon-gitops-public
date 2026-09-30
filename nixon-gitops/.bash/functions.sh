
get_kv_secret() {
    local vault_name="$1"
    local secret_name="$2"

    az keyvault secret show \
        --vault-name "$vault_name" \
        --name "$secret_name" \
        --query "value" \
        -o tsv
}
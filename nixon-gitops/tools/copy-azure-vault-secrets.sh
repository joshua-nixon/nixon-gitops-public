SOURCE_VAULT="k3sclustersharedvault"
DEST_VAULT="kvk3shared"

for secret in $(az keyvault secret list --vault-name $SOURCE_VAULT --query "[].name" -o tsv); do
    value=$(az keyvault secret show --vault-name $SOURCE_VAULT --name $secret --query "value" -o tsv)
    
    az keyvault secret set --vault-name $DEST_VAULT --name $secret --value "$value"
done
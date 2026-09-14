
# kind create cluster --name arc-test
# kubectl config use-context kind-arc-test

az config set extension.use_dynamic_install=yes_without_prompt

az connectedk8s connect \
    --name talos-cluster-080926 \
    --resource-group rg-v1-shared \
    --location uksouth \
    --enable-oidc-issuer \
    --enable-workload-identity

# /etc/rancher/k3s/config.yaml
#   kube-apiserver-arg:  
#       - "service-account-issuer=${OIDC_ISSUER}"
#       - "service-account-max-token-expiration=24h"
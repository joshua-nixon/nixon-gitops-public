
# kind create cluster --name arc-test
# kubectl config use-context kind-arc-test

kubectl config use-context k3s-hetzner

az config set extension.use_dynamic_install=yes_without_prompt

az connectedk8s connect \
    --name arc-k3s-hetzner-cluster \
    --resource-group rg-v1-shared \
    --location uksouth \
    --enable-oidc-issuer \
    --enable-workload-identity
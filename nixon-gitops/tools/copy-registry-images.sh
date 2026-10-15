#!/bin/bash

SRC_REGISTRY="containerregistry.azurecr.io"
DST_REGISTRY="containerregistry.azurecr.io"

SRC_REGISTRY_ID=$(az acr show --name "$SRC_REGISTRY" --query id --output tsv)

repos=$(az acr repository list --name "$SRC_REGISTRY" --output tsv)

for repo in $repos; do
    echo "Processing repository: $repo"
    
    tags=$(az acr repository show-tags --name "$SRC_REGISTRY" --repository "$repo" --output tsv)
    
    for tag in $tags; do
        echo " -> Importing $repo:$tag..."
        
        az acr import \
          --name "$DST_REGISTRY" \
          --source "$repo:$tag" \
          --image "$repo:$tag" \
          --registry "$SRC_REGISTRY_ID" \
          --no-wait
    done
done

echo "All import tasks have been queued in Azure!"
#!/usr/bin/env bash
set -e

RG_NAME=$1
SA_NAME=$2
CONTAINER_NAME=$3
LOCATION=${4:-eastus}

# Create Resource Group if not exists
if ! az group show -n "$RG_NAME" >/dev/null 2>&1; then
  echo "Creating Resource Group $RG_NAME"
  az group create -n "$RG_NAME" -l "$LOCATION" >/dev/null
fi

# Create Storage Account if not exists
if ! az storage account show -n "$SA_NAME" -g "$RG_NAME" >/dev/null 2>&1; then
  echo "Creating Storage Account $SA_NAME"
  az storage account create -n "$SA_NAME" -g "$RG_NAME" -l "$LOCATION" \
    --sku Standard_LRS --min-tls-version TLS1_2 --allow-blob-public-access false >/dev/null
fi

# Get Account Key
ACCOUNT_KEY=$(az storage account keys list -n "$SA_NAME" -g "$RG_NAME" --query '[0].value' -o tsv)

# Create Container if not exists
if ! az storage container show -n "$CONTAINER_NAME" --account-name "$SA_NAME" --account-key "$ACCOUNT_KEY" >/dev/null 2>&1; then
  echo "Creating Container $CONTAINER_NAME"
  az storage container create -n "$CONTAINER_NAME" --account-name "$SA_NAME" --account-key "$ACCOUNT_KEY" >/dev/null
fi

echo "Backend ready: rg=$RG_NAME sa=$SA_NAME container=$CONTAINER_NAME"

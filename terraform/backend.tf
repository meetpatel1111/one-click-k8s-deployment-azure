// Remote state in Azure Storage. Supply values via -backend-config at init time, or fill here.
// Example init:
// terraform init -backend-config="resource_group_name=rg-tfstate" -backend-config="storage_account_name=sttfstateabc123" -backend-config="container_name=tfstate" -backend-config="key=aks/terraform.tfstate"
terraform {
  backend "azurerm" {}
}

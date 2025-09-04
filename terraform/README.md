# Azure Terraform (AKS) – Port of AWS EKS Stack

This folder mirrors your AWS `terraform/` but targets Azure:

## What it creates
- Resource Group, VNet (two subnets: system, user) and NSG
- AKS with a system pool + a user pool (autoscaling min/max similar to your EKS node group)
- ACR with `AcrPull` role assignment to the AKS kubelet identity
- Log Analytics + Diagnostics for AKS
- (Optional) App deployments via the Kubernetes provider (left commented like your AWS file)

## Files
- `versions.tf` – provider versions
- `backend.tf` – **azurerm** backend for remote state
- `provider.tf` – azurerm + kubernetes providers
- `resource-group.tf` – resource group
- `network.tf` – vnet/subnets/nsg
- `acr.tf` – Azure Container Registry + role assignment
- `aks.tf` – AKS cluster + user node pool
- `log-analytics.tf` – workspace + diagnostics
- `apps-deployment.tf` – commented Kubernetes deployments (parallel to your AWS file)
- `variables.tf`, `outputs.tf`
- `dev.tfvars`, `test.tfvars` – mirrors of your values

## Bootstrap remote state (optional)
If you want a dedicated storage account for Terraform state, use `bootstrap/` first, then copy its outputs into `-backend-config` when you run `terraform init`.

## Usage
```bash
cd azure-terraform/bootstrap
terraform init && terraform apply -var 'environment=dev' -var 'location=eastus'

# copy the outputs for the backend, then:
cd ..
terraform init   -backend-config="resource_group_name=<rg>"   -backend-config="storage_account_name=<stname>"   -backend-config="container_name=tfstate"   -backend-config="key=aks/terraform.tfstate"

# Plan/apply
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

To deploy the optional app resources, uncomment sections in `apps-deployment.tf`.

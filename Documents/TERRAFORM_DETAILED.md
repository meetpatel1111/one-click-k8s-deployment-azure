# 🌍 Terraform Detailed Guide (Azure Version)

## 1. Introduction

Terraform is the backbone of infrastructure provisioning in this repository.  
It enables **Infrastructure as Code (IaC)**, allowing teams to define, version, and reproduce **Azure infrastructure** in a consistent and auditable way.

This repository uses Terraform to provision:

- **Resource Group** (logical container for resources)  
- **Networking** (VNet + Subnets + NSGs)  
- **Azure Container Registry (ACR)** for container images  
- **Azure Kubernetes Service (AKS)** for workloads  
- **Log Analytics Workspace** for monitoring and observability  

By combining Terraform with **GitHub Actions**, the system provides one-click provisioning of Azure Kubernetes environments.

---

## 2. Philosophy of Terraform in This Repository

Terraform defines **what exists** in Azure and reconciles actual state with desired state.  
The philosophy applied here:

- **Declarative IaC** – resources are defined in `.tf` files.  
- **Environment separation** – `dev.tfvars`, `test.tfvars` provide isolation.  
- **Automation** – executed through GitHub Actions, not manual CLI.  
- **Safety** – every `apply` is preceded by a `plan`.  
- **Reversibility** – environments can be destroyed with one command.  

---

## 3. Terraform in the Workflow

Terraform runs when the workflow input `run_terraform=true`.  
Action parameter controls behavior:

- `apply` → Provision AKS + ACR + networking + monitoring  
- `destroy` → Delete all Azure resources provisioned  
- `refresh` → Sync Terraform state with actual Azure resources  

### Example Workflow Snippet

```yaml
jobs:
  terraform:
    if: ${{ github.event.inputs.run_terraform == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform init

      - name: Terraform Plan
        run: terraform plan -var-file=${{ github.event.inputs.environment }}.tfvars

      - name: Terraform Apply
        if: ${{ github.event.inputs.action == 'apply' }}
        run: terraform apply -auto-approve -var-file=${{ github.event.inputs.environment }}.tfvars

      - name: Terraform Destroy
        if: ${{ github.event.inputs.action == 'destroy' }}
        run: terraform destroy -auto-approve -var-file=${{ github.event.inputs.environment }}.tfvars
```

---

## 4. Provider & Authentication

Terraform uses the **AzureRM provider**.

```hcl
provider "azurerm" {
  features {}
}
```

### Authentication

We use a **single GitHub secret: `AZURE_CREDENTIALS`**, which contains a Service Principal JSON.  
It is consumed by `azure/login` and exported as `ARM_*` variables for Terraform.

Example JSON:

```json
{
  "clientId": "xxxx",
  "clientSecret": "xxxx",
  "subscriptionId": "xxxx",
  "tenantId": "xxxx"
}
```

---

## 5. State Management

Terraform state is stored remotely in **Azure Storage** for safety and collaboration.

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tf-backend"
    storage_account_name = "tfbackendstate001"
    container_name       = "tfstate"
    key                  = "infra.tfstate"
  }
}
```

Benefits of remote state:

- Collaboration  
- Locking to avoid conflicts  
- Versioning and recovery  

---

## 6. Core Azure Resources

### 6.1 Resource Group

```hcl
resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-deployment"
  location = "East US"
}
```

---

### 6.2 Networking (VNet, Subnets, NSG)

```hcl
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-aks"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
```

---

### 6.3 Azure Container Registry (ACR)

```hcl
resource "azurerm_container_registry" "acr" {
  name                = "acrDeploymentDemo"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}
```

---

### 6.4 Azure Kubernetes Service (AKS)

```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-deployment-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aksdemo"

  default_node_pool {
    name       = "systempool"
    node_count = 2
    vm_size    = "Standard_B4ms"
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true
}
```

Access is configured in CI/CD with:

```sh
az aks get-credentials --resource-group rg-aks-deployment --name aks-deployment-demo
```

---

### 6.5 Log Analytics Workspace

```hcl
resource "azurerm_log_analytics_workspace" "law" {
  name                = "aks-log-analytics"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
```

This integrates with **Azure Monitor for Containers**.

---

## 7. Environments (tfvars)

Each environment has its own `.tfvars` file.

### Example `dev.tfvars`

```hcl
location       = "East US"
cluster_name   = "aks-dev"
node_count     = 2
node_vm_size   = "Standard_B2s"
acr_sku        = "Basic"
```

---

## 8. Error Handling

Common failure scenarios:

- **Quota limits** → e.g., insufficient cores in region.  
- **Networking conflicts** → overlapping CIDR ranges.  
- **ACR name taken** → must be globally unique.  

Terraform plan highlights these issues early.

---

## 9. Best Practices for Azure Terraform

- Use **remote state in Azure Storage**  
- Separate environments via `.tfvars`  
- Use **RBAC + Managed Identity** for AKS  
- Monitor with **Log Analytics**  
- Rotate Service Principal credentials regularly  
- Keep node pools minimal in dev/test  

---

## 10. Conclusion

Terraform in this repo provisions a **complete AKS environment** with ACR, networking, and monitoring.  
By parameterizing environments and automating via GitHub Actions, it ensures **reproducibility, safety, and scalability**.  

End result: **One-click AKS clusters with secure CI/CD integration**.  

---

## 📑 Documentation Navigation

- [README.md](../README.md) – Root project overview  
- [DOCUMENTATION.md](./DOCUMENTATION.md) – General documentation and explanations  
- [DEPLOYMENT.md](./DEPLOYMENT.md) – Deployment workflow and parameter guide  
- [WORKFLOW_DETAILED.md](./WORKFLOW_DETAILED.md) – Detailed workflow explanation  
- [TERRAFORM_DETAILED.md](./TERRAFORM_DETAILED.md) – Terraform provisioning deep dive  
- [KUBERNETES_DETAILED.md](./KUBERNETES_DETAILED.md) – Kubernetes application deployment  
- [GITHUBACTIONS_DETAILED.md](./GITHUBACTIONS_DETAILED.md) – GitHub Actions automation  
- [DELETE_WORKFLOW_DETAILED.md](./DELETE_WORKFLOW_DETAILED.md) – Safe deletion workflow  
- [BEST_PRACTICES.md](./BEST_PRACTICES.md) – Security, scalability, and governance  
- [HANDBOOK.md](./HANDBOOK.md) – Combined handbook (all docs in one)  

🔗 Extras:  
- [HANDBOOK.html](./HANDBOOK.html) – Web-friendly version  
- [HANDBOOK_QUICKSTART.pdf](./HANDBOOK_QUICKSTART.pdf) – Quickstart summary (2–3 pages)  
- [HANDBOOK_CHEATSHEET.pdf](./HANDBOOK_CHEATSHEET.pdf) – 1-page cheatsheet  
- [HANDBOOK_CHEATSHEET_GRAPHICAL.pdf](./HANDBOOK_CHEATSHEET_GRAPHICAL.pdf) – Visual cheatsheet with diagram  
- [HANDBOOK_FULL_PRESENTATION.pptx](./HANDBOOK_FULL_PRESENTATION.pptx) – Technical slide deck  
- [HANDBOOK_EXECUTIVE_PRESENTATION.pptx](./HANDBOOK_EXECUTIVE_PRESENTATION.pptx) – Executive-friendly deck  

---
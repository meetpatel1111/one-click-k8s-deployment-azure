provider "azurerm" {
  features {}
  # subscription_id, tenant_id can be provided via environment (ARM_SUBSCRIPTION_ID, ARM_TENANT_ID) or az cli login
}

# Kubernetes provider will be configured after AKS is created using its kube_config
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

################################
# Resource Group & Cluster
################################
output "resource_group_name" {
  description = "Name of the resource group containing the AKS cluster"
  value       = azurerm_resource_group.rg.name
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

################################
# Kubeconfig outputs
################################
output "kube_config_raw" {
  description = "User kubeconfig for connecting to the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "kube_admin_config_raw" {
  description = "Admin kubeconfig for connecting to the AKS cluster (use with caution)"
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
  sensitive   = true
}

################################
# Networking
################################
output "vnet_id" {
  description = "ID of the AKS Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "system_subnet_id" {
  description = "ID of the system subnet"
  value       = azurerm_subnet.system.id
}

output "user_subnet_id" {
  description = "ID of the user subnet"
  value       = azurerm_subnet.user.id
}

################################
# ACR
################################
output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "Login server (registry FQDN) of the ACR"
  value       = azurerm_container_registry.acr.login_server
}

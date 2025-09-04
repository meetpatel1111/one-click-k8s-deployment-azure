output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

# Kubeconfig (user)
output "kube_config_raw" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

# Kubeconfig (admin) - optional but handy
output "kube_admin_config_raw" {
  value     = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
  sensitive = true
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "system_subnet_id" {
  value = azurerm_subnet.system.id
}

output "user_subnet_id" {
  value = azurerm_subnet.user.id
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "Login server (registry FQDN) of the ACR"
  value       = azurerm_container_registry.acr.login_server
}

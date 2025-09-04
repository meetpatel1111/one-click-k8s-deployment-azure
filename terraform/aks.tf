resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.cluster_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.cluster_name}-${var.environment}"
  sku_tier            = var.sku_tier

  # Optional: leave null to let Azure pick default, or set a version
  kubernetes_version = var.kubernetes_version

  # Public vs Private API server
  private_cluster_enabled = var.enable_public_access ? false : true

  # (Optional but recommended with OIDC)
  oidc_issuer_enabled       = var.oidc_issuer_enabled
  workload_identity_enabled = var.oidc_issuer_enabled

  default_node_pool {
    name                         = "system"
    vm_size                      = var.node_vm_size
    node_count                   = var.desired_capacity
    enable_auto_scaling          = true
    min_count                    = var.min_size
    max_count                    = var.max_size
    only_critical_addons_enabled = true
    vnet_subnet_id               = azurerm_subnet.system.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  # Only authorized IPs matter when public access is enabled.
  api_server_access_profile {
    authorized_ip_ranges = var.enable_public_access ? var.authorized_ip_ranges : []
  }

  tags = {
    environment = var.environment
    terraform   = "true"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "userpool" {
  name                  = "usernp"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.node_vm_size
  node_count            = var.desired_capacity
  enable_auto_scaling   = true
  min_count             = var.min_size
  max_count             = var.max_size
  mode                  = "User"
  vnet_subnet_id        = azurerm_subnet.user.id
  orchestrator_version  = azurerm_kubernetes_cluster.aks.kubernetes_version
}

# Allow AKS kubelet to pull images from ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

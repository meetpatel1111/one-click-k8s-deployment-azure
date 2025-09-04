############################################
# AKS Cluster + (Optional) User Node Pool + ACR RBAC
############################################

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.cluster_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.cluster_name}-${var.environment}"
  sku_tier            = var.sku_tier

  # Optional: let Azure pick default if null
  kubernetes_version = var.kubernetes_version

  # Public vs Private API server
  private_cluster_enabled = var.enable_public_access ? false : true

  # OIDC / Workload Identity
  oidc_issuer_enabled       = var.oidc_issuer_enabled
  workload_identity_enabled = var.oidc_issuer_enabled

  # Single pool for now (system + workloads).
  # When a user pool is enabled, this flips to "critical-only".
  default_node_pool {
    name                         = "system"
    vm_size                      = var.node_vm_size
    node_count                   = var.desired_capacity
    enable_auto_scaling          = true
    min_count                    = var.min_size
    max_count                    = var.max_size
    only_critical_addons_enabled = var.enable_user_pool
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

    # Must not overlap with your VNet/subnets
    service_cidr   = var.service_cidr
    dns_service_ip = var.dns_service_ip
  }

  # When public access is enabled, optionally restrict IPs
  api_server_access_profile {
    authorized_ip_ranges = var.enable_public_access ? var.authorized_ip_ranges : []
  }

  tags = {
    environment = var.environment
    terraform   = "true"
  }

  # Avoid drift when the autoscaler adjusts node_count
  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }

  # Cross-variable check belongs at the resource level
  precondition {
    condition     = cidrhost(var.service_cidr, 10) == var.dns_service_ip
    error_message = "dns_service_ip must be inside service_cidr (${var.service_cidr})."
  }
}

# --------------------------------------------
# FUTURE USE: Dedicated User Pool for workloads
# --------------------------------------------
# resource "azurerm_kubernetes_cluster_node_pool" "userpool" {
#   name                  = "usernp"
#   kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
#   vm_size               = var.user_node_vm_size
#
#   # Start at 0; autoscaler adds nodes on demand
#   node_count            = var.user_desired_capacity
#   enable_auto_scaling   = true
#   min_count             = var.user_min_size
#   max_count             = var.user_max_size
#
#   mode                  = "User"
#   vnet_subnet_id        = azurerm_subnet.user.id
#   orchestrator_version  = azurerm_kubernetes_cluster.aks.kubernetes_version
#
#   tags = {
#     environment = var.environment
#     terraform   = "true"
#   }
#
#   lifecycle {
#     ignore_changes = [
#       node_count
#     ]
#   }
# }

# Allow AKS kubelet to pull from ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

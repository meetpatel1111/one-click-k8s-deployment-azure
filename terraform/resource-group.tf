resource "azurerm_resource_group" "rg" {
  name     = coalesce(var.resource_group_name, "${var.cluster_name}-${var.environment}-rg")
  location = var.location
  tags = {
    environment = var.environment
    workload    = "aks"
    terraform   = "true"
  }
}

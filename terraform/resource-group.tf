resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  tags = {
    environment = var.environment
    workload    = "aks"
    terraform   = "true"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = local.rg_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = false

  tags = {
    environment = var.environment
  }
}

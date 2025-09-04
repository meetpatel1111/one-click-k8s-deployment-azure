resource "azurerm_resource_group" "tf" {
  name     = coalesce(var.resource_group_name, "tfstate-${var.environment}-rg")
  location = var.location
}

resource "random_string" "sa_suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "azurerm_storage_account" "sa" {
  name                            = coalesce(var.storage_account_name, "sttf${var.environment}${random_string.sa_suffix.result}")
  resource_group_name             = azurerm_resource_group.tf.name
  location                        = azurerm_resource_group.tf.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "state" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

output "backend_resource_group_name" { value = azurerm_resource_group.tf.name }
output "backend_storage_account_name" { value = azurerm_storage_account.sa.name }
output "backend_container_name" { value = azurerm_storage_container.state.name }
output "backend_key" { value = "aks/terraform.tfstate" }

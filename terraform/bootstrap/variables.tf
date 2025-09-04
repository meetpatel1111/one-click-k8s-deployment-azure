variable "environment" { type = string }
variable "location"    { type = string  default = "eastus" }
variable "resource_group_name" {
  type        = string
  default     = null
  description = "RG for state (default: tfstate-<env>-rg)"
}
variable "storage_account_name" {
  type        = string
  default     = null
  description = "Storage account for state (must be globally unique, 3-24 lowercase alphanumerics)"
}
variable "container_name" {
  type        = string
  default     = "tfstate"
}

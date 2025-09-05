################################
# Locals for naming convention
################################

locals {
  # Core prefix: {envtype}-{short_location}-{environment}  (example: np-use-dev)
  resource_prefix = "${var.environment_type}-${var.short_location}-${var.environment}"

  # Resource Group (fallback to computed name if var set to null)
  rg_name = coalesce(var.resource_group_name, "rg-${local.resource_prefix}")

  # Cluster (dashed name for human-friendly resources)
  aks_name = coalesce(var.cluster_name, "aks-${local.resource_prefix}")

  # DNS prefix must be a valid DNS name (lowercase, numbers, hyphen). Remove invalid chars.
  aks_dns_prefix = lower(regexreplace(local.aks_name, "[^a-z0-9-]", ""))

  # Nodepool names: system (System-mode), default (User-mode)
  system_nodepool_name = "system"
  user_nodepool_name   = "default"

  # VNet / Subnet / NSG / Log Analytics / Diagnostic names
  vnet_name           = "vnet-${local.resource_prefix}"
  system_subnet_name  = "snet-system-${local.resource_prefix}"
  user_subnet_name    = "snet-user-${local.resource_prefix}"
  nsg_name            = "nsg-aks-${local.resource_prefix}"
  log_analytics_name  = "law-${local.resource_prefix}"
  aks_diagnostic_name = "diag-${local.aks_name}"

  # Human-friendly ACR display name following your convention:
  acr_display_name = "acr-${local.resource_prefix}" # e.g. "acr-np-use-dev"

  # Actual ACR resource name must be lowercase, alphanumeric, no dashes:
  acr_name = lower(replace(local.acr_display_name, "-", ""))

  # Short dashless helper for storage-like resources that can't have hyphens.
  dashless_resource_prefix = replace(local.resource_prefix, "-", "")
}

################################
# Core / environment
################################

variable "environment" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group to create"
  type        = string
  default     = null
}

variable "cluster_name" {
  type = string
}

################################
# Networking (VNet/Subnets)
################################

variable "vnet_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "system_subnet_cidr" {
  type    = string
  default = "10.0.0.0/20"
}

variable "user_subnet_cidr" {
  type    = string
  default = "10.0.16.0/20"
}

################################
# AKS settings
################################

variable "kubernetes_version" {
  type    = string
  default = null
}

# Quota-friendly defaults (adjust in tfvars when you have more quota)
variable "node_vm_size" {
  type    = string
  default = "Standard_B4ms" # was B2s; B1ms uses 1 vCPU
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 1
}

variable "sku_tier" {
  type    = string
  default = "Free" # or "Paid"
}

variable "oidc_issuer_enabled" {
  type    = bool
  default = true
}

# Toggle a dedicated User pool later (kept commented in aks.tf by default)
variable "enable_user_pool" {
  type    = bool
  default = false
}

variable "user_node_vm_size" {
  type    = string
  default = "Standard_B1ms"
}

variable "user_desired_capacity" {
  type    = number
  default = 0
}

variable "user_min_size" {
  type    = number
  default = 0
}

variable "user_max_size" {
  type    = number
  default = 1
}

################################
# ACR
################################

variable "acr_name" {
  type    = string
  default = null
}

variable "acr_sku" {
  type    = string
  default = "Basic"
}

################################
# Images & replicas
################################

variable "nodejs_docker_image" {
  type    = string
  default = null
}

variable "mini_budget_tracker_image" {
  type    = string
  default = null
}

variable "retro_arcade_docker_image" {
  type    = string
  default = null
}

variable "nginx_replicas" {
  type    = number
  default = 2
}

variable "nodejs_replicas" {
  type    = number
  default = 2
}

variable "mini_budget_tracker_replicas" {
  type    = number
  default = 2
}

variable "retro_arcade_galaxy_replicas" {
  type    = number
  default = 2
}

variable "k8sgpt_replicas" {
  type    = number
  default = 1
}

variable "nginx_hpa_max" {
  type    = number
  default = 5
}

variable "nodejs_hpa_max" {
  type    = number
  default = 5
}

variable "mini_budget_tracker_hpa_max" {
  type    = number
  default = 5
}

variable "retro_arcade_galaxy_hpa_max" {
  type    = number
  default = 3
}

variable "k8sgpt_hpa_max" {
  type    = number
  default = 5
}

################################
# API server access
################################

variable "enable_public_access" {
  description = "If false, makes AKS private. If true, public API server with optional authorized IP ranges."
  type        = bool
  default     = true
}

variable "authorized_ip_ranges" {
  description = "CIDR list allowed to reach AKS API server if public."
  type        = list(string)
  default     = []
}

################################
# AKS Service CIDRs (must not overlap VNet/Subnets)
################################

variable "service_cidr" {
  type    = string
  default = "10.2.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.service_cidr))
    error_message = "service_cidr must be a valid CIDR."
  }
}

variable "dns_service_ip" {
  type    = string
  default = "10.2.0.10"

  # IP format check (no cross-var refs)
  validation {
    condition     = can(cidrhost(format("%s/32", var.dns_service_ip), 0))
    error_message = "dns_service_ip must be a valid IPv4 address."
  }
}

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

# Networking
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

# AKS settings
variable "kubernetes_version" {
  type    = string
  default = null
}

variable "node_vm_size" {
  type    = string
  default = "Standard_DS2_v2"
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 3
}

variable "enable_private_cluster" {
  type    = bool
  default = false
}

variable "sku_tier" {
  type    = string
  default = "Free" # or "Paid"
}

variable "oidc_issuer_enabled" {
  type    = bool
  default = true
}

# ACR
variable "acr_name" {
  type    = string
  default = null
}

variable "acr_sku" {
  type    = string
  default = "Basic"
}

# Images & replicas (to mirror current app vars)
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

# API server access
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

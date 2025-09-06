################################
# Environment / Naming
################################

# Short environment type: np (nonprod), p (prod), etc.
variable "environment_type" {
  description = "Environment type short code (e.g., np = non-prod, p = prod)"
  type        = string
}

# Short region code: use (eastus), eus (eastus2), wus (westus), uks (uksouth), etc.
variable "short_location" {
  description = "Short code for Azure location (eastus = use, westus = wus, etc.)"
  type        = string
}

################################
# Core / environment
################################

variable "environment" {
  description = "Logical environment name (dev, stg, prod, etc.)"
  type        = string
}

variable "location" {
  description = "Azure region (full name, e.g. 'eastus')"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group to create (optional). If null, computed from locals."
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "Cluster short name (optional). If null locals will compute 'aks-{envtype}-{shortloc}-{environment}'."
  type        = string
  default     = null
}

################################
# Networking (VNet/Subnets)
################################

variable "vnet_cidr" {
  description = "Address space for virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "system_subnet_cidr" {
  description = "CIDR for the system subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "user_subnet_cidr" {
  description = "CIDR for the user workloads subnet"
  type        = string
  default     = "10.0.16.0/20"
}

################################
# AKS settings
################################

variable "kubernetes_version" {
  description = "Kubernetes version (leave null to let Azure choose)."
  type        = string
  default     = null
}

variable "node_vm_size" {
  description = "VM size for the system node pool"
  type        = string
  default     = "Standard_B4ms"
}

variable "desired_capacity" {
  description = "Initial node count for system pool (can be autoscaled)"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum nodes for system autoscaler"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum nodes for system autoscaler"
  type        = number
  default     = 1
}

variable "sku_tier" {
  description = "AKS SKU tier (Free/Paid)"
  type        = string
  default     = "Free"
}

variable "oidc_issuer_enabled" {
  description = "Enable OIDC / workload identity"
  type        = bool
  default     = true
}

variable "enable_user_pool" {
  description = "Create a separate user node pool for workloads"
  type        = bool
  default     = false
}

variable "user_node_vm_size" {
  description = "VM size for the optional user node pool"
  type        = string
  default     = "Standard_B1ms"
}

variable "user_desired_capacity" {
  description = "Initial desired nodes for user pool"
  type        = number
  default     = 0
}

variable "user_min_size" {
  description = "Minimum for user pool autoscaler"
  type        = number
  default     = 0
}

variable "user_max_size" {
  description = "Maximum for user pool autoscaler"
  type        = number
  default     = 1
}

################################
# ACR
################################

variable "acr_name" {
  description = "Optional ACR name (must be globally unique, lowercase, alphanumeric, no dashes). If null, a local will compute a safe fallback."
  type        = string
  default     = null
}

variable "acr_sku" {
  description = "ACR SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"
}

################################
# Images & replicas
################################

variable "nodejs_docker_image" {
  description = "NodeJS image reference (optional)"
  type        = string
  default     = null
}

variable "mini_budget_tracker_image" {
  description = "Mini budget tracker image reference (optional)"
  type        = string
  default     = null
}

variable "retro_arcade_docker_image" {
  description = "Retro arcade image reference (optional)"
  type        = string
  default     = null
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
  description = "Cluster service CIDR"
  type        = string
  default     = "10.2.0.0/16"
}

variable "dns_service_ip" {
  description = "Cluster DNS service IP"
  type        = string
  default     = "10.2.0.10"
}

################################
# Network / NSG helper variables
################################

variable "health_check_node_port" {
  description = "Azure LB health probe nodePort. Must match Service.spec.healthCheckNodePort for LoadBalancer services (e.g. ingress controller)."
  type        = number
  default     = 31593
}

variable "nodeport_range" {
  description = "NodePort range as a single string used in destination_port_ranges (e.g. \"30000-32767\")."
  type        = string
  default     = "30000-32767"
}

# Terraform will create the Allow-HTTP-HTTPS-From-MyCIDR rule only when this list is non-empty.
# If you want Terraform to manage a single rule that allows Internet, use ["Internet"] here.
# If you want it locked down by default, keep this empty and add your CIDR(s) in terraform.tfvars.
variable "allowed_client_cidrs" {
  description = "List of CIDRs allowed to access HTTP/HTTPS on nodes. Terraform will use the first entry to create the single rule Allow-HTTP-HTTPS-From-MyCIDR. Keep empty to not create the rule."
  type        = list(string)
  default     = ["Internet"]
}

variable "allow_nodeports_from_internet" {
  description = "If true, create an NSG rule allowing NodePort range from Internet (not recommended for production)."
  type        = bool
  default     = true
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDRs allowed to SSH to nodes. Empty list = no SSH rule created."
  type        = list(string)
  default     = []
}

################################
# Environment
################################
environment         = "dev"
environment_type    = "np" # non-prod
location            = "eastus"
short_location      = "use" # short code for eastus
resource_group_name = null  # let locals compute rg-np-use-dev
cluster_name        = null  # let locals compute aks-np-use-dev

################################
# ACR
################################
acr_name = null # let locals compute acrdevusenp
acr_sku  = "Basic"

################################
# Node pool (system pool)
################################
#node_vm_size     = "Standard_B4ms"
node_vm_size     = "Standard_B2s"
desired_capacity = 2
min_size         = 2
max_size         = 3

################################
# Optional user pool (disabled for now)
################################
enable_user_pool = false
#user_node_vm_size     = "Standard_B4ms"
user_node_vm_size     = "Standard_B2s"
user_desired_capacity = 0
user_min_size         = 0
user_max_size         = 1

################################
# Images (strings)
################################
nodejs_docker_image       = "acrnpusedev.azurecr.io/nodejs-app:dev"
mini_budget_tracker_image = "acrnpusedev.azurecr.io/mini-budget:dev"
retro_arcade_docker_image = "acrnpusedev.azurecr.io/retro-arcade-galaxy:dev"

################################
# Replicas / HPA (numbers)
################################
nginx_replicas               = 2
nodejs_replicas              = 2
mini_budget_tracker_replicas = 2
retro_arcade_galaxy_replicas = 2
k8sgpt_replicas              = 1

nginx_hpa_max               = 5
nodejs_hpa_max              = 5
mini_budget_tracker_hpa_max = 5
retro_arcade_galaxy_hpa_max = 3
k8sgpt_hpa_max              = 3

################################
# API server access
################################
enable_public_access = true
authorized_ip_ranges = []

################################
# AKS service CIDRs
################################
service_cidr   = "10.2.0.0/16"
dns_service_ip = "10.2.0.10"

################################
# Network / NSG overrides
################################

# Keep Internet open for now (works like your current setup).
# Later you can lock this down by replacing with your office/home CIDR.
allowed_client_cidrs = ["Internet"]

# Keep NodePorts accessible from Internet for ingress services (default true).
allow_nodeports_from_internet = true

# SSH is disabled by default (empty). Add your IP if you ever want SSH access.
ssh_allowed_cidrs = []

# Health probe port is fixed for AKS-managed LB (matches ingress controller).
health_check_node_port = 31593

# NodePort range (default AKS range).
nodeport_range = "30000-32767"

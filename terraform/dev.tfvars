################################
# Environment
################################
environment         = "dev"
location            = "eastus"
resource_group_name = "rg-aks-dev"
cluster_name        = "aks-dev"

################################
# ACR
################################
acr_name = "acrdevjm"
acr_sku  = "Basic"

################################
# Node pool (system pool)
################################
node_vm_size     = "Standard_B4ms"
desired_capacity = 1
min_size         = 1
max_size         = 1

################################
# Optional user pool (disabled for now)
################################
enable_user_pool      = false
user_node_vm_size     = "Standard_B4ms"
user_desired_capacity = 0
user_min_size         = 0
user_max_size         = 1

################################
# Images (strings)
################################
nodejs_docker_image       = "acrdevjm.azurecr.io/nodejs-app:dev"
mini_budget_tracker_image = "acrdevjm.azurecr.io/mini-budget:dev"
retro_arcade_docker_image = "acrdevjm.azurecr.io/retro-arcade-galaxy:dev"

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

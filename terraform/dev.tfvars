# Required strings must be quoted
environment         = "dev"
location            = "eastus"
resource_group_name = "rg-aks-dev"
cluster_name        = "aks-dev"

# ACR
acr_name = "acrdevjm"
acr_sku  = "Basic"

# Node pool
node_vm_size     = "Standard_B2s"
desired_capacity = 2
min_size         = 1
max_size         = 3

# Images (strings)
nodejs_docker_image       = "acrdevjm.azurecr.io/nodejs-app:${var.environment}"
mini_budget_tracker_image = "acrdevjm.azurecr.io/mini-budget:${var.environment}"
retro_arcade_docker_image = "acrdevjm.azurecr.io/retro-arcade-galaxy:${var.environment}"

# Replicas / HPA (numbers)
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

# Booleans/lists don’t need quotes
enable_public_access = true
authorized_ip_ranges = []

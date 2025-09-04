# Required strings must be quoted
environment         = "dev"
location            = "eastus"
resource_group_name = "rg-aks-dev"
cluster_name        = "aks-dev"

# ACR
acr_name = "acrdev"
acr_sku  = "Basic"

# Node pool
node_vm_size     = "Standard_DS2_v2"
desired_capacity = 2
min_size         = 1
max_size         = 3

# Images (strings)
nodejs_docker_image       = "acrdev.azurecr.io/nodejs-app:latest"
mini_budget_tracker_image = "acrdev.azurecr.io/mini-budget:latest"
retro_arcade_docker_image = "acrdev.azurecr.io/retro-arcade-galaxy:latest"

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

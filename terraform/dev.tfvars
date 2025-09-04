# Example dev environment values mirroring your AWS inputs
environment          = "dev"
location             = "eastus"
cluster_name         = "aks-cluster"
vnet_cidr            = "10.0.0.0/16"
system_subnet_cidr   = "10.0.0.0/20"
user_subnet_cidr     = "10.0.16.0/20"
node_vm_size         = "Standard_DS2_v2"
desired_capacity     = 2
min_size             = 1
max_size             = 3
enable_public_access = true
authorized_ip_ranges = []

# Images
nodejs_docker_image       = "meetpatel1111/nodejs-app:dev"
mini_budget_tracker_image = "meetpatel1111/mini-budget-tracker:dev"
retro_arcade_docker_image = "meetpatel1111/retro-arcade-galaxy:dev"

# Replicas & HPA max (if you enable the app resources)
nginx_replicas               = 2
nginx_hpa_max                = 5
nodejs_replicas              = 2
nodejs_hpa_max               = 5
mini_budget_tracker_replicas = 2
mini_budget_tracker_hpa_max  = 5
k8sgpt_replicas              = 1
k8sgpt_hpa_max               = 4
retro_arcade_galaxy_replicas = 2
retro_arcade_galaxy_hpa_max  = 3
acr_name                     = acrdev

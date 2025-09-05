# Example test/stage environment
environment      = "test"
environment_type = "np" # non-prod
location         = "eastus2"
short_location   = "eus" # short code for eastus2

# Let locals compute RG/cluster names by default (set to non-null to override)
resource_group_name = null
cluster_name        = null

vnet_cidr          = "10.1.0.0/16"
system_subnet_cidr = "10.1.0.0/20"
user_subnet_cidr   = "10.1.16.0/20"

node_vm_size     = "Standard_DS2_v2"
desired_capacity = 2
min_size         = 1
max_size         = 4

enable_public_access = true
authorized_ip_ranges = []

# Optional: override ACR name; otherwise local.acr_name will be used
acr_name = null
acr_sku  = "Basic"

# Images (if you publish to ACR, replace acrdevjm with your ACR or leave as-is)
nodejs_docker_image       = "acrnpusetest.azurecr.io/nodejs-app:latest"
mini_budget_tracker_image = "acrnpusetest.azurecr.io/mini-budget:latest"
retro_arcade_docker_image = "acrnpusetest.azurecr.io/retro-arcade-galaxy:latest"

# Replicas & HPA max (if you enable the app resources)
nginx_replicas               = 2
nginx_hpa_max                = 5
nodejs_replicas              = 2
nodejs_hpa_max               = 5
mini_budget_tracker_replicas = 2
mini_budget_tracker_hpa_max  = 5
k8sgpt_replicas              = 2
k8sgpt_hpa_max               = 4
retro_arcade_galaxy_replicas = 2
retro_arcade_galaxy_hpa_max  = 3

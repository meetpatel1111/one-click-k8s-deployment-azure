###############################################################################
# network.tf
# VNet, subnets, NSG (secure defaults), subnet <-> NSG associations
###############################################################################

# ---------------------------------------------------------------------------
# Virtual Network
# ---------------------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_cidr]

  tags = {
    environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------
resource "azurerm_subnet" "system" {
  name                 = local.system_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.system_subnet_cidr]
}

resource "azurerm_subnet" "user" {
  name                 = local.user_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.user_subnet_cidr]
}

# ---------------------------------------------------------------------------
# Network Security Group
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "aks" {
  name                = local.nsg_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Security Rules
# ---------------------------------------------------------------------------

# 1) Allow Azure LB health probes to node health-check port
resource "azurerm_network_security_rule" "allow_lb_health_probe" {
  name                        = "Allow-AzureLB-HealthProbe"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = [tostring(var.health_check_node_port)]
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  description                 = "Allow Azure Load Balancer health probes to node health-check port"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# 2) Allow Azure LB to reach NodePort range
resource "azurerm_network_security_rule" "allow_lb_nodeports" {
  name                        = "Allow-AzureLB-NodePortRange"
  priority                    = 105
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = [var.nodeport_range]
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  description                 = "Allow Azure LoadBalancer to reach NodePort range"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# 3) Optional: Allow HTTP/HTTPS from first configured CIDR
resource "azurerm_network_security_rule" "allow_http_https_cidr" {
  count                       = length(var.allowed_client_cidrs) > 0 ? 1 : 0
  name                        = "Allow-HTTP-HTTPS-From-MyCIDR"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = element(var.allowed_client_cidrs, 0)
  destination_address_prefix  = "*"
  description                 = "Allow HTTP/HTTPS from first configured CIDR"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# 4) Optional: Allow NodePorts from Internet
resource "azurerm_network_security_rule" "allow_nodeports_internet" {
  count                       = var.allow_nodeports_from_internet ? 1 : 0
  name                        = "Allow-NodePorts-From-Internet"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = [var.nodeport_range]
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  description                 = "Allow NodePorts from Internet (optional)"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# 5) Optional: Allow SSH from each configured CIDR
resource "azurerm_network_security_rule" "allow_ssh" {
  for_each                    = toset(var.ssh_allowed_cidrs)
  name                        = "Allow-SSH-${replace(each.key, "/", "-")}"
  priority                    = 300 + index(var.ssh_allowed_cidrs, each.key)
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = each.key
  destination_address_prefix  = "*"
  description                 = "Allow SSH from ${each.key}"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# 6) Egress: allow HTTPS outbound
resource "azurerm_network_security_rule" "allow_https_out" {
  name                        = "Allow-HTTPS-Outbound"
  priority                    = 1000
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  description                 = "Allow outbound HTTPS"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# ---------------------------------------------------------------------------
# NSG Associations
# ---------------------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "system" {
  subnet_id                 = azurerm_subnet.system.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

resource "azurerm_subnet_network_security_group_association" "user" {
  subnet_id                 = azurerm_subnet.user.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

###############################################################################
# network.tf
# VNet, subnets, NSG (secure defaults), subnet <-> NSG associations
# Uses locals from your locals.tf (vnet_name, system_subnet_name, user_subnet_name, nsg_name)
###############################################################################

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_cidr]

  tags = {
    environment = var.environment
  }
}

# System subnet (for AKS system nodepool)
resource "azurerm_subnet" "system" {
  name                 = local.system_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.system_subnet_cidr]
}

# User subnet (for workloads)
resource "azurerm_subnet" "user" {
  name                 = local.user_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.user_subnet_cidr]
}

###############################################################################
# Network Security Group
###############################################################################
resource "azurerm_network_security_group" "aks" {
  name                = local.nsg_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # 1) ALLOW: Azure Load Balancer health probe -> specific node health port
  security_rule {
    name                       = "Allow-AzureLB-HealthProbe"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = [tostring(var.health_check_node_port)]
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
    description                = "Allow Azure Load Balancer health probes to node health-check port"
  }

  # 2) ALLOW: AzureLoadBalancer -> NodePort range (so LB can forward NodePort traffic)
  security_rule {
    name                       = "Allow-AzureLB-NodePortRange"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = [var.nodeport_range]
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
    description                = "Allow AzureLoadBalancer to reach NodePort range"
  }

  # 3) SINGLE RULE: HTTP/HTTPS from the first configured CIDR
  #    This creates one rule named "Allow-HTTP-HTTPS-From-MyCIDR" with source = var.allowed_client_cidrs[0]
  #    If allowed_client_cidrs is empty, this rule is not created.
  security_rule {
    count                   = length(var.allowed_client_cidrs) > 0 ? 1 : 0
    name                    = "Allow-HTTP-HTTPS-From-MyCIDR"
    priority                = 110
    direction               = "Inbound"
    access                  = "Allow"
    protocol                = "Tcp"
    source_port_range       = "*"
    destination_port_ranges = ["80", "443"]
    # Use first CIDR in the list (allowing you to manage one rule via terraform)
    source_address_prefix      = var.allowed_client_cidrs[0]
    destination_address_prefix = "*"
    description                = "Allow HTTP/HTTPS from configured CIDR (first entry)"
  }

  # 4) OPTIONAL: Allow NodePort range from Internet (create only if requested)
  security_rule {
    count                      = var.allow_nodeports_from_internet ? 1 : 0
    name                       = "Allow-NodePorts-From-Internet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = [var.nodeport_range]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    description                = "Allow NodePorts from Internet (optional)"
  }

  # 5) OPTIONAL: Per-CIDR SSH allow rules (if any)
  dynamic "ssh_rule" {
    for_each = length(var.ssh_allowed_cidrs) > 0 ? var.ssh_allowed_cidrs : []
    content {
      name                       = "Allow-SSH-From-${replace(ssh_rule.value, "/", "-")}"
      priority                   = 300 + index(var.ssh_allowed_cidrs, ssh_rule.value)
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = ssh_rule.value
      source_port_range          = "*"
      destination_port_range     = "22"
      destination_address_prefix = "*"
      description                = "Allow SSH from ${ssh_rule.value}"
    }
  }

  # 6) Egress: allow HTTPS outbound
  security_rule {
    name                       = "Allow-HTTPS-Outbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow outbound HTTPS"
  }

  # -------------------------------------------------------------------------
  # Commented rule: ALLOW HTTP/HTTPS from Internet to nodes (kept commented)
  # If you want to open 80/443 to the whole Internet, uncomment the block below.
  # -------------------------------------------------------------------------
  # security_rule {
  #   name                       = "Allow-HTTP-HTTPS-From-Internet"
  #   priority                   = 130
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_ranges    = ["80", "443"]
  #   source_address_prefix      = "Internet"
  #   destination_address_prefix = "*"
  #   description                = "Allow HTTP/HTTPS from Internet (uncomment to enable)"
  # }

  tags = {
    environment = var.environment
  }
}

###############################################################################
# NSG associations - apply NSG to subnets
###############################################################################
resource "azurerm_subnet_network_security_group_association" "system" {
  subnet_id                 = azurerm_subnet.system.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

resource "azurerm_subnet_network_security_group_association" "user" {
  subnet_id                 = azurerm_subnet.user.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

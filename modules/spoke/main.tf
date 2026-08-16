resource "random_string" "flow_log_storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "spoke" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "time_sleep" "after_resource_group" {
  create_duration = "30s"
  depends_on      = [azurerm_resource_group.spoke]
}

resource "azurerm_storage_account" "flow_logs" {
  name                     = "stfl${replace(var.environment, "-", "")}${random_string.flow_log_storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.spoke.name
  location                 = azurerm_resource_group.spoke.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.spoke_vnet_cidr]
  tags                = var.tags
  depends_on          = [time_sleep.after_resource_group]
}

resource "azurerm_subnet" "subnet_app" {
  name                 = "snet-${var.environment}-app"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.app_subnet_cidr]
}

resource "azurerm_subnet" "private_endpoints" {
  name                              = "snet-${var.environment}-pe"
  resource_group_name               = azurerm_resource_group.spoke.name
  virtual_network_name              = azurerm_virtual_network.spoke.name
  address_prefixes                  = [var.private_endpoint_subnet_cidr]
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-${var.environment}-aks"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.aks_subnet_cidr]
}

resource "azurerm_route_table" "spoke" {
  name                          = "rt-${var.environment}-app"
  location                      = azurerm_resource_group.spoke.location
  resource_group_name           = azurerm_resource_group.spoke.name
  bgp_route_propagation_enabled = false
  tags                          = var.tags

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "app" {
  subnet_id      = azurerm_subnet.subnet_app.id
  route_table_id = azurerm_route_table.spoke.id
}

resource "azurerm_subnet_route_table_association" "aks" {
  subnet_id      = azurerm_subnet.aks.id
  route_table_id = azurerm_route_table.spoke.id
}

# --- NSG: tier appropriate baseline, defense in depth alongside the UDR

resource "azurerm_network_security_group" "app_nsg" {
  name                = "nsg-${var.environment}-app"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = var.tags
  security_rule {
    name                       = "deny-all-inbound-internet"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.subnet_app.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_network_security_group" "private_endpoints_nsg" {
  name                = "nsg-${var.environment}-pe"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints_nsg.id
}

resource "azurerm_network_security_group" "aks" {
  name                = "nsg-${var.environment}-aks"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = var.tags
  security_rule {
    name                       = "deny-all-inbound-internet"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}


resource "azurerm_resource_group" "network_watcher" {
  name     = "NetworkWatcherRG"
  location = var.location
  tags     = var.tags
}

resource "azurerm_network_watcher" "spoke" {
  name                = "NetworkWatcher_${var.location}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_watcher.name
  tags                = var.tags
}

# --- NSG Flow Logs -> centralized Log Analytics

resource "azurerm_network_watcher_flow_log" "app" {
  name                 = "fl-vnet-${var.environment}"
  network_watcher_name = azurerm_network_watcher.spoke.name
  resource_group_name  = azurerm_network_watcher.spoke.resource_group_name
  target_resource_id   = azurerm_virtual_network.spoke.id
  storage_account_id   = azurerm_storage_account.flow_logs.id
  tags                 = var.tags
  enabled              = true

  retention_policy {
    enabled = true
    days    = 30
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "35m"
  }
}
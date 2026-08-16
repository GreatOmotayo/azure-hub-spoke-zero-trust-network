module "log_analytics" {
  source              = "./modules/log-analytics"
  location            = var.location
  resource_group_name = "rg-hub-shared-services"
  tags                = var.project_tags
  retention_in_days   = 30
  daily_quota_gb      = 1
}

module "hub" {
  source                      = "./modules/hub"
  location                    = var.location
  resource_group_name         = "rg-hub-network"
  tags                        = var.project_tags
  hub_vnet_cidr               = var.hub_vnet_cidr
  firewall_subnet_cidr        = var.hub_firewall_subnet_cidr
  bastion_subnet_cidr         = var.hub_bastion_subnet_cidr
  shared_services_subnet_cidr = var.hub_shared_services_subnet_cidr
  firewall_sku_tier           = "Standard"
  bastion_sku                 = "Standard"
  log_analytics_workspace_id  = module.log_analytics.workspace_id
}

module "spoke_production" {
  source = "./modules/spoke"

  providers = {
    azurerm = azurerm.production
  }

  environment                         = "production"
  location                            = var.location
  resource_group_name                 = "rg-production-network"
  tags                                = merge(var.project_tags, { environment = "production" })
  spoke_vnet_cidr                     = var.production_vnet_cidr
  app_subnet_cidr                     = var.production_app_subnet_cidr
  private_endpoint_subnet_cidr        = var.production_pe_subnet_cidr
  aks_subnet_cidr                     = var.production_aks_subnet_cidr
  firewall_private_ip_address         = module.hub.firewall_private_ip_address
  log_analytics_workspace_id          = module.log_analytics.workspace_id
  log_analytics_workspace_customer_id = module.log_analytics.workspace_customer_id
}

module "spoke_nonproduction" {
  source = "./modules/spoke"

  providers = {
    azurerm = azurerm.non-production
  }

  environment                         = "non-production"
  location                            = var.location
  resource_group_name                 = "rg-non-production-network"
  tags                                = merge(var.project_tags, { environment = "non-production" })
  spoke_vnet_cidr                     = var.non_production_vnet_cidr
  app_subnet_cidr                     = var.non_production_app_subnet_cidr
  private_endpoint_subnet_cidr        = var.non_production_pe_subnet_cidr
  aks_subnet_cidr                     = var.non_production_aks_subnet_cidr
  firewall_private_ip_address         = module.hub.firewall_private_ip_address
  log_analytics_workspace_id          = module.log_analytics.workspace_id
  log_analytics_workspace_customer_id = module.log_analytics.workspace_customer_id
}

module "peering_hub_production" {
  source = "./modules/peering"

  providers = {
    azurerm.hub   = azurerm
    azurerm.spoke = azurerm.production
  }
  depends_on                = [module.spoke_production]
  hub_vnet_id               = module.hub.vnet_id
  hub_vnet_name             = module.hub.vnet_name
  hub_resource_group_name   = module.hub.resource_group_name
  spoke_vnet_id             = module.spoke_production.vnet_id
  spoke_vnet_name           = module.spoke_production.vnet_name
  spoke_resource_group_name = module.spoke_production.resource_group_name
  environment               = "production"
}

module "peering_hub_non_production" {
  source = "./modules/peering"
  providers = {
    azurerm.hub   = azurerm
    azurerm.spoke = azurerm.non-production
  }

  depends_on                = [module.spoke_nonproduction]
  hub_vnet_id               = module.hub.vnet_id
  hub_vnet_name             = module.hub.vnet_name
  hub_resource_group_name   = module.hub.resource_group_name
  spoke_vnet_id             = module.spoke_nonproduction.vnet_id
  spoke_vnet_name           = module.spoke_nonproduction.vnet_name
  spoke_resource_group_name = module.spoke_nonproduction.resource_group_name
  environment               = "non-production"
}
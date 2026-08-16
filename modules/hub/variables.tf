variable "location" {
  type        = string
  description = "Azure region for the hub resource"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for hub resource"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all hub resources"
}

variable "hub_vnet_cidr" {
  type        = string
  description = "Address space for the hub VNet"
}

variable "firewall_subnet_cidr" {
  type        = string
  description = "AzureFirewallSubnet CIDR"
}

variable "bastion_subnet_cidr" {
  type        = string
  description = "AzureBastionSubnet CIDR"
}

variable "shared_services_subnet_cidr" {
  type        = string
  description = "Reserved subnet for the future shared services (monitoring private endpoints etc)"
}

variable "firewall_sku_tier" {
  type        = string
  description = "Azure Firewall SKU tier"
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.firewall_sku_tier)
    error_message = "firewall_sku_tier must be Basic, Standard or Premium"
  }
}

variable "bastion_sku" {
  type        = string
  description = "Azure Bastion SKU"
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.bastion_sku)
    error_message = "bastion_sku must be Basic or Standard"
  }
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the centralized Log Analytics workspace for diagnostic settings"
}





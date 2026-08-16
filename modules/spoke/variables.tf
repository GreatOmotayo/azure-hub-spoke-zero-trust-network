variable "environment" {
  description = "Environment name - used in resource naming and tags"
  type        = string

  validation {
    condition     = contains(["production", "non-production"], var.environment)
    error_message = "environment must be production or non_production"
  }
}

variable "location" {
  description = "Azure region for this spoke's resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group for this spoke"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources in this spoke"
  type        = map(string)
}

variable "spoke_vnet_cidr" {
  description = "Address space for this spoke's VNet"
  type        = string
}

variable "app_subnet_cidr" {
  description = "Workload/application subnet CIDR"
  type        = string
}

variable "private_endpoint_subnet_cidr" {
  description = "Subnet CIDR for key Vault / Storage private endpoints"
  type        = string
}

variable "aks_subnet_cidr" {
  description = "Reserved CIDR for the future AKS node subnet - NOT provisioned as a subnet by this module, reservation only"
  type        = string
}

variable "firewall_private_ip_address" {
  description = "Private IP of the hub Azure Firewall - used as next hop in this spoke's forced-tunneling route table"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Full ARM resource ID of the centralized Log Analytics workspace - used for diagnostic settings and the traffic_analytics workspace_resource_id field"
  type        = string
}

variable "log_analytics_workspace_customer_id" {
  description = "Workspace GUID of the centralized Log Analytics workspace - distinct from the ARM resource ID, required specifically by the traffic_analytics workspace_id field"
  type        = string
}
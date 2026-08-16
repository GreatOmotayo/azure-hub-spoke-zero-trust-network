variable "platform_subscription_id" {
  type        = string
  description = "Subscription ID for the Platform subscription (hub firewall, bastion, log analytics)"
}

variable "production_subscription_id" {
  type        = string
  description = "Subscription ID for the Production spoke"
}

variable "non_production_subscription_id" {
  type        = string
  description = "Subscription ID for the Non Production spoke"
}

variable "location" {
  type        = string
  description = "Azure region for all resources in this project"
  default     = "centralus"
}

variable "project_tags" {
  type        = map(string)
  description = "Common tags applied to every resource in this project"
  default = {
    "project"     = "hub-spoke-zero-trust-network"
    "managed_by"  = "terraform"
    "environment" = "shared"
    "costCenter"  = "Tech"
  }
}

# ---- CIDR plan
variable "hub_vnet_cidr" {
  type        = string
  description = "Hub VNet address space (Platform subscription)"
  default     = "10.0.0.0/16"
}

variable "hub_firewall_subnet_cidr" {
  type    = string
  default = "10.0.0.0/26"
}

variable "hub_bastion_subnet_cidr" {
  type    = string
  default = "10.0.0.64/26"
}

variable "hub_shared_services_subnet_cidr" {
  type    = string
  default = "10.0.0.128/25"
}

variable "production_vnet_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "production_app_subnet_cidr" {
  type    = string
  default = "10.1.0.0/24"
}

variable "production_pe_subnet_cidr" {
  type        = string
  description = "Private endpoints subnet - key Vault, Storage"
  default     = "10.1.1.0/24"
}

variable "production_aks_subnet_cidr" {
  type        = string
  description = "Reserved for the future AKS project"
  default     = "10.1.16.0/22"
}

variable "non_production_vnet_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

variable "non_production_app_subnet_cidr" {
  type    = string
  default = "10.2.0.0/24"
}

variable "non_production_pe_subnet_cidr" {
  type    = string
  default = "10.2.1.0/24"
}

variable "non_production_aks_subnet_cidr" {
  description = "Reserved for the future AKS project"
  type        = string
  default     = "10.2.16.0/23"
}

variable "resource_group_name" {
  description = "Resource group ID"
  type        = string
  default     = "rg-hub-network"
}

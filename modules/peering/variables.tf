variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet"
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of the hub VNet - required because peering resources are named/scoped per VNet"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource group name of the hub VNet - the hub to spoke peering resource is created in this resource group"
  type        = string
}

variable "spoke_vnet_id" {
  description = "Resource ID of the spoke VNet being peered to the hub"
  type        = string
}
variable "spoke_vnet_name" {
  description = "Name of the spoke VNet"
  type        = string
}

variable "spoke_resource_group_name" {
  description = "Resource group name of the spoke VNet -  the spoke to hub peering resource is created in this resource group"
  type        = string
}

variable "environment" {
  description = "Environment name of the spoke being peered"
  type        = string
}
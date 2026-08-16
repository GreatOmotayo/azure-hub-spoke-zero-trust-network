output "vnet_id" {
  description = "Resource ID of this spoke's VNet - consumed by the peering module"
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "Name of this spoke's VNet"
  value       = azurerm_virtual_network.spoke.name
}

output "resource_group_name" {
  description = "Name of the spoke's resource group"
  value       = azurerm_resource_group.spoke.name
}

output "app_subnet_id" {
  description = "Resource ID of the app/workload subnet"
  value       = azurerm_subnet.subnet_app.id
}

output "private_endpoint_subnet_id" {
  description = "Resource ID of this spoke's route table"
  value       = azurerm_subnet.private_endpoints.id
}

output "aks_subnet_id" {
  description = "Resource ID of this aks subnet"
  value       = azurerm_subnet.aks.id
}

output "route_table_id" {
  description = "Resource ID of this spoke's route table"
  value       = azurerm_route_table.spoke.id
}
output "vnet_id" {
  description = "Resource ID of the hub VNet - consumed by the peering module"
  value       = azurerm_virtual_network.hub.id
}

output "vnet_name" {
  description = "Name of the hub VNet"
  value       = azurerm_virtual_network.hub.name
}

output "resource_group_name" {
  description = "Name of the hub resource group"
  value       = azurerm_resource_group.hub.name
}

output "firewall_private_ip_address" {
  description = "Private IP of the Azure Firewall - consumed by spoke route tables as the next hop for forced tunneling"
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "firewall_id" {
  description = "Resource ID of the Azure Firewall"
  value       = azurerm_firewall.hub.id
}

output "firewall_public_ip_address" {
  description = "Public IP address of the hub Azure Firewall - used for SNAT'd outbound traffic and as the address to allow-list on any external service this environment's workload call out to"
  value       = azurerm_public_ip.firewall.ip_address
}

output "firewall_policy_id" {
  description = "Resource ID of the Firewall Policy"
  value       = azurerm_firewall_policy.firewall_policy.id
}

output "bastion_id" {
  description = "Resource ID of the Bastion host"
  value       = azurerm_bastion_host.hub.id
}
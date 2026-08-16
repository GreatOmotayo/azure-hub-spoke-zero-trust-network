output "hub_to_spoke_peering_id" {
  description = "Resource ID of the hub->spoke peering connection"
  value       = azurerm_virtual_network_peering.hub_to_spoke.id
}

output "spoke_to_hub_peering_id" {
  description = "Resource ID of the spoke->hub peering connection"
  value       = azurerm_virtual_network_peering.spoke_to_hub.id
}
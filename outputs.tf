# --- Hub ---
output "firewall_public_ip" {
  description = "Public IP of the hub Azure Firewall - useful for reference/allow-listing outbound SNAT treaffic, not for inbound access"
  value       = module.hub.firewall_public_ip_address
}

output "firewall_private_ip_address" {
  description = "Private IP of the hub Azure Firewall - the next hop every spoke subnet routes through"
  value       = module.hub.firewall_private_ip_address
}

output "bastion_id" {
  description = "Resource ID of the hub Bastion host"
  value       = module.hub.bastion_id
}

output "hub_vnet_id" {
  description = "Resource ID of the hub Bastion host"
  value       = module.hub.vnet_id
}

# --- Spokes ---

output "production_vnet_id" {
  description = "Resource ID of the production spoke VNet"
  value       = module.spoke_production.vnet_id
}

output "production_aks_subnet_id" {
  description = "Resource ID of the production AKS node subnet - ready for the AKS project to deploy into"
  value       = module.spoke_production.aks_subnet_id
}

output "non_production_vnet_id" {
  description = "Resource ID of the production spoke VNet"
  value       = module.spoke_nonproduction.vnet_id
}

output "non_production_aks_subnet_id" {
  description = "Resource ID of the production AKS node subnet - ready for the AKS project to deploy into"
  value       = module.spoke_nonproduction.aks_subnet_id
}

# --- Peering (validation)

output "peering_hub_production_state" {
  description = "Peering state for hub<->production, both directions - for post-apply validation"
  value = {
    hub_to_spoke = module.peering_hub_production.hub_to_spoke_peering_id
    spoke_to_hub = module.peering_hub_production.spoke_to_hub_peering_id
  }
}

output "peering_hub_nonproduction_state" {
  description = "Peering state for hub<->production, both directions - for post-apply validation"
  value = {
    hub_to_spoke = module.peering_hub_non_production.hub_to_spoke_peering_id
    spoke_to_hub = module.peering_hub_non_production.spoke_to_hub_peering_id
  }
}

# --- Observability ---
output "log_analytics_workspace_id" {
  description = "Resource ID of the centralized log Analytics workspace"
  value       = module.log_analytics.workspace_id
}

output "log_analytics_workpace_name" {
  description = "Name of the centralized log abalytics workspace - for portal/KQL reference"
  value       = module.log_analytics.workspace_name
}

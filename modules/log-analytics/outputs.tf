output "workspace_id" {
  description = "Full resource ID of the Log Analytics workspace - consumed by hub and spoke modules for diagnostic settings and flow logs"
  value       = azurerm_log_analytics_workspace.shared.id
}

output "workspace_customer_id" {
  description = "Workspace GUID - distinct from the resource ID, some resources/queries expect this GUID rather than the full ARMresource ID"
  value       = azurerm_log_analytics_workspace.shared.workspace_id
}

output "workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.shared.name
}

output "resource_group_name" {
  description = "Name of Resource ID"
  value       = azurerm_resource_group.log_analytics.name
}
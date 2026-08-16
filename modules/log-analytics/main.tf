resource "azurerm_resource_group" "log_analytics" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
resource "azurerm_log_analytics_workspace" "shared" {
  name                       = "log-hub-shared"
  location                   = azurerm_resource_group.log_analytics.location
  resource_group_name        = azurerm_resource_group.log_analytics.name
  tags                       = var.tags
  sku                        = "PerGB2018"
  retention_in_days          = var.retention_in_days
  daily_quota_gb             = var.daily_quota_gb
  internet_ingestion_enabled = true
  internet_query_enabled     = true
}
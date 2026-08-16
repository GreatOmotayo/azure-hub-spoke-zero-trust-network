variable "location" {
  description = "Azure region for the log Analytics workspace"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the workspace - lives in the hub/platform resource group since it's a shared, cross-environment resource"
  type        = string
}

variable "tags" {
  description = "Tags applied to the workspace"
  type        = map(string)
}

variable "retention_in_days" {
  description = "Log retention period. 30 days is the free/low-cost tier ceiling before per-GB overage-style charges apply more noticeably"
  type        = number
  default     = 30

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "retention in days must be between 30 andd 730 (Azure Log Analytics)"
  }
}

variable "daily_quota_gb" {
  description = "Daily ingestion cap in GB - hard stop - hard stop to prevent a misconfigured diagnostic setting"
  type        = number
  default     = 1
}
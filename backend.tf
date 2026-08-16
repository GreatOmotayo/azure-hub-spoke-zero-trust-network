terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "omotayotfstate"
    container_name       = "tf-state"
    key                  = "hub-spoke-zero-trust-network.tfstate"
    use_oidc             = true
  }
}
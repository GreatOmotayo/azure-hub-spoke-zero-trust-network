terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.81"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
  resource_provider_registrations = "core"
  subscription_id                 = var.platform_subscription_id
}

provider "azurerm" {
  features {}
  alias           = "production"
  subscription_id = var.production_subscription_id
}

provider "azurerm" {
  features {}
  alias           = "non-production"
  subscription_id = var.non_production_subscription_id
}
provider "azuread" {}

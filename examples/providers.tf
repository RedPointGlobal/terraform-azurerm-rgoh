terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "3.20.0"
      configuration_aliases = [azurerm.hub, azurerm.shared-platform, azurerm.connectivity]
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.30.0"
    }
  }

  cloud {
    organization = "redpointglobal"

    workspaces {
      tags = ["azure", "fish", "prod", "network"]
    }
  }
}

provider "azurerm" {
  client_id       = local.client_id
  client_secret   = var.client_secret
  tenant_id       = local.tenant_id
  subscription_id = local.rgoh_spoke_subscription_id
  features {}
}

provider "azurerm" {
  alias           = "hub"
  client_id       = local.client_id
  client_secret   = var.client_secret
  tenant_id       = local.tenant_id
  subscription_id = local.rgoh_hub_subscription_id
  features {}
}

provider "azurerm" {
  alias           = "shared-platform"
  client_id       = local.client_id
  client_secret   = var.client_secret
  tenant_id       = local.tenant_id
  subscription_id = local.rgoh_shared_platform_subscription_id
  features {}
}

provider "azurerm" {
  alias           = "connectivity"
  client_id       = local.client_id
  client_secret   = var.client_secret
  tenant_id       = local.tenant_id
  subscription_id = local.rgoh_hub_subscription_id
  features {}
}

provider "azuread" {
  client_id     = local.client_id
  client_secret = var.client_secret
  tenant_id     = local.tenant_id
}
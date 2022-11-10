terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "3.20.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.30.0"
    }
  }


provider "azurerm" {
  client_id       = local.client_id
  client_secret   = var.client_secret
  tenant_id       = local.tenant_id
  subscription_id = local.rgoh_spoke_subscription_id
  features {}
}

provider "azuread" {
  client_id     = local.client_id
  client_secret = var.client_secret
  tenant_id     = local.tenant_id
}

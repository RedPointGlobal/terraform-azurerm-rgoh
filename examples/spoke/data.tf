// HUB DDoS PLAN
data "azurerm_network_ddos_protection_plan" "hub" {
  name                = local.rgoh_hub_ddos_protection_plan_name
  resource_group_name = local.rgoh_hub_resource_group_name
  provider            = azurerm.hub
}

output "ddos_protection_plan_id" {
  value = data.azurerm_network_ddos_protection_plan.hub.id
}

// HUB RESOURCE GROUP
data "azurerm_resource_group" "hub" {
  name     = local.rgoh_hub_resource_group_name
  provider = azurerm.hub
}

output "rgoh_hub_resource_group_name" {
  value = data.azurerm_resource_group.hub.name
}

// HUB VIRTUAL NETWORK
data "azurerm_virtual_network" "hub" {
  name                = local.rgoh_hub_virtual_network_name
  resource_group_name = local.rgoh_hub_resource_group_name
  provider            = azurerm.hub
}

output "rgoh_hub_virtual_network_id" {
  value = data.azurerm_virtual_network.hub.id
}

output "rgoh_hub_virtual_network_name" {
  value = data.azurerm_virtual_network.hub.name
}

// KEY VAULT

data "azurerm_key_vault" "kv_shared_platform" {
  name                = "kv-ado-shared"
  resource_group_name = "rg-packer-rpspeastus2"
  provider            = azurerm.shared-platform
}

output "kv_shared_platform_id" {
  value = data.azurerm_key_vault.kv_shared_platform.id
}

data "azurerm_key_vault_secret" "vm_admin_password" {
  name         = "fisher-vm-admin-password"
  key_vault_id = data.azurerm_key_vault.kv_shared_platform.id
  provider     = azurerm.shared-platform
}

output "vm_admin_password_secret_value" {
  value     = data.azurerm_key_vault_secret.vm_admin_password.value
  sensitive = true
}

data "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "fisher-sql-admin-password"
  key_vault_id = data.azurerm_key_vault.kv_shared_platform.id
  provider     = azurerm.shared-platform
}

output "sql_admin_password_secret_value" {
  value     = data.azurerm_key_vault_secret.sql_admin_password.value
  sensitive = true
}

// PRIVATE DNS ZONES
data "azurerm_private_dns_zone" "mssql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = local.rgoh_hub_resource_group_name
  provider            = azurerm.hub
}

output "mssql_private_dns_zone_name" {
  value = data.azurerm_private_dns_zone.mssql.name
}
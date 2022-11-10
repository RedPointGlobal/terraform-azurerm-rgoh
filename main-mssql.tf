// AZURE SQL SERVER
resource "azurerm_mssql_server" "mssql" {
  for_each                     = var.azure_sql_servers
  name                         = "mssql-${var.client}-${each.key}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = var.location
  version                      = each.value.version
  administrator_login          = each.value.administrator_login
  administrator_login_password = each.value.administrator_login_password
  minimum_tls_version          = each.value.minimum_tls_version
  connection_policy            = each.value.connection_policy

  identity {
    type = "SystemAssigned"
  }

  public_network_access_enabled = each.value.public_network_access_enabled

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = each.value.sql_admin_azuread_group
    tenant_id      = var.tenant_id
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [azuread_administrator]
  }
}

// AZURE ELASTIC POOL
resource "azurerm_mssql_elasticpool" "rpiops" {
  for_each            = var.azure_sql_servers
  name                = each.value.elastic_pool_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  server_name         = azurerm_mssql_server.mssql[each.key].name
  license_type        = "LicenseIncluded"
  max_size_gb         = each.value.elastic_pool_max_size_gb

  sku {
    name     = each.value.elastic_pool_sku
    tier     = each.value.elastic_pool_tier
    family   = each.value.elastic_pool_family
    capacity = each.value.elastic_pool_capacity
  }

  per_database_settings {
    min_capacity = each.value.elastic_pool_min_capacity
    max_capacity = each.value.elastic_pool_max_capacity
  }

  depends_on = [azurerm_mssql_server.mssql]
}

// AZURE SQL DATABASE
data "azurerm_mssql_server" "mssql" {
  name                = "mssql-${var.client}-primary"
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [azurerm_mssql_server.mssql]
}

output "mssql_server_id" {
  value = data.azurerm_mssql_server.mssql.id
}

resource "azurerm_mssql_database" "mssql_db" {
  for_each             = var.azure_sql_databases
  name                 = "cdp-${var.client}-dw"
  server_id            = data.azurerm_mssql_server.mssql.id
  collation            = each.value.collation
  license_type         = each.value.license_type
  read_scale           = each.value.read_scale
  sku_name             = each.value.sku_name
  zone_redundant       = each.value.zone_redundant
  geo_backup_enabled   = each.value.geo_backup_enabled
  storage_account_type = each.value.storage_account_type

  threat_detection_policy {
    email_account_admins       = each.value.email_account_admins
    email_addresses            = each.value.email_addresses
    retention_days             = each.value.log_retention_days
    storage_endpoint           = azurerm_storage_account.st.primary_blob_endpoint
    storage_account_access_key = azurerm_storage_account.st.primary_access_key
    state                      = each.value.threat_detection_policy_state
  }

  tags = var.tags

  depends_on = [azurerm_storage_account.st, azurerm_mssql_server.mssql]

  lifecycle { ignore_changes = [threat_detection_policy,
  license_type, geo_backup_enabled, server_id, read_scale] }
}
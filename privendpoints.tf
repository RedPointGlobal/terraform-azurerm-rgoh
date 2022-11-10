// PRIVATE ENDPOINTS
resource "azurerm_private_endpoint" "mssql" {
  for_each            = var.azure_sql_servers
  name                = "pe-${var.client}-${each.key}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.shared.id

  private_service_connection {
    name                           = "peconn-${var.client}-${each.key}"
    is_manual_connection           = "false"
    private_connection_resource_id = azurerm_mssql_server.mssql[each.key].id
    subresource_names              = ["sqlServer"]
  }
  depends_on = [azurerm_mssql_server.mssql]

  lifecycle {
    ignore_changes = [subnet_id,private_dns_zone_group, private_service_connection]
  }
}


// NSG FLOW LOGS
resource "azurerm_network_watcher_flow_log" "nsg" {
  for_each             = var.virtual_network_subnets
  network_watcher_name = azurerm_network_watcher.netw.name
  resource_group_name  = azurerm_resource_group.rg.name
  name                 = "snet-${var.client}-${each.key}"
  version              = 2

  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
  storage_account_id        = azurerm_storage_account.st.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.loga.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.loga.location
    workspace_resource_id = azurerm_log_analytics_workspace.loga.id
    interval_in_minutes   = 10
  }

  tags = var.tags
  depends_on = [azurerm_storage_account.st, azurerm_network_watcher.netw,
  azurerm_network_security_group.nsg, azurerm_log_analytics_workspace.loga]
  lifecycle { ignore_changes = [location] }
}

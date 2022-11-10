resource "azurerm_security_center_workspace" "defender" {
  scope        = var.defender_for_cloud_scope
  workspace_id = azurerm_log_analytics_workspace.loga.id

  depends_on = [azurerm_log_analytics_workspace.loga]
}

resource "azurerm_security_center_subscription_pricing" "defender" {
  count         = length(var.defender_for_cloud_resource_types)
  tier          = "Standard"
  resource_type = element(var.defender_for_cloud_resource_types, count.index)

}


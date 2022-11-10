resource "azurerm_servicebus_namespace" "namespace" {
  count               = var.create_service_bus ? 1 : 0
  name                = "sbus-${var.client}-primary"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  tags = var.tags
}

// PRIVATE ENDPOINTS
resource "azurerm_private_endpoint" "sbus" {
  count               = var.create_service_bus ? 1 : 0
  name                = "sbus-${var.client}-primary"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.shared.id

  private_service_connection {
    name                           = "sbus-${var.client}-primary"
    is_manual_connection           = "false"
    private_connection_resource_id = azurerm_servicebus_namespace.namespace[count.index].id
    subresource_names              = ["namespace"]
  }
  depends_on = [azurerm_servicebus_namespace.namespace]

  lifecycle {
    ignore_changes = [private_service_connection]
  }
}

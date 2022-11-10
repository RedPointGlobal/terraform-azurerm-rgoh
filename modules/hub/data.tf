data "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name

  depends_on = [azurerm_virtual_network.vnet, azurerm_subnet.subnet]
}

output "firewall_subnet_id" {
  value = data.azurerm_subnet.firewall.id
}

data "azurerm_subnet" "vpn" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name

  depends_on = [azurerm_virtual_network.vnet, azurerm_subnet.subnet]
}

output "vpn_gateway_subnet_id" {
  value = data.azurerm_subnet.vpn.id
}
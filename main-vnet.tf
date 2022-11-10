// NETWORK WATCHER
resource "azurerm_network_watcher" "netw" {
  name                = "NetworkWatcher_${var.client_prefix}_${var.location}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

// VIRTUAL NETWORK
resource "azurerm_network_security_group" "nsg" {
  for_each            = var.virtual_network_subnets
  name                = "snet-${var.client}-${each.key}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.virtual_network_address_space
  dns_servers         = var.virtual_network_dns_servers

  ddos_protection_plan {
    enable = true
    id     = var.rgoh_hub_ddos_protection_plan_id
  }

  tags = var.tags

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_subnet" "subnet" {
  for_each                                      = var.virtual_network_subnets
  name                                          = "snet-${var.client}-${each.key}"
  resource_group_name                           = azurerm_resource_group.rg.name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  address_prefixes                              = each.value.address_prefixes
  private_endpoint_network_policies_enabled     = each.value.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.Sql",
    "Microsoft.ContainerRegistry",
    "Microsoft.AzureCosmosDB",
    "Microsoft.KeyVault",
    "Microsoft.ServiceBus",
    "Microsoft.EventHub",
    "Microsoft.AzureActiveDirectory",
  "Microsoft.Web"]
}

resource "azurerm_route_table" "rtb" {
  for_each                      = var.virtual_network_subnets
  name                          = "snet-${var.client}-${each.key}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg" {
  for_each                  = var.virtual_network_subnets
  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

resource "azurerm_subnet_route_table_association" "rtb" {
  for_each       = var.virtual_network_subnets
  subnet_id      = azurerm_subnet.subnet[each.key].id
  route_table_id = azurerm_route_table.rtb[each.key].id
}

// ROUTE
resource "azurerm_route" "route" {
  for_each               = var.virtual_network_subnets
  name                   = "default"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.rtb[each.key].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.default_route_internet
}

// VNET PEERING
resource "azurerm_virtual_network_peering" "fish" {
  name                         = "peer-fish-to-hub"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = var.rgoh_hub_virtual_network_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  use_remote_gateways          = true

  depends_on = [azurerm_virtual_network.vnet]
}

//DIAGNOSTIC SETTING
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name               = "diag-${var.virtual_network_name}"
  target_resource_id = azurerm_virtual_network.vnet.id
  storage_account_id = azurerm_storage_account.st.id

  log {
    category = "VMProtectionAlerts"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }

  depends_on = [azurerm_virtual_network.vnet]
}

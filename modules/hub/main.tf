locals {
  if_ddos_enabled = var.create_ddos_protection_plan ? [{}] : []
}

// RESOURCE GROUP
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

// LOGGING STORAGE ACCOUNT
resource "azurerm_storage_account" "logs" {
  name                     = "sthubdiagnosticlogs"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

// LOG ANALYTICS WORKSPACE
resource "azurerm_log_analytics_workspace" "loga" {
  name                = "loga-hub-primary"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"

  tags = var.tags
}

// FIREWALL
resource "azurerm_firewall_policy" "afw" {
  count                    = var.create_firewall ? 1 : 0
  name                     = "afw-hub-${var.location}"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.rg.name
  sku                      = "Premium"
  threat_intelligence_mode = "Deny"
  tags                     = var.tags

  intrusion_detection {
    mode = "Deny"
  }
}

resource "azurerm_public_ip" "afw" {
  count               = var.create_firewall ? 1 : 0
  name                = "afw-hub-${var.location}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_firewall" "afw" {
  count               = var.create_firewall ? 1 : 0
  name                = "afw-hub-${var.location}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_tier            = "Premium"
  sku_name            = "AZFW_VNet"
  firewall_policy_id  = azurerm_firewall_policy.afw[count.index].id
  tags                = var.tags
  zones               = ["1", "2", "3"]
  ip_configuration {
    name                 = "afw-hub-${var.location}"
    subnet_id            = data.azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.afw[count.index].id
  }
}

// VIRTUAL NETWORK

resource "azurerm_network_ddos_protection_plan" "ddos" {
  count               = var.create_ddos_protection_plan ? 1 : 0
  name                = "ddos-pplan-${var.location}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.virtual_network_address_space
  dns_servers         = var.virtual_network_dns_servers

  dynamic "ddos_protection_plan" {
    for_each = local.if_ddos_enabled

    content {
      id     = azurerm_network_ddos_protection_plan.ddos[0].id
      enable = true
    }
  }

  tags = var.tags

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_subnet" "subnet" {
  for_each                                      = var.virtual_network_subnets
  name                                          = each.value.name
  resource_group_name                           = azurerm_resource_group.rg.name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  address_prefixes                              = each.value.address_prefixes
  private_endpoint_network_policies_enabled     = each.value.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
}

//DIAGNOSTIC SETTING
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name               = "diag-${var.virtual_network_name}"
  target_resource_id = azurerm_virtual_network.vnet.id
  storage_account_id = azurerm_storage_account.logs.id

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

  depends_on = [azurerm_virtual_network.vnet, azurerm_storage_account.logs]
}

// VPN GATEWAY

resource "azurerm_public_ip" "afw_pip1" {
  count               = var.create_virtual_network_gateway ? 1 : 0
  name                = "vgw-hub-${var.location}-pip1"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_public_ip" "afw_pip2" {
  count               = var.create_virtual_network_gateway ? 1 : 0
  name                = "vgw-hub-${var.location}-pip2"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "hub" {
  count               = var.create_virtual_network_gateway ? 1 : 0
  name                = "vgw-hub-${var.location}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = false
  sku           = "VpnGw1AZ"

  ip_configuration {
    name                 = "vgw-hub-${var.location}-pip1"
    public_ip_address_id = azurerm_public_ip.afw_pip1[count.index].id
    subnet_id            = data.azurerm_subnet.vpn.id
  }
  ip_configuration {
    name                 = "vgw-hub-${var.location}-pip2"
    public_ip_address_id = azurerm_public_ip.afw_pip2[count.index].id
    subnet_id            = data.azurerm_subnet.vpn.id
  }
}

// LOCAL NETWORK GATEWAY
data "azurerm_virtual_network_gateway" "hub" {
  name                = "vgw-hub-${var.location}"
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [azurerm_virtual_network_gateway.hub]
}

output "gateway_id" {
  value = data.azurerm_virtual_network_gateway.hub.id
}

resource "azurerm_local_network_gateway" "vpn" {
  count               = var.create_local_network_gateway ? 1 : 0
  name                = "lngw-hub-${var.location}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  gateway_address     = var.local_vpn_gateway_address
  address_space       = var.prisma_access_vpn_addresses
}

resource "azurerm_virtual_network_gateway_connection" "vpn" {
  count                      = var.create_local_network_gateway ? 1 : 0
  name                       = "vpnconn-${var.location}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  type                       = "IPsec"
  tags                       = var.tags
  virtual_network_gateway_id = data.azurerm_virtual_network_gateway.hub.id
  local_network_gateway_id   = azurerm_local_network_gateway.vpn[count.index].id
  shared_key                 = var.vpn_connection_shared_key

  depends_on = [
    azurerm_local_network_gateway.vpn, azurerm_virtual_network_gateway.hub
  ]

}

// DEFENDER FOR CLOUD
resource "azurerm_security_center_workspace" "defender" {
  scope        = "/subscriptions/${var.subscription_id}"
  workspace_id = azurerm_log_analytics_workspace.loga.id

  depends_on = [azurerm_log_analytics_workspace.loga]
}

resource "azurerm_security_center_subscription_pricing" "defender" {
  count         = length(var.defender_for_cloud_resource_types)
  tier          = "Standard"
  resource_type = element(var.defender_for_cloud_resource_types, count.index)

}

// NAT GATEWAY
resource "azurerm_public_ip_prefix" "nat" {
  count               = var.create_nat_gateway ? 1 : 0
  name                = "natgw-hub-${var.location}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  prefix_length       = 28
  zones               = ["1"]
}

resource "azurerm_nat_gateway" "nat" {
  count               = var.create_nat_gateway ? 1 : 0
  name                = "natgw-hub-${var.location}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
  zones               = ["1"]

}

resource "azurerm_nat_gateway_public_ip_prefix_association" "nat" {
  count               = var.create_nat_gateway ? 1 : 0
  nat_gateway_id      = azurerm_nat_gateway.nat[count.index].id
  public_ip_prefix_id = azurerm_public_ip_prefix.nat[count.index].id
}

resource "azurerm_subnet_nat_gateway_association" "firewall" {
  count          = var.create_nat_gateway ? 1 : 0
  subnet_id      = data.azurerm_subnet.firewall.id
  nat_gateway_id = azurerm_nat_gateway.nat[count.index].id
}

/*
resource "azurerm_virtual_network_peering" "hub" {
  for_each                  = var.virtual_network_peering
  name                      = "peer-${each.value.spoke_vnet_name}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = each.value.spoke_virtual_network_id
}

resource "azurerm_virtual_network_peering" "spoke" {
  for_each                  = var.virtual_network_peering
  name                      = "peer-${var.virtual_network_name}"
  resource_group_name       = each.value.spoke_vnet_resource_group
  virtual_network_name      = each.value.spoke_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
}
*/

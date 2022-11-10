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

  ddos_protection_plan {
    enable = true
    id     = azurerm_network_ddos_protection_plan.ddos.id
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

// DEFENDER FOR CLOUD
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

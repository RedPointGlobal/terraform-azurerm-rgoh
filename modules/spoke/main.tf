// NETWORK WATCHER
resource "azurerm_network_watcher" "netw" {
  name                = "NetworkWatcher_${var.client_prefix}_${var.location}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

// RESOURCE GROUP
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

// SHARED IMAGE GALLERY
resource "azurerm_shared_image_gallery" "avd" {
  name                = "cig${var.client}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  description         = "Shared vitual machine images"

  tags = var.tags
}

//
data "azurerm_shared_image" "avd" {
  name                = "win11-22h2-ent"
  gallery_name        = "cig${var.client}"
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [azurerm_shared_image_gallery.avd]
}

output "shared_image_id" {
  value = data.azurerm_shared_image.avd.id
}

// LOGGING STORAGE ACCOUNT
resource "azurerm_storage_account" "st" {
  name                     = "stfishcorelogging"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

// LOG ANALYTICS WORKSPACE
resource "azurerm_log_analytics_workspace" "loga" {
  name                = "loga-fish-primary"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"

  tags = var.tags
}

// AKS CLUSTER
resource "azurerm_user_assigned_identity" "aks" {
  count               = var.create_aks_cluster ? 1 : 0
  location            = var.location
  name                = "mi-${var.client}-aks"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "aks" {
  count                = var.create_aks_cluster ? 1 : 0
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks[count.index].principal_id

  depends_on = [azurerm_virtual_network.vnet]
}

data "azurerm_kubernetes_service_versions" "aks" {
  location = var.location
}

output "latest_version" {
  value = data.azurerm_kubernetes_service_versions.aks.latest_version
}

data "azurerm_subnet" "aks" {
  name                 = "snet-${var.client}-aks"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name

  depends_on = [azurerm_virtual_network.vnet, azurerm_subnet.subnet]
}

output "aks_subnet_id" {
  value = data.azurerm_subnet.aks.id
}

resource "azurerm_kubernetes_cluster" "aks" {
  count                               = var.create_aks_cluster ? 1 : 0
  name                                = "aks-${var.client}-primary"
  location                            = var.location
  sku_tier                            = "Paid"
  resource_group_name                 = var.resource_group_name
  dns_prefix                          = "aks${var.client}primary"
  automatic_channel_upgrade           = "stable"
  azure_policy_enabled                = true
  kubernetes_version                  = data.azurerm_kubernetes_service_versions.aks.latest_version
  node_resource_group                 = "rg-${var.client}-aks"
  public_network_access_enabled       = false
  oidc_issuer_enabled                 = true
  open_service_mesh_enabled           = true
  private_cluster_enabled             = true
  private_dns_zone_id                 = var.aks_private_dns_zone_id
  private_cluster_public_fqdn_enabled = true
  role_based_access_control_enabled   = true

  key_vault_secrets_provider {
    secret_rotation_enabled = false
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    tenant_id              = var.tenant_id
    azure_rbac_enabled     = true
    admin_group_object_ids = var.aks_admin_group_object_id
  }

  default_node_pool {
    name                         = "system"
    zones                        = var.aks_availability_zones
    type                         = "VirtualMachineScaleSets"
    os_disk_size_gb              = 128
    os_disk_type                 = "Managed"
    orchestrator_version         = data.azurerm_kubernetes_service_versions.aks.latest_version
    vm_size                      = var.aks_virtual_machine_size
    vnet_subnet_id               = data.azurerm_subnet.aks.id
    enable_auto_scaling          = true
    min_count                    = 1
    max_count                    = 5
    node_count                   = 3
    enable_host_encryption       = false
    enable_node_public_ip        = false
    max_pods                     = 60
    only_critical_addons_enabled = false

    upgrade_settings {
      max_surge = "10%"
    }
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    outbound_type  = "userDefinedRouting"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks[count.index].id]
  }

  tags = var.tags

  depends_on = [azurerm_user_assigned_identity.aks, azurerm_role_assignment.aks]
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

// AVD
resource "azurerm_virtual_desktop_workspace" "avd" {
  for_each            = var.azure_virtual_desktop
  name                = each.value.workspace_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  friendly_name = each.value.friendly_name

  tags = var.tags
}

resource "azurerm_storage_account" "avd" {
  name                     = "st${var.client}avdprofiles"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

resource "azurerm_virtual_desktop_host_pool" "avd" {
  for_each            = var.azure_virtual_desktop
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  name                             = each.value.host_pool_name
  friendly_name                    = each.value.host_pool_name
  validate_environment             = each.value.validate_environment
  start_vm_on_connect              = each.value.start_vm_on_connect
  custom_rdp_properties            = each.value.custom_rdp_properties
  type                             = each.value.host_pool_type
  maximum_sessions_allowed         = each.value.maximum_sessions_allowed
  load_balancer_type               = each.value.load_balancer_type
  personal_desktop_assignment_type = each.value.personal_desktop_assignment_type

  tags = var.tags

  lifecycle {
    ignore_changes = [maximum_sessions_allowed]
  }
}

resource "azurerm_virtual_desktop_application_group" "avd" {
  for_each            = var.azure_virtual_desktop
  name                = each.value.application_group_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  type          = each.value.application_group_type
  host_pool_id  = azurerm_virtual_desktop_host_pool.avd[each.key].id
  friendly_name = each.value.application_group_name

  tags = var.tags
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "avd" {
  for_each             = azurerm_virtual_desktop_workspace.avd
  workspace_id         = azurerm_virtual_desktop_workspace.avd[each.key].id
  application_group_id = azurerm_virtual_desktop_application_group.avd[each.key].id
}


resource "azurerm_user_assigned_identity" "avd" {
  location            = var.location
  name                = "avd-${var.client}-mi"
  resource_group_name = azurerm_resource_group.rg.name
}

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
    ignore_changes = [subnet_id, private_dns_zone_group, private_service_connection]
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

// SERVICE BUS
resource "azurerm_servicebus_namespace" "namespace" {
  count               = var.create_service_bus ? 1 : 0
  name                = "sbus-${var.client}-primary"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  tags = var.tags
}

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

// VIRTUAL MACHINES
data "azurerm_subnet" "shared" {
  name                 = "snet-${var.client}-shared"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name

  depends_on = [azurerm_virtual_network.vnet, azurerm_subnet.subnet]
}

output "shared_subnet_id" {
  value = data.azurerm_subnet.shared.id
}

resource "azurerm_network_interface" "nic" {
  for_each            = var.rpdm_linux_virtual_machines
  name                = "nic-${var.client}-${each.key}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipcfg-${var.client}-${each.key}"
    subnet_id                     = data.azurerm_subnet.shared.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "rpdm_linux" {
  for_each                        = var.rpdm_linux_virtual_machines
  name                            = "vm-${var.client}-${each.key}"
  computer_name                   = each.value.computer_name
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = var.location
  size                            = each.value.size
  admin_username                  = each.value.admin_username
  admin_password                  = each.value.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nic[each.key].id, ]

  source_image_reference {
    publisher = each.value.image_publisher
    offer     = each.value.image_offer
    sku       = each.value.sku
    version   = each.value.version
  }

  os_disk {
    storage_account_type = each.value.storage_account_type
    caching              = each.value.disk_caching
    disk_size_gb         = each.value.os_disk_size
  }

  tags = var.tags
}

resource "azurerm_managed_disk" "rpdm_tempdata" {
  for_each             = var.rpdm_linux_virtual_machines
  name                 = "tempdata-${var.client}-${each.key}"
  location             = var.location
  create_option        = "Empty"
  disk_size_gb         = each.value.tempdata_disk_size
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = each.value.storage_account_type

  depends_on = [azurerm_linux_virtual_machine.rpdm_linux]
}

resource "azurerm_virtual_machine_data_disk_attachment" "rpdm_tempdata" {
  for_each           = var.rpdm_linux_virtual_machines
  virtual_machine_id = azurerm_linux_virtual_machine.rpdm_linux[each.key].id
  managed_disk_id    = azurerm_managed_disk.rpdm_tempdata[each.key].id
  lun                = each.value.tempdata_disk_lun
  caching            = each.value.disk_caching
}

resource "azurerm_managed_disk" "rpdm_appdata" {
  for_each             = var.rpdm_linux_virtual_machines
  name                 = "appdata-${var.client}-${each.key}"
  location             = var.location
  create_option        = "Empty"
  disk_size_gb         = each.value.appdata_disk_size
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = each.value.storage_account_type

  depends_on = [azurerm_linux_virtual_machine.rpdm_linux]
}

resource "azurerm_virtual_machine_data_disk_attachment" "rpdm_appdata" {
  for_each           = var.rpdm_linux_virtual_machines
  virtual_machine_id = azurerm_linux_virtual_machine.rpdm_linux[each.key].id
  managed_disk_id    = azurerm_managed_disk.rpdm_appdata[each.key].id
  lun                = each.value.appdata_disk_lun
  caching            = each.value.disk_caching
}

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
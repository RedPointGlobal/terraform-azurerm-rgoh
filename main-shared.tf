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
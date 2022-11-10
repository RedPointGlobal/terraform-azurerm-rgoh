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



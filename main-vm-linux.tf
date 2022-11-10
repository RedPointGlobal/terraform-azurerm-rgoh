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
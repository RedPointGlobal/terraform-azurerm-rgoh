locals {

  //HUB
  rgoh_hub_ddos_protection_plan_name = "ddos-pplan-eastus2"
  rgoh_hub_resource_group_name       = "RGOH-hubeastus2"
  rgoh_hub_subscription_id           = "" 
  rgoh_hub_virtual_network_name      = "vnet-hub-eastus2"

  // SPOKE
  rgoh_spoke_client_name               = "rgoh-client-1"
  rgoh_spoke_client_prefix             = "rgohc1"
  rgoh_spoke_region                    = "eastus2"
  rgoh_spoke_resource_group_name       = "RGOH-client-1"
  rgoh_spoke_subscription_id           = ""
  rgoh_shared_platform_subscription_id = ""
  client_id                            = ""
  tenant_id                            = ""
}

module "spoke" {
  source                       = "../../../modules/rgoh-spoke/"
  client                       = local.rgoh_spoke_client_name
  client_prefix                = local.rgoh_spoke_client_prefix
  tenant_id                    = local.tenant_id
  resource_group_name          = local.rgoh_spoke_resource_group_name
  location                     = local.rgoh_spoke_region
  rgoh_hub_resource_group_name = data.azurerm_resource_group.hub.name
  defender_for_cloud_scope     = "/subscriptions/${local.rgoh_spoke_subscription_id}"

  // SPOKE ADDONS
  create_service_bus        = false
  create_aks_cluster        = false
  aks_private_dns_zone_id   = "" # Required if create AKS cluster is true.
  aks_admin_group_object_id = ["1e0f3617-25dd-4db0-a1b7-c22839bb4dcf"]
  aks_availability_zones    = ["1", "2"]
  aks_virtual_machine_size  = "Standard_D4ads_v5"

  // VIRTUAL NETWORK
  virtual_network_address_space    = ["10.160.8.0/23"]
  virtual_network_name             = "vnet-exple-primary"
  virtual_network_dns_servers      = ["10.153.12.68"]
  firewall_subnet_address_prefix   = ["10.160.8.0/28"]
  default_route_internet           = "10.153.12.68" # Internal IP of Hub firewall
  rgoh_hub_virtual_network_name    = data.azurerm_virtual_network.hub.name
  rgoh_hub_virtual_network_id      = data.azurerm_virtual_network.hub.id
  rgoh_hub_ddos_protection_plan_id = data.azurerm_network_ddos_protection_plan.hub.id
  tags = {
    provisioner = "terraform"
    client      = "${local.rgoh_spoke_client_name}"
  }

  virtual_network_subnets = {

    "aks" = {
      address_prefixes                              = ["10.160.9.0/24"]
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
    }

    "shared" = {
      address_prefixes                              = ["10.160.8.0/25"]
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
    }
  }

  // VIRTUAL MACHINES
  rpdm_linux_virtual_machines = {

    "rpdment" = {
      computer_name        = "exple-rpdment.redpointcloud.com"
      admin_username       = "redpointops"
      admin_password       = data.azurerm_key_vault_secret.vm_admin_password.value
      size                 = "Standard_D4s_v5"
      image_publisher      = "Canonical"
      sku                  = "18.04-LTS"
      image_offer          = "UbuntuServer"
      version              = "latest"
      storage_account_type = "Premium_LRS"
      disk_caching         = "ReadWrite"
      os_disk_size         = 128
      tempdata_disk_size   = 256
      tempdata_disk_lun    = 0
      appdata_disk_size    = 256
      appdata_disk_lun     = 1
      tags = {
        provisioner = "terraform"
        client      = "${local.rgoh_spoke_client_name}"
        type        = "linux_vm"
        backup      = "daily"
      }

    }
  }

  // AZURE SQL SERVERS
  azure_sql_servers = {

    "primary" = {
      version                       = "12.0"
      administrator_login           = "redpointops"
      administrator_login_password  = data.azurerm_key_vault_secret.sql_admin_password.value
      minimum_tls_version           = "1.2"
      connection_policy             = "Default"
      public_network_access_enabled = false
      sql_admin_azuread_group       = "920e96fa-8b31-4222-b8e2-64de619c7964"
      elastic_pool_name             = "epool-${local.rgoh_spoke_client_prefix}-rpiops"
      elastic_pool_sku              = "GP_Gen5"
      elastic_pool_tier             = "GeneralPurpose"
      elastic_pool_family           = "Gen5"
      elastic_pool_capacity         = "4"
      elastic_pool_max_size_gb      = 200
      elastic_pool_min_capacity     = 0.25
      elastic_pool_max_capacity     = 4
      tags = {
        provisioner = "terraform"
        client      = "${local.rgoh_spoke_client_name}"
        type        = "mssql"
        role        = "RPI operational database"
      }
    }
  }

// AZURE SQL DATABASES
  azure_sql_databases = {

    "cdp-example-dw" = {
      collation                     = "SQL_Latin1_General_CP1_CI_AS"
      license_type                  = "LicenseIncluded"
      read_scale                    = true
      sku_name                      = "HS_Gen5_8"
      zone_redundant                = false
      geo_backup_enabled            = true
      storage_account_type          = "Zone"
      email_account_admins          = "Enabled"
      email_addresses               = ["secure@redpointglobal.com", "rp-dba@redpointglobal.com"]
      log_retention_days            = 90
      threat_detection_policy_state = "Enabled"
      tags = {
        provisioner = "terraform"
        client      = "${local.rgoh_spoke_client_name}"
        type        = "database"
        role        = "data warehouse"
      }
    }
  }

// AZURE VIRTUAL DESKTOPS
  azure_virtual_desktop = {

    "personal" = {
      application_group_name           = "avd-${local.rgoh_spoke_client_prefix}-personal"
      application_group_type           = "Desktop"
      custom_rdp_properties            = "audiocapturemode:i:1;audiomode:i:0;"
      friendly_name                    = "avd-${local.rgoh_spoke_client_prefix}-personal"
      host_pool_name                   = "avd-${local.rgoh_spoke_client_prefix}-personal"
      host_pool_type                   = "Personal"
      load_balancer_type               = "Persistent"
      maximum_sessions_allowed         = 10
      start_vm_on_connect              = false
      validate_environment             = false
      workspace_name                   = "avd-${local.rgoh_spoke_client_prefix}-personal"
      personal_desktop_assignment_type = "Automatic"
      tags = {
        provisioner = "terraform"
        client      = "${local.rgoh_spoke_client_name}"
        type        = "virtual desktops"
      }
    }
  }
}

// VNET PEERING HUB TO SPOKE
resource "azurerm_virtual_network_peering" "hub" {
  name                         = "peer-hub-to-${local.rgoh_spoke_client_name}"
  resource_group_name          = data.azurerm_resource_group.hub.name
  virtual_network_name         = data.azurerm_virtual_network.hub.name
  remote_virtual_network_id    = module.spoke.virtual_network_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = true
  provider                     = azurerm.hub
  depends_on                   = [module.spoke]
}


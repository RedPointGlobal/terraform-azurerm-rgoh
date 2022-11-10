variable "location" {}
variable "client_prefix" {}
variable "virtual_network_name" {}
variable "resource_group_name" {}
variable "client" {}
variable "tenant_id" {}
variable "default_route_internet" {}
variable "defender_for_cloud_scope" {}

variable "create_aks_cluster" { type = bool }
variable "aks_private_dns_zone_id" { type = string }
variable "aks_admin_group_object_id" { type = list(string) }
variable "aks_availability_zones" { type = list(string) }
variable "aks_virtual_machine_size" { type = string }

variable "virtual_network_address_space" {
  type = list(string)
}

variable "defender_for_cloud_resource_types" {
  type = list(string)
  default = ["AppServices", "ContainerRegistry", "KeyVaults",
    "KubernetesService", "SqlServers", "SqlServerVirtualMachines", "StorageAccounts", "VirtualMachines",
  "Arm", "OpenSourceRelationalDatabases", "Containers", "Dns"]
}

variable "rgoh_hub_virtual_network_id" {}
variable "rgoh_hub_resource_group_name" {}
variable "rgoh_hub_virtual_network_name" {}
#variable "network_watcher_name" {}

variable "create_service_bus" {
  type = bool
}

#variable "mssql_private_privatelink_dns_zone_name" {}
#variable "mssql_private_privatelink_resource_group_name" {}

variable "firewall_subnet_address_prefix" {
  type = list(string)
}

variable "virtual_network_dns_servers" {
  type = list(string)
}

variable "rgoh_hub_ddos_protection_plan_id" {}

variable "tags" {
  type = map(string)
}

variable "virtual_network_subnets" {
  type = map(object({
    address_prefixes                              = list(string)
    private_endpoint_network_policies_enabled     = bool
    private_link_service_network_policies_enabled = bool

  }))
}

variable "rpdm_linux_virtual_machines" {
  type = map(object({
    computer_name        = string
    admin_username       = string
    admin_password       = string
    size                 = string
    image_publisher      = string
    image_offer          = string
    sku                  = string
    version              = string
    storage_account_type = string
    disk_caching         = string
    os_disk_size         = number
    tempdata_disk_size   = number
    tempdata_disk_lun    = string
    appdata_disk_size    = number
    appdata_disk_lun     = string
    tags                 = map(string)

  }))
}

variable "azure_sql_servers" {
  type = map(object({
    version                       = string
    administrator_login           = string
    administrator_login_password  = string
    minimum_tls_version           = string
    connection_policy             = string
    public_network_access_enabled = bool
    sql_admin_azuread_group       = string
    elastic_pool_name             = string
    elastic_pool_sku              = string
    elastic_pool_tier             = string
    elastic_pool_family           = string
    elastic_pool_capacity         = string
    elastic_pool_max_size_gb      = number
    elastic_pool_min_capacity     = number
    elastic_pool_max_capacity     = number
    tags                          = map(string)

  }))
}

variable "azure_sql_databases" {
  type = map(object({
    collation                     = string
    license_type                  = string
    read_scale                    = bool
    sku_name                      = string
    zone_redundant                = bool
    geo_backup_enabled            = bool
    storage_account_type          = string
    email_account_admins          = string
    email_addresses               = list(string)
    log_retention_days            = number
    threat_detection_policy_state = string
    tags                          = map(string)
  }))
}

variable "azure_virtual_desktop" {
  type = map(object({
    workspace_name                   = string
    friendly_name                    = string
    host_pool_name                   = string
    validate_environment             = bool
    start_vm_on_connect              = bool
    custom_rdp_properties            = string
    host_pool_type                   = string
    maximum_sessions_allowed         = number
    load_balancer_type               = string
    application_group_name           = string
    application_group_type           = string
    personal_desktop_assignment_type = string
    tags                             = map(string)
  }))
}
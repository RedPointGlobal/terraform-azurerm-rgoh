variable "location" {}
variable "virtual_network_name" {}
variable "resource_group_name" {}
variable "create_firewall" { type = bool }
variable "create_virtual_network_gateway" { type = bool }
variable "create_local_network_gateway" { type = bool }
variable "subscription_id" {}
variable "prisma_access_vpn_addresses" { type = list(string) }
variable "create_ddos_protection_plan" { type = bool }
variable "vpn_connection_shared_key" { type = string }
variable "local_vpn_gateway_address" { type = string }
variable "create_nat_gateway" { type = bool }

/*
variable "virtual_network_peering" {
  type = map(object({
    spoke_vnet_name           = string
    spoke_virtual_network_id  = string
    spoke_vnet_resource_group = string
  }))
}
*/

variable "virtual_network_address_space" {
  type = list(string)
}

variable "defender_for_cloud_resource_types" {
  type = list(string)

  default = ["AppServices", "ContainerRegistry", "KeyVaults",
    "KubernetesService", "SqlServers", "SqlServerVirtualMachines", "StorageAccounts", "VirtualMachines",
  "Arm", "OpenSourceRelationalDatabases", "Containers", "Dns"]
}

variable "virtual_network_dns_servers" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

variable "virtual_network_subnets" {
  type = map(object({
    name                                          = string
    address_prefixes                              = list(string)
    private_endpoint_network_policies_enabled     = bool
    private_link_service_network_policies_enabled = bool

  }))
}


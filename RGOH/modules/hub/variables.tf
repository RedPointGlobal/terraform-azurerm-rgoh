variable "location" {}
variable "virtual_network_name" {}
variable "resource_group_name" {}
variable "defender_for_cloud_scope" {}
variable "create_firewall" { type = bool }
variable "create_virtual_network_gateway" { type = bool }

variable "create_ddos_protection_plan" {
  type = bool
}

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


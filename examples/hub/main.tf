locals {

  rgoh_hub_region                  = "eastus2"
  rgoh_hub_resource_group_name     = "RGOH-hubeastus2"
  environment                      = "hub"
  subscription_id                  = "aa47f583-fdf8-4ed6-acf8-46fcd7015701"
  virtual_network_address_space    = ["10.175.8.0/23"]
  virtual_network_name             = "vnet-hub-eastus2"
  virtual_network_dns_servers      = ["10.153.12.68"] # Internal IP address of Azure Firewall
  firewall_subnet_address_prefixes = ["10.175.8.0/26"]
  gateway_subnet_address_prefix    = ["10.175.9.0/26"]
  vpn_connection_shared_key        = "examplekey" # Generate a strong 32-character pre-shared key.
  local_vpn_gateway_address        = "134.238.183.191"
  prisma_access_vpn_addresses      = ["10.172.190.0/24", "10.172.192.0/22", "10.172.200.0/23", "10.172.202.0/23", "10.172.204.0/23"]
}

module "rgoh_hub" {
  source              = "../../modules/hub/"
  resource_group_name = local.rgoh_hub_resource_group_name
  location            = local.rgoh_hub_region
  subscription_id     = local.subscription_id

  // VIRTUAL NETWORK
  create_ddos_protection_plan    = true
  create_firewall                = true
  create_virtual_network_gateway = true
  create_local_network_gateway   = true
  create_nat_gateway             = true
  virtual_network_address_space  = local.virtual_network_address_space
  virtual_network_name           = local.virtual_network_name
  virtual_network_dns_servers    = local.virtual_network_dns_servers
  prisma_access_vpn_addresses    = local.prisma_access_vpn_addresses
  vpn_connection_shared_key      = local.vpn_connection_shared_key
  local_vpn_gateway_address      = local.local_vpn_gateway_address
  tags = {
    provisioner = "terraform"
    client      = "${local.environment}"
  }

  virtual_network_subnets = {

    "firewall" = {
      name                                          = "AzureFirewallSubnet"
      address_prefixes                              = local.firewall_subnet_address_prefixes
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
    }

    "vpn" = {
      name                                          = "GatewaySubnet"
      address_prefixes                              = local.gateway_subnet_address_prefix
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
    }
  }
}

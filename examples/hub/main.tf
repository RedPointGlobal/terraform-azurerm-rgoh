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
}

module "rgoh_hub" {
  source              = "../../modules/hub/"
  resource_group_name = local.rgoh_hub_resource_group_name
  location            = local.rgoh_hub_region
  subscription_id     = local.subscription_id
  // ADDONS
  create_ddos_protection_plan    = true
  create_firewall                = true
  create_virtual_network_gateway = true

  // VIRTUAL NETWORK
  virtual_network_address_space = local.virtual_network_address_space
  virtual_network_name          = local.virtual_network_name
  virtual_network_dns_servers   = local.virtual_network_dns_servers

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

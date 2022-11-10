locals {

  rgoh_hub_region              = "eastus2"
  rgoh_hub_resource_group_name = "RGOH-hubeastus2"
  environment                  = "hub"
  rgoh_hub_subscription_id     = ""
  client_id                    = ""
  tenant_id                    = ""
}

module "rgoh_hub" {
  source                   = "../modules/hub/"
  resource_group_name      = local.rgoh_hub_resource_group_name
  location                 = local.rgoh_hub_region
  defender_for_cloud_scope = "/subscriptions/${local.rgoh_hub_subscription_id}"

  // ADDONS
  create_ddos_protection_plan    = true
  create_firewall                = true
  create_virtual_network_gateway = true

  // VIRTUAL NETWORK
  virtual_network_address_space = ["10.175.8.0/23"]
  virtual_network_name          = "vnet-hub-eastus2"
  virtual_network_dns_servers   = ["10.153.12.68"]

  tags = {
    provisioner = "terraform"
    client      = "${local.environment}"
  }

  virtual_network_subnets = {

    "firewall" = {
      name                                          = "AzureFirewallSubnet"
      address_prefixes                              = ["10.175.8.0/26"]
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
    }

    "vpn" = {
      name                                          = "GatewaySubnet"
      address_prefixes                              = ["10.175.9.0/26"]
      private_endpoint_network_policies_enabled     = true
      private_link_service_network_policies_enabled = true
    }
  }
}

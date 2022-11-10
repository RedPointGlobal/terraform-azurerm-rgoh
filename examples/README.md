![RG](https://user-images.githubusercontent.com/42842390/158004336-60f07c05-7e5d-420e-87a6-22c5ac206fb6.jpg)
## Redpoint rgOne Hosted (RGOH) Hub and Spoke Examples

### Prerequisites
  ### HUB
  ```
  rgoh_hub_ddos_protection_plan_name = "ddos-pplan-eastus2"
  rgoh_hub_resource_group_name       = "RGOH-hubeastus2"
  rgoh_hub_subscription_id           = "" 
  rgoh_hub_virtual_network_name      = "vnet-hub-eastus2"
```
  ### SPOKE
  ```
  rgoh_spoke_client_name               = "rgoh-client-1"
  rgoh_spoke_client_prefix             = "rgohc1"
  rgoh_spoke_region                    = "eastus2"
  rgoh_spoke_resource_group_name       = "RGOH-client-1"
  rgoh_spoke_subscription_id           = ""
  rgoh_shared_platform_subscription_id = ""
  client_id                            = ""
  tenant_id                            = ""
  ```
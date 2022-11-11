![RG](https://user-images.githubusercontent.com/42842390/158004336-60f07c05-7e5d-420e-87a6-22c5ac206fb6.jpg)
## Redpoint rgOne Hosted (RGOH) Hub and Spoke Examples

### Prerequisites

  ### Terraform Provider Configuration
We recommend using either a Service Principal or Managed Service Identity when running Terraform non-interactively (such as when running Terraform in a CI server) - and authenticating using the Azure CLI when running Terraform locally.
```
export ARM_SUBSCRIPTION_ID="<azure_subscription_id>"
export ARM_TENANT_ID="<azure_subscription_tenant_id>"
export ARM_CLIENT_ID="<service_principal_appid>"
export ARM_CLIENT_SECRET="<service_principal_password>"
```
### Module Outputs
The following core resources are created
```
- Resource Group
- Azure Virtual Network
- Azure Firewall
- DDos Protection Plan
- Virtual Network Gateway
- Local Network Gateway
- NAT Gateway
- VPN Connection
- VNET Peering to Spoke 
- Network Watcher Flow Logs 
- Azure Diagnostics
- Log Analytics Workspace
- Storage account for Azure monitor diagnostics
```
![Hub (1)](https://user-images.githubusercontent.com/42842390/201029461-7359695b-b305-478c-8ef6-db67820d2dae.png)


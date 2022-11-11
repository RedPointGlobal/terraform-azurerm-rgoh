![RG](https://user-images.githubusercontent.com/42842390/158004336-60f07c05-7e5d-420e-87a6-22c5ac206fb6.jpg)
## Redpoint rgOne Hosted (RGOH) Hub and Spoke

This repository contains Terraform modules that deploy a security hardened hub & spoke virtual network topology in Azure. 

In addition, the modules deploy Azure resources that make up a standard production cloud environment for a Redpoint rgOne Client, with the hub virtual network acting as the central point of connectivity.
![Blank diagram (3)](https://user-images.githubusercontent.com/42842390/201256439-b66ea8b1-52ae-4051-9b96-b6663df00de0.png)
The architecture consists of the following aspects:

- The modules assume the spoke and Hub Network VNETs are in different Azure subscriptions.

### RGOH Hub  
The hub is the central point of connectivity to all RGOH spokes. It hosts services consumed by workloads hosted in the spoke virtual networks.

The following core resources are created
```
- Azure Virtual Network
- Azure Firewall
- DDos Protection Plan
- Virtual Network Gateway
- Local Network Gateway
- NAT Gateway
- VPN Connection
- Network Watcher Flow Logs
- Azure Diagnostics
```
### RGOH Spoke 
The Spoke is an isolated environment for a Redpoint rgOne hosted customer whose workloads are in their own virtual networks, managed separately from other spokes. 

The following core resources are created
```
- Azure Virtual Network
- Azure Virtual Desktop
- Azure SQL Server and DB
- Virtual Machines for RPDM and RPI
- AKS Cluster for Mercury and MDM
- VNET Peering to Hub
- Network Watcher Flow Logs 
- Azure Diagnostics
```
### Example Usage
Please refer to the ```examples/``` directory at the root of this repository . You can execute the ```terraform apply``` command in the examples folder to try the modules

We assume that you have setup service principal's credentials in your environment variables like below: The service principal must have "Contributor" or "Owner" Role assigned on the target subscription
```
export ARM_SUBSCRIPTION_ID="<azure_subscription_id>"
export ARM_TENANT_ID="<azure_subscription_tenant_id>"
export ARM_CLIENT_ID="<service_principal_appid>"
export ARM_CLIENT_SECRET="<service_principal_password>"
```
For more details, refer to the module README within the examples folder

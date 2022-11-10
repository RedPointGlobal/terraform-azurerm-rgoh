![RG](https://user-images.githubusercontent.com/42842390/158004336-60f07c05-7e5d-420e-87a6-22c5ac206fb6.jpg)
## Redpoint rgOne Hosted (RGOH) Hub and Spoke

This repository contains Terraform modules that deploy a security hardened hub & spoke virtual network topology in Azure. 

In addition, the modules deploy Azure resources that make up a standard production cloud environment for a Redpoint rgOne Client, with the hub virtual network acting as the central point of connectivity.
![Blank diagram](https://user-images.githubusercontent.com/42842390/201025253-06bab19e-21eb-4edc-a0d3-57a00d46f7ce.png)
The architecture consists of the following aspects:

### RGOH Hub  
The hub is the central point of connectivity to all RGOH spokes. It hosts services consumed by workloads hosted in the spoke virtual networks.

### RGOH Spoke 
The Spoke is an isolated environment for a Redpoint rgOne hosted customer whose workloads are in their own virtual networks, managed separately from other spokes. 

### Assumptions
- The modules assume the spoke and Hub Network VNETs are in different Azure subscriptions.

### Example Usage
Please refer to the ```examples/``` directory at the root of this repository . You can execute the ```terraform apply``` command in the examples folder to try the modules

We assume that you have setup service principal's credentials in your environment variables like below: The service principal must have "Contributor" or "Owner" Role assigned on the target subscription
```
export ARM_SUBSCRIPTION_ID="<azure_subscription_id>"
export ARM_TENANT_ID="<azure_subscription_tenant_id>"
export ARM_CLIENT_ID="<service_principal_appid>"
export ARM_CLIENT_SECRET="<service_principal_password>"
```

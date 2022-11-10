![RG](https://user-images.githubusercontent.com/42842390/158004336-60f07c05-7e5d-420e-87a6-22c5ac206fb6.jpg)
## Redpoint rgOne Hosted (RGOH) Hub and Spoke

This repository contains Terraform modules that deploy a security hardened hub & spoke virtual network topology in Azure. 

In addition, the modules deploy Azure resources that make up a standard production cloud environment for a Redpoint rgOne Client, with the hub virtual network acting as the central point of connectivity.
![Blank diagram (2)](https://user-images.githubusercontent.com/42842390/200998035-e8f73288-6ada-44f4-bdb2-315c773c17f7.png)
The architecture consists of the following aspects:

### RGOH Hub  
The hub is the central point of connectivity to all RGOH spokes. It hosts services consumed by workloads hosted in the spoke virtual networks.

### RGOH Spoke 
The Spoke is an isolated environment for a Redpoint rgOne hosted customer whose workloads are in their own virtual networks, managed separately from other spokes. 

### Assumptions
- The modules assume the spoke and Hub Network VNETs are in different Azure subscriptions.

### Examples
- Examples of using the modules exist under the examples/ subdirectory at the root of the repository.
```
- examples/main-hub.tf : Deploys the Hub
- examples/main-spoke.tf : Deploys the Spoke
```

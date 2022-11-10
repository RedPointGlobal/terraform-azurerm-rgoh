![RG](https://user-images.githubusercontent.com/42842390/158004336-60f07c05-7e5d-420e-87a6-22c5ac206fb6.jpg)
## Redpoint rgOne Hosted (RGOH) Hub and Spoke

This repository contains Terraform modules that deploy a security hardened hub & spoke virtual network topology in Azure. 

In addition, the modules deploy Azure resources that make up a standard production cloud environment for a Redpoint rgOne Client, with the hub virtual network acting as the central point of connectivity.
![Blank diagram (1)](https://user-images.githubusercontent.com/42842390/200983171-0d3c512d-3c1a-4994-a063-a353d08bcdc5.png)

### Assumptions
- The modules assume the spoke and Hub Network VNETs are in different Azure subscriptions.

### Examples
- Examples of using the modules exist under the examples/ subdirectory at the root of the repository.
```
- examples/main-hub.tf : Deploys the Hub
- examples/main-hub.tf : Deploys the Spoke
```
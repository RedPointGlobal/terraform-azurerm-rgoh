![RG](https://user-images.githubusercontent.com/42842390/158004336-60f07c05-7e5d-420e-87a6-22c5ac206fb6.jpg)
## Redpoint rgOne Hosted (RGOH) Hub and Spoke

This repository contains Terraform modules that deploy a security hardened hub & spoke virtual network topology in Azure. 

In addition, the modules deploy Azure resources that make up a standard production cloud environment for a Redpoint rgOne Client, with the hub virtual network acting as the central point of connectivity.

## Assumptions
- The spoke and Hub Network VNETs are in different subscriptions.

## Abbreviations
- RGOH - rgOne Hosted
- RG   - Resource Group
![Blank diagram](https://user-images.githubusercontent.com/42842390/200982906-d9b00cfe-0543-43e0-961e-f18cf43d48d2.png)

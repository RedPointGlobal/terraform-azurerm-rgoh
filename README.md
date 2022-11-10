![RG](https://user-images.githubusercontent.com/42842390/158004336-60f07c05-7e5d-420e-87a6-22c5ac206fb6.jpg)
## Redpoint rgOne Hosted (RGOH) Hub and Spoke

This repository contains Terraform modules that deploy and harden a hub-spoke network topology in Azure. In addition, the modules deploy azure resources that make up a standard production cloud environment for a Redpoint rgOne Client, with the hub virtual network acting as the central point of connectivity.

## Assumptions
- The spoke and Hub Network VNETs are in different subscriptions.

## Abbreviations
- RGOH - rgOne Hosted
- RG   - Resource Group

terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.38.0"
    }
  }
}

provider "tfe" {
  token = var.tf_cloud_token
}

terraform {
  cloud {
    organization = "redpointglobal"

    workspaces {
      name = "tfc-sandbox-01"
    }
  }
}
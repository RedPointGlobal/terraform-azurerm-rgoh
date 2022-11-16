terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.38.0"
    }
  }
}

provider "tfe" {

}

terraform {
  cloud {
    organization = "redpointglobal"

    workspaces {
      name = "tfc-sandbox-01"
    }
  }
}
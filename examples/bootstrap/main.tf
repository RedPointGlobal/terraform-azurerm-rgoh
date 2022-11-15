data "tfe_organizations" "main" {
}

resource "tfe_workspace" "main" {
  name         = "argo-sandbox"
  organization = data.tfe_organizations.main.id
  tag_names    = ["argo", "sandbox", "jmusana"]
}


resource "tfe_variable" "client_id" {
  name          = "client_id"
  value         = "7838e8f3-dba4-48de-82cd-b1d065f1efd4"
  category      = "terraform"
  workspace_id = tfe_workspace.main.id
}

resource "tfe_variable" "client_secret" {
  name          = "client_secret"
  value         = var.client_secret
  category      = "terraform"
  sensitive     = true
  workspace_id = tfe_workspace.main.id

}

resource "tfe_variable" "tenant_id" {
  name          = "tenant_id"
  value         = "16a3d264-4987-408a-a6aa-69dd136253fc"
  category      = "terraform"
  workspace_id = tfe_workspace.main.id
}

resource "tfe_variable" "subscription_id" {
  name          = "subscription_id"
  value         = var.subscription_id
  category      = "terraform"
  workspace_id = tfe_workspace.main.id
}
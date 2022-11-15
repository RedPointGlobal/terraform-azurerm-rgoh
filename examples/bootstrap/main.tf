data "tfe_organizations" "main" {
}

resource "tfe_workspace" "main" {
  name         = "argo-sandbox"
  organization = data.tfe_organizations.main.id
  tag_names    = ["argo", "sandbox", "jmusana"]
}

resource "tfe_variable_set" "client_id" {
  name          = "client_id"
  value         = var.client_id
  description   = "Some description."
  global        = false
  workspace_ids = tfe_workspace.main.id
}

resource "tfe_variable_set" "client_secret" {
  name          = "client_secret"
  value         = var.client_secret
  description   = "Client Secret"
  global        = false
  sensitive     = true
  workspace_ids = tfe_workspace.main.id

}

resource "tfe_variable_set" "tenant_id" {
  name          = "tenant_id"
  value         = var.tenant_id
  description   = "Client ID."
  global        = false
  workspace_ids = tfe_workspace.main.id
}

resource "tfe_variable_set" "subscription_id" {
  name          = "subscription_id"
  value         = var.subscription_id
  description   = "subscription id"
  global        = false
  workspace_ids = tfe_workspace.main.id
}
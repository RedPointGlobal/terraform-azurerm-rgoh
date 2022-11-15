resource "tfe_organization" "main" {
  name  = "tfc-black-devops"
  email = "musanajim@gmail.com"
}

resource "tfe_workspace" "main" {
  name         = "tfc-rgoh-onboard"
  organization = tfe_organization.main.id
  tag_names    = ["argo", "sandbox", "jmusana"]

  depends_on = [
    tfe_organization.main
  ]
}

resource "tfe_variable" "client_id" {
  key          = "client_id"
  value        = "7838e8f3-dba4-48de-82cd-b1d065f1efd4"
  category     = "terraform"
  workspace_id = tfe_workspace.main.id

  depends_on = [
    tfe_workspace.main
  ]
}

resource "tfe_variable" "client_secret" {
  key          = "client_secret"
  value        = var.client_secret
  category     = "terraform"
  sensitive    = true
  workspace_id = tfe_workspace.main.id

  depends_on = [
    tfe_workspace.main
  ]

}

resource "tfe_variable" "tenant_id" {
  key          = "tenant_id"
  value        = "16a3d264-4987-408a-a6aa-69dd136253fc"
  category     = "terraform"
  workspace_id = tfe_workspace.main.id

  depends_on = [
    tfe_workspace.main
  ]
}

resource "tfe_variable" "subscription_id" {
  key          = "subscription_id"
  value        = var.subscription_id
  category     = "terraform"
  workspace_id = tfe_workspace.main.id

  depends_on = [
    tfe_workspace.main
  ]
}
data "tfe_organizations" "main" {
}

resource "tfe_workspace" "main" {
  name         = "argo-sandbox"
  organization = data.tfe_organizations.main.id
  tag_names    = ["argo", "sandbox", "jmusana"]
}
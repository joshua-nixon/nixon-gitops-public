locals {
  azure_applications_by_name = { for application in var.azure_applications : application.name => application }
}

module "application_bundles" {
  for_each = local.azure_applications_by_name

  source                  = "../../modules/azure_application_bundle"
  display_name            = each.value.name
  client_secrets          = each.value.client_secrets
  tags                    = var.azure_common_labels
  federated_credentials   = each.value.federated_credentials
  redirect_url            = each.value.redirect_url
  group_membership_claims = each.value.group_membership_claims
  cluster_issuer          = var.cluster_issuer
}

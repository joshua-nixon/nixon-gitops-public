locals {
  acr_pull_registries_by_application = {
    for application_name in keys(module.azure_application) : application_name => {
      for registry in var.container_registries : module.container_registries[registry.name].login_server => registry
      if contains(try(registry.rbac_role_assignments["AcrPull"], []), application_name)
    }
    if anytrue([
      for registry in var.container_registries :
      contains(try(registry.rbac_role_assignments["AcrPull"], []), application_name)
    ])
  }

  dockerconfig_auths_by_application = {
    for application_name, registries in local.acr_pull_registries_by_application : application_name => {
      for login_server, registry in registries : login_server => {
        auth = base64encode("${module.azure_application[application_name].application_client_id}:${module.azure_application[application_name].client_secrets["container-registry"].value}")
      }
    }
  }
}

module "azure_application" {
  for_each                = { for application in var.applications : application.name => application }
  source                  = "../../modules/azure_application"
  display_name            = each.value.name
  client_secrets          = each.value.client_secrets
  federated_credentials   = each.value.federated_credentials
  redirect_url            = each.value.redirect_url
  group_membership_claims = each.value.group_membership_claims
}

resource "local_file" "dockerconfig" {
  for_each = local.dockerconfig_auths_by_application
  content  = jsonencode({ auths = each.value })
  filename = "/workspaces/nixon-gitops/.config/dockerconfig-${each.key}.json"
}

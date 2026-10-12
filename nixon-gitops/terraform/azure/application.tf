locals {
  acr_pull_registries_by_application = {
    for application_name in keys(module.azure_application) : application_name => {
      for registry in var.container_registries : module.azure_container_registry[registry.name].login_server => registry
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
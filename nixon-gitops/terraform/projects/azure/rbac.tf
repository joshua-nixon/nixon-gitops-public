locals {
  rbac_scopes = {
    container_registries = { for name, registry in module.container_registries : name => registry.id }
    key_vaults           = { for name, vault in module.key_vaults : name => vault.id }
    storage_accounts     = { for name, account in azurerm_storage_account.default : name => account.id }
  }

  rbac_principals = merge(
    { for name, application in module.application_bundles : name => application.service_principal_object_id },
    { for name, group in azuread_group.default : name => group.object_id }
  )

  rbac_resource_configs = {
    container_registries = var.azure_container_registries
    key_vaults           = var.azure_key_vaults
    storage_accounts     = var.azure_storage_accounts
  }

  azure_rbac_assignments_by_key = merge(flatten([
    for scope_type, resources in local.rbac_resource_configs : [
      for resource in resources : merge([
        for role_name, principal_refs in try(resource.rbac_role_assignments, {}) : {
          for principal_ref in principal_refs :
          "${scope_type}.${resource.name}.${role_name}.${principal_ref}" => {
            scope_type           = scope_type
            scope_name           = resource.name
            role_definition_name = role_name
            principal_ref        = principal_ref
          }
        }
      ]...)
    ]
  ])...)
}

resource "azurerm_role_assignment" "rbac" {
  for_each = local.azure_rbac_assignments_by_key

  scope                = local.rbac_scopes[each.value.scope_type][each.value.scope_name]
  role_definition_name = each.value.role_definition_name
  principal_id         = local.rbac_principals[each.value.principal_ref]
}

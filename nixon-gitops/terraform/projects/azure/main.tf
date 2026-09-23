locals {
  rbac_principals = merge(
    { for name, application in module.azure_application : name => application.service_principal_object_id },
    { for name, group in azuread_group.default : name => group.object_id },
    { for name, identity in module.user_assigned_identity : name => identity.principal_id }
  )
}

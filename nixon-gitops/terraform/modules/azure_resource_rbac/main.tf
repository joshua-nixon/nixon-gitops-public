locals {
  assignments_by_key = {
    for assignment in flatten([
      for role_name, principal_refs in var.role_assignments : [
        for principal_ref in principal_refs : {
          role_definition_name = role_name
          principal_ref        = principal_ref
        }
      ]
    ]) : "${assignment.role_definition_name}.${assignment.principal_ref}" => assignment
  }
}

resource "azurerm_role_assignment" "this" {
  for_each = local.assignments_by_key

  scope                = var.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = var.rbac_principals[each.value.principal_ref]
}
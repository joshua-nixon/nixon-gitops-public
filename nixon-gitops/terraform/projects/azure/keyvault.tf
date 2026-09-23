module "keyvault" {
  for_each              = { for x in var.keyvaults : x.name => x }
  source                = "../../modules/azure_keyvault"
  name                  = each.value.name
  resource_group_name   = each.value.resource_group_name
  location              = azurerm_resource_group.default[each.value.resource_group_name].location
  tenant_id             = var.tenant_id
  rbac_role_assignments = each.value.rbac_role_assignments
  rbac_principals       = local.rbac_principals
}

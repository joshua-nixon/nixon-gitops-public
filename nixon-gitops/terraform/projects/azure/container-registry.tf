
module "container_registries" {
  for_each              = { for x in var.container_registries : x.name => x }
  source                = "git::https://github.com/joshua-nixon/terraform-modules.git//azure_container_registry?ref=main"
  registry_name         = each.value.name
  resource_group_name   = each.value.resource_group_name
  location              = azurerm_resource_group.default[each.value.resource_group_name].location
  rbac_role_assignments = each.value.rbac_role_assignments
  rbac_principals       = local.rbac_principals
}

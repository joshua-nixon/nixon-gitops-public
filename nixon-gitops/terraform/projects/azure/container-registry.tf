
module "container_registries" {
  for_each            = { for x in var.container_registries : x.name => x }
  source              = "../../modules/azure_container_registry"
  registry_name       = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = azurerm_resource_group.default[each.value.resource_group_name].location
}

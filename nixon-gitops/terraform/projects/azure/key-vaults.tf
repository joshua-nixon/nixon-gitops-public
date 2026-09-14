module "key_vaults" {
  for_each            = { for x in var.azure_key_vaults : x.name => x }
  source              = "../../modules/azure_key_vault"
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = azurerm_resource_group.default[each.value.resource_group_name].location
  tenant_id           = var.azure_tenant_id
  tags                = var.azure_common_labels
}

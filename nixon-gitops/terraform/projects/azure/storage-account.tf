
module "azure_storageaccount" {
  for_each            = { for account in var.storage_accounts : account.name => account }
  source              = "../../modules/azure_storageaccount"
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = azurerm_resource_group.default[each.value.resource_group_name].location
}

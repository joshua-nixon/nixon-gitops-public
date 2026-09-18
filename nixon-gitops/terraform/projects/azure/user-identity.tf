module "user_assigned_identity" {
  for_each              = { for identity in var.user_identities : identity.name => identity }
  source                = "../../modules/azure_user_identity"
  name                  = each.value.name
  resource_group_name   = each.value.resource_group_name
  federated_credentials = each.value.federated_credentials
  location              = azurerm_resource_group.default[each.value.resource_group_name].location
}

output "user_assigned_identities" {
  value = {
    for identity_name, identity_module in module.user_assigned_identity : identity_name => {
      client_id = identity_module.client_id
    }
  }
}

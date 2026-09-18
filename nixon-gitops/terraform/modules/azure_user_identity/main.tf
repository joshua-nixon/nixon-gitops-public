
resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = module.resource_tags.all_tags
}

resource "azurerm_federated_identity_credential" "this" {
  for_each = local.federated_credential_map

  user_assigned_identity_id = azurerm_user_assigned_identity.this.id
  name                      = each.value.name
  issuer                    = each.value.issuer
  subject                   = each.value.subject
  audience                  = ["api://AzureADTokenExchange"]
}

module "resource_tags" {
  source = "../azure_resource_tags"
  update_change_triggers = {
    resource_group_name = var.resource_group_name
  }
}

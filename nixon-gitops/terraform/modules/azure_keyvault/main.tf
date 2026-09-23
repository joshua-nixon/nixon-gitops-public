resource "azurerm_key_vault" "this" {
  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = var.soft_delete_retention_days
  tags                       = module.resource_tags.all_tags
}

module "rbac" {
  source                = "../azure_resource_rbac"
  scope                 = azurerm_key_vault.this.id
  role_assignments      = var.rbac_role_assignments
  rbac_principals       = var.rbac_principals
}

module "resource_tags" {
  source = "../common_resource_tags"
  update_change_triggers = {
    soft_delete_retention_days = var.soft_delete_retention_days
  }
}

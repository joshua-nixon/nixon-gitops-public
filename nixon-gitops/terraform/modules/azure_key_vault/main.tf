locals {
  tags = merge(var.tags, {
    "updated-at" = time_static.updated_at.rfc3339
  })
}

resource "azurerm_key_vault" "this" {
  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = var.soft_delete_retention_days
  tags                       = local.tags
}

resource "time_static" "updated_at" {
  triggers = {
    name                       = var.name
    resource_group_name        = var.resource_group_name
    location                   = var.location
    tenant_id                  = var.tenant_id
    soft_delete_retention_days = var.soft_delete_retention_days
  }
}

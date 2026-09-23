locals {
  tags_set = toset([for key, value in module.resource_tags.all_tags : "${key}=${value}"])
}

resource "azuread_application" "this" {
  display_name            = var.display_name
  tags                    = local.tags_set
  group_membership_claims = var.group_membership_claims

  dynamic "web" {
    for_each = var.redirect_url != null ? [var.redirect_url] : []
    content {
      redirect_uris = [web.value]
    }
  }
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
  tags      = local.tags_set
}

resource "azuread_application_password" "this" {
  for_each       = toset(var.client_secrets)
  application_id = azuread_application.this.id
  display_name   = each.value
}

module "resource_tags" {
  source = "../common_resource_tags"
  update_change_triggers = {
    display_name            = var.display_name
    redirect_url            = var.redirect_url
    group_membership_claims = jsonencode(var.group_membership_claims)
    client_secrets          = jsonencode(var.client_secrets)
  }
}

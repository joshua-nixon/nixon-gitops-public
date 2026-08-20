locals {
  tags_set = toset([for key, value in var.tags : "${key}=${value}"])
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
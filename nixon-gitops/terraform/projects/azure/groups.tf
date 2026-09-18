
locals {
  all_member_emails = distinct(flatten([for g in var.user_groups : g.member_emails]))
}

data "azuread_user" "all_group_members" {
  for_each            = toset(local.all_member_emails)
  user_principal_name = each.value
}

resource "azuread_group" "default" {
  for_each         = var.user_groups
  display_name     = each.key
  security_enabled = true
  members          = [for email in each.value.member_emails : data.azuread_user.all_group_members[email].object_id]
}

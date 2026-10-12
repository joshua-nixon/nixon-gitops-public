locals {
  rbac_principals = merge(
    { for name, application in module.azure_application : name => application.service_principal_object_id },
    { for name, identity in module.azure_user_identity : name => identity.principal_id },
    { "current-user" = data.azuread_user.current_user.object_id }
  )
}

data "azurerm_client_config" "current" {

}

data "azuread_user" "current_user" {
  object_id = data.azurerm_client_config.current.object_id
}

module "azure_resource_group" {
  for_each = { for x in var.resource_groups : x => x }
  source   = "git::https://github.com/joshua-nixon/terraform-modules.git//azure_resource_group?ref=main"
  name     = each.value
  location = "uksouth"
}

module "azure_storageaccount" {
  for_each            = { for account in var.storage_accounts : account.name => account }
  source              = "git::https://github.com/joshua-nixon/terraform-modules.git//azure_storageaccount?ref=main"
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = module.azure_resource_group[each.value.resource_group_name].location
  rbac_role_assignments = {
    for role, principals in each.value.rbac_role_assignments : role =>
    [for principal in principals : local.rbac_principals[principal]]
  }
}

module "azure_keyvault" {
  for_each            = { for x in var.keyvaults : x.name => x }
  source              = "git::https://github.com/joshua-nixon/terraform-modules.git//azure_keyvault?ref=main"
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = module.azure_resource_group[each.value.resource_group_name].location
  tenant_id           = var.tenant_id
  rbac_role_assignments = {
    for role, principals in each.value.rbac_role_assignments : role =>
    [for principal in principals : local.rbac_principals[principal]]
  }
}

module "azure_budget" {
  source          = "git::https://github.com/joshua-nixon/terraform-modules.git//azure_budget?ref=main"
  name            = "monthly-subscription-budget"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.monthly_budget.amount
  contact_emails  = var.monthly_budget.contact_emails
  start_date      = var.monthly_budget.start_date
}

module "azure_container_registry" {
  for_each            = { for x in var.container_registries : x.name => x }
  source              = "git::https://github.com/joshua-nixon/terraform-modules.git//azure_container_registry?ref=main"
  registry_name       = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = module.azure_resource_group[each.value.resource_group_name].location
  rbac_role_assignments = {
    for role, principals in each.value.rbac_role_assignments : role =>
    [for principal in principals : local.rbac_principals[principal]]
  }
}

module "azure_user_identity" {
  for_each              = { for identity in var.user_identities : identity.name => identity }
  source                = "git::https://github.com/joshua-nixon/terraform-modules.git//azure_user_identity?ref=main"
  name                  = each.value.name
  resource_group_name   = each.value.resource_group_name
  federated_credentials = each.value.federated_credentials
  location              = module.azure_resource_group[each.value.resource_group_name].location
}

module "azure_application" {
  for_each                = { for application in var.applications : application.name => application }
  source                  = "git::https://github.com/joshua-nixon/terraform-modules.git//azure_application?ref=main"
  display_name            = each.value.name
  client_secrets          = each.value.client_secrets
  federated_credentials   = each.value.federated_credentials
  redirect_url            = each.value.redirect_url
  group_membership_claims = each.value.group_membership_claims
}
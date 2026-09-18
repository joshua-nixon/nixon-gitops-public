
resource "azurerm_resource_group" "default" {
  for_each = { for x in var.resource_groups : x.name => x }
  name     = each.value.name
  location = "uksouth"
  tags = {
    "managed-by" = "terraform"
  }
}

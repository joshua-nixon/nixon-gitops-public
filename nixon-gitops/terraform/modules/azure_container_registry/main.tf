
resource "azurerm_container_registry" "registry" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  tags                = module.resource_tags.all_tags
}

module "rbac" {
  source                = "../azure_resource_rbac"
  scope                 = azurerm_container_registry.registry.id
  role_assignments      = var.rbac_role_assignments
  rbac_principals       = var.rbac_principals
}

resource "azurerm_container_registry_task" "purge_task" {
  name                  = "purge-task"
  container_registry_id = azurerm_container_registry.registry.id
  tags                  = module.resource_tags.all_tags

  platform {
    os = "Linux"
  }

  encoded_step {
    task_content = <<-EOT
      version: v1.1.0
      steps:
        - cmd: acr purge --filter '.*:.*' --ago ${var.purge_older_than_days}d --keep ${var.purge_retain_count}
          timeout: 60
    EOT
  }

  timer_trigger {
    name     = "purge-timer"
    schedule = "0 0 * * 0"
    enabled  = true
  }
}

module "resource_tags" {
  source = "../common_resource_tags"
  update_change_triggers = {
    purge_older_than_days = var.purge_older_than_days
    purge_retain_count    = var.purge_retain_count
  }
}

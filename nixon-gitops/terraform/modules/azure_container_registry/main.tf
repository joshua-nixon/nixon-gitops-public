
locals {
  tags = merge(var.tags, {
    "updated-at" = time_static.updated_at.rfc3339
  })
}

resource "azurerm_container_registry" "registry" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  tags                = local.tags
}

resource "time_static" "updated_at" {
  triggers = {
    name                  = var.registry_name
    resource_group_name   = var.resource_group_name
    location              = var.location
    purge_older_than_days = var.purge_older_than_days
    purge_retain_count    = var.purge_retain_count
  }
}

resource "azurerm_container_registry_task" "purge_task" {
  name                  = "purge-task"
  container_registry_id = azurerm_container_registry.registry.id
  tags                  = local.tags

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

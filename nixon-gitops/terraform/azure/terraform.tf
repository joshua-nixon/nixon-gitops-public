terraform {
  required_version = ">= 1.14.9"

  backend "azurerm" {
    resource_group_name  = "rg-v1-tfstate"
    storage_account_name = "nixontfstatestorage"
    container_name       = "tfstate-azure"
    key                  = "tfstate/terraform.tfstate"
    use_azuread_auth     = true
  }

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.8.0"
    }

    azurerm = {
      source  = "hashicorp/azurerm",
      version = "4.69.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
  subscription_id = var.subscription_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}

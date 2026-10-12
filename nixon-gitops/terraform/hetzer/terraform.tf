terraform {
  backend "azurerm" {
    resource_group_name  = "rg-v1-tfstate"
    storage_account_name = "nixontfstatestorage"
    container_name       = "tfstate-hetzner"
    key                  = "tfstate/terraform.tfstate"
    use_azuread_auth     = true
  }

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.66.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.6.1"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "local" {

}
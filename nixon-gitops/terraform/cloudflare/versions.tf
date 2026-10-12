
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-v1-tfstate"
    storage_account_name = "nixontfstatestorage"
    container_name       = "tfstate-cloudflare"
    key                  = "tfstate/terraform.tfstate"
    use_azuread_auth     = true
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.19.1"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

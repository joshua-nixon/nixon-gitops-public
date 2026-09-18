terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.8.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }

    azurerm = {
      source  = "hashicorp/azurerm",
      version = "4.69.0"
    }
  }
}

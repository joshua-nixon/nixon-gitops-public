terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.66.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0"
    }
    imager = {
      source  = "hcloud-talos/imager"
      version = "1.0.20"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "imager" {
  token = var.hcloud_token
}

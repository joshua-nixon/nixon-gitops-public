variable "server_pools" {
  type = list(object({
    name         = string
    server_type  = string
    count        = number
    image        = string
    cluster_role = string
    location     = string
  }))
  default = []
}

variable "firewalls" {
  type = list(object({
    name                = string
    attachment_selector = string
    rules = list(object({
      description = string
      protocol    = string
      port        = string
    }))
  }))
  default = []
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "netbird_setup_key" {
  type      = string
  sensitive = true
}

variable "ssh_private_key_path" {
  type = string
}
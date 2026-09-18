variable "ssh_keys" {
  type = list(object({
    name            = string
    public_key_path = string
  }))
}

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

variable "firewall" {
  type = object({
    label_selector = string
    rules = list(object({
      description = string
      protocol    = string
      port        = optional(string)
      groups      = optional(list(string), [])
    }))
  })
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "netbird_setup_key" {
  type      = string
  sensitive = true
}

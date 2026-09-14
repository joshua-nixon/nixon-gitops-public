variable "ssh_keys" {
  type = list(object({
    name            = string
    public_key_path = string
  }))
}

variable "server_pools" {
  type = list(object({
    name           = string
    server_type    = string
    count          = number
    image          = string
    cluster_role   = string
    location       = string
  }))
  default = []
}

variable "firewall_rules" {
  type = list(object({
    description = string
    protocol    = string
    port        = optional(string)
    groups      = optional(list(string), [])
  }))
  default = []
}

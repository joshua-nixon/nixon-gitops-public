
variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "netbird_setup_key" {
  type      = string
  sensitive = true
}

variable "cluster_issuer_url" {
  type = string
}

variable "hcloud_firewall_rules" {
  type = list(object({
    description = string
    protocol    = string
    port        = optional(string)
    groups      = optional(list(string), [])
  }))
  default = []
}

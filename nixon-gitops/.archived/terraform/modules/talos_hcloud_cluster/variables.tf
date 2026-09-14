
variable "servers" {
  type = list(object({
    name         = string
    location     = string
    server_type  = string
    machine_type = string
    bootstrap    = bool
  }))
}

variable "talos_version" {
  type = string
}

variable "talos_schematic" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "netbird_setup_key" {
  type      = string
  sensitive = true
}

variable "talosconfig_path" {
  type = string
}

variable "kubeconfig_path" {
  type = string
}

variable "issuer_url" {
  type = string
}

variable "firewall_ids" {
  type    = list(string)
  default = []
}

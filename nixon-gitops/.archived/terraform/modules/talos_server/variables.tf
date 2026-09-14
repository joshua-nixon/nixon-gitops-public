variable "talos_version" {
  type = string
}

variable "endpoint" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "setup_key" {
  type = string
}

variable "public_ipv4_address" {
  type = string
}

variable "bootstrap" {
  type = bool
}

variable "machine_secrets" {
  type = any
}

variable "client_configuration" {
  type = any
}

variable "machine_configuration" {
  type = any
}

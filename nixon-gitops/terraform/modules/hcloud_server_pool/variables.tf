variable "name" {
  type    = string
  default = null
}

variable "labels" {
  type    = map(string)
  default = null
}

variable "location" {
  type = string
}

variable "server_type" {
  type = string
}

variable "image" {
  type = string
}

variable "server_count" {
  type = number
}

variable "ssh_key_id" {
  type    = string
  default = null
}

variable "firewall_id" {
  type    = string
  default = null
}

variable "user_data" {
  type      = string
  default   = null
  sensitive = true
}

variable "resource_group_name" {
  type = string
}

variable "registry_name" {
  type = string
}

variable "location" {
  type = string
}

variable "purge_older_than_days" {
  type    = number
  default = 30
}

variable "purge_retain_count" {
  type    = number
  default = 5
}

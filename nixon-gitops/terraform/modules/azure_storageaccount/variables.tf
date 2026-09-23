variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "rbac_role_assignments" {
  type    = map(list(string))
  default = {}
}

variable "rbac_principals" {
  type    = map(string)
  default = {}
}

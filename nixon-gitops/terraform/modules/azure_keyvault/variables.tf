variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "soft_delete_retention_days" {
  type    = number
  default = 7
}

variable "rbac_role_assignments" {
  type    = map(list(string))
  default = {}
}

variable "rbac_principals" {
  type    = map(string)
  default = {}
}

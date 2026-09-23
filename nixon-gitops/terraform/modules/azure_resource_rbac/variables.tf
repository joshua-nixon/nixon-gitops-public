variable "scope" {
  type = string
}

variable "role_assignments" {
  type    = map(list(string))
  default = {}
}

variable "rbac_principals" {
  type    = map(string)
  default = {}
}
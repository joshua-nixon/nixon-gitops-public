variable "resource_group_name" {
  type = string
}

variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "federated_credentials" {
  type = list(object({
    serviceaccounts = optional(object({
      issuer = string
      accounts = list(object({
        name      = string
        namespace = string
      }))
    }))
    github_organization = optional(object({
      id   = number
      name = string
      repositories = list(object({
        id       = number
        name     = string
        branches = list(string)
      }))
    }))
  }))
  default = []
}

variable "display_name" {
  type = string
}

variable "redirect_url" {
  type    = string
  default = null
}

variable "group_membership_claims" {
  type    = list(string)
  default = null
}

variable "client_secrets" {
  type    = list(string)
  default = []
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

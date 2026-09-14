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
    subject_identifier = optional(string)
    issuer             = optional(string)
    serviceaccounts = optional(object({
      issuer = string
      accounts = list(object({
        name      = string
        namespace = string
      }))
    }))
    github = optional(object({
      organisation    = string
      organisation_id = number
      repository      = string
      repository_id   = number
      branches        = list(string)
    }))
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

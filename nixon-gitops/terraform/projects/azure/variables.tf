
variable "resource_groups" {
  type = list(object({
    name = string
  }))
}

variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "monthly_budget" {
  type = object({
    amount         = number
    contact_emails = list(string)
    start_date     = string
  })
}

variable "keyvaults" {
  type = list(object({
    name                  = string
    resource_group_name   = string
    rbac_role_assignments = optional(map(list(string)), {})
  }))
}

variable "container_registries" {
  type = list(object({
    name                  = string
    resource_group_name   = string
    rbac_role_assignments = optional(map(list(string)), {})
  }))
}

variable "storage_accounts" {
  type = list(object({
    name                  = string
    resource_group_name   = string
    rbac_role_assignments = optional(map(list(string)), {})
  }))
}

variable "applications" {
  type = list(object({
    name                    = string
    redirect_url            = optional(string)
    group_membership_claims = optional(list(string))
    client_secrets          = optional(list(string), [])
    federated_credentials = optional(list(object({
      subject_identifier = optional(string)
      issuer             = optional(string)
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
    })), [])
  }))
  default = []
}

variable "user_groups" {
  type = map(object({
    member_emails = list(string)
    display_name  = optional(string)
    mail_nickname = optional(string)
  }))
  default = {}
}

variable "user_identities" {
  type = list(object({
    name                = string
    resource_group_name = string
    federated_credentials = optional(list(object({
      subject_identifier = optional(string)
      issuer             = optional(string)
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
    })), [])
  }))
  default = []
}

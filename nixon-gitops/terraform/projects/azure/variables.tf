
variable "azure_resource_groups" {
  type = list(object({
    name = string
  }))
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "azure_key_vaults" {
  type = list(object({
    name                  = string
    resource_group_name   = string
    rbac_role_assignments = optional(map(list(string)), {})
  }))
}

variable "azure_container_registries" {
  type = list(object({
    name                  = string
    resource_group_name   = string
    rbac_role_assignments = optional(map(list(string)), {})
  }))
}

variable "azure_storage_accounts" {
  type = list(object({
    name                  = string
    resource_group_name   = string
    rbac_role_assignments = optional(map(list(string)), {})
  }))
}

variable "azure_common_labels" {
  type    = map(string)
  default = {}
}

variable "azure_applications" {
  type = list(object({
    name                    = string
    redirect_url            = optional(string)
    group_membership_claims = optional(list(string))
    client_secrets          = optional(list(string), [])
    federated_credentials = optional(list(object({
      subject_identifier = optional(string)
      issuer             = optional(string)
      kubernetes_namespace = optional(object({
        namespace       = string
        issuer          = optional(string)
        serviceaccounts = list(string)
      }))

      github = optional(object({
        organisation = string
        organisation_id = number
        repository   = string
        repository_id = number
        branches     = list(string)
      }))
    })), [])
  }))
  default = []
}

variable "azure_groups" {
  type = map(object({
    member_emails = list(string)
    display_name  = optional(string)
    mail_nickname = optional(string)
  }))
  default = {}
}

variable "cluster_issuer" {
  type = string
  default = null
}
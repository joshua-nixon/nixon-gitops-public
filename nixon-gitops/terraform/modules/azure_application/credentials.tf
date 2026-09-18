locals {
  k8s_credentials = flatten([
    for cred in var.federated_credentials : [
      for account in cred.serviceaccounts.accounts : {
        subject = format("system:serviceaccount:%s:%s", account.namespace, account.name)
        issuer  = cred.serviceaccounts.issuer
        name = format(
          "namespace-%s-%s",
          account.namespace,
          account.name
        )
      }
    ]
    if cred.serviceaccounts != null
  ])

  github_credentials = flatten([
    for cred in var.federated_credentials : [
      for repository in cred.github_organization.repositories : [
        for branch in repository.branches : {
          issuer = "https://token.actions.githubusercontent.com"
          name = format(
            "github-%s-%s-%s",
            cred.github_organization.name,
            repository.name,
            branch
          )
          subject = format(
            "repo:%s@%s/%s@%s:ref:refs/heads/%s",
            cred.github_organization.name,
            cred.github_organization.id,
            repository.name,
            repository.id,
            branch
          )
        }
      ]
    ]
    if cred.github_organization != null
  ])

  federated_credential_list = concat(
    local.k8s_credentials,
    local.github_credentials
  )

  federated_credential_map = {
    for item in local.federated_credential_list : item.name => item
  }
}

resource "azuread_application_federated_identity_credential" "this" {
  for_each = local.federated_credential_map

  application_id = azuread_application.this.id
  display_name   = each.value.name
  issuer         = each.value.issuer
  subject        = each.value.subject
  audiences      = ["api://AzureADTokenExchange"]
}

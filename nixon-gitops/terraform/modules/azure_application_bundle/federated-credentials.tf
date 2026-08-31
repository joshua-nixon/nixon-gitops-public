locals {
  federated_credential_list = flatten([
    for credential in var.federated_credentials : credential.kubernetes_namespace != null ? [
      for serviceaccount in credential.kubernetes_namespace.serviceaccounts : {
        key     = format("kubernetes-%s-%s", credential.kubernetes_namespace.namespace, serviceaccount)
        subject = format("system:serviceaccount:%s:%s", credential.kubernetes_namespace.namespace, serviceaccount)
        issuer  = coalesce(credential.kubernetes_namespace.issuer, var.cluster_issuer)
      }
      ] : credential.subject_identifier != null ? [
      {
        key     = format("federated-credential-%s", substr(sha1(credential.subject_identifier), 0, 8))
        subject = credential.subject_identifier
        issuer  = credential.issuer
      }
      ] : [
      for branch in credential.github.branches : {
        key     = format("github-%s-%s-%s", credential.github.organisation, credential.github.repository, branch)
        subject = format(
          "repo:%s@%s/%s@%s:ref:refs/heads/%s", 
          credential.github.organisation, 
          credential.github.organisation_id,
          credential.github.repository, 
          credential.github.repository_id,
          branch
        )
        issuer  = "https://token.actions.githubusercontent.com"
      }
    ]
  ])

  federated_credential_map = {
    for item in local.federated_credential_list : item.key => {
      subject   = item.subject
      issuer    = item.issuer
    }
  }
}

resource "azuread_application_federated_identity_credential" "this" {
  for_each = local.federated_credential_map

  application_id = azuread_application.this.id
  display_name   = each.key
  issuer         = each.value.issuer
  subject        = each.value.subject
  audiences      = ["api://AzureADTokenExchange"]
}

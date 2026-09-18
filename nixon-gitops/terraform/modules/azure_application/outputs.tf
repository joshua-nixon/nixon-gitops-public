output "application_id" {
  value = azuread_application.this.id
}

output "application_client_id" {
  value = azuread_application.this.client_id
}

output "service_principal_id" {
  value = azuread_service_principal.this.id
}

output "service_principal_object_id" {
  value = azuread_service_principal.this.object_id
}

output "client_secrets" {
  value = {
    for key, password in azuread_application_password.this : key => {
      display_name = password.display_name
      id           = password.id
      value        = password.value
    }
  }
  sensitive = true
}

output "federated_identity_credentials" {
  value = {
    for key, credential in azuread_application_federated_identity_credential.this : key => {
      id           = credential.id
      display_name = credential.display_name
      subject      = credential.subject
      issuer       = credential.issuer
      audiences    = credential.audiences
    }
  }
}
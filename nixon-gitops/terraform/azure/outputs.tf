resource "local_file" "dockerconfig" {
  for_each = local.dockerconfig_auths_by_application
  content  = jsonencode({ auths = each.value })
  filename = "/workspaces/nixon-gitops/.config/dockerconfig-${each.key}.json"
}

output "user_assigned_identities" {
  value = {
    for identity_name, identity_module in module.azure_user_identity : identity_name => {
      client_id = identity_module.client_id
    }
  }
}
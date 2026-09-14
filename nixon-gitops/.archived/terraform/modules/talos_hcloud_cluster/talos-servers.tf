locals {
  talos_cluster_endpoint     = local.created_hcloud_servers[0].public_ipv4_address
  talos_cluster_private_ipv4 = local.created_talos_servers[0].private_ipv4_address

  created_talos_servers = [for server in module.talos_server : server]
}

module "talos_server" {
  source                = "../../modules/talos_server"
  for_each              = local.hcloud_servers
  talos_version         = var.talos_version
  endpoint              = local.talos_cluster_endpoint
  cluster_name          = var.cluster_name
  setup_key             = var.netbird_setup_key
  machine_secrets       = talos_machine_secrets.this
  public_ipv4_address   = each.value.public_ipv4_address
  client_configuration  = data.talos_client_configuration.this
  machine_configuration = data.talos_machine_configuration.controlplane
  machine_type          = each.value.machine_type
  bootstrap             = each.value.bootstrap
}

locals {
  created_servers = flatten([
    for pool_name, mod in module.hcloud_server_pools : [
      for s in mod.servers : merge(s, {
        cluster_role = local.server_pools[pool_name].cluster_role
      })
    ]
  ])

  server_pools = {
    for sp in var.server_pools : sp.name => {
      name            = sp.name
      server_type     = sp.server_type
      image           = sp.image
      count           = sp.count
      cluster_role    = sp.cluster_role
      ssh_key_name    = "k3s-cluster-ssh-key"
      cloud_init_file = "cloud-init.yaml"
      location        = sp.location
    }
  }
}

module "hcloud_server_pools" {
  for_each     = { for n in local.server_pools : n.name => n }
  source       = "../../modules/hcloud_server_pool"
  name         = each.key
  location     = each.value.location
  image        = each.value.image
  server_type  = each.value.server_type
  server_count = each.value.count
  ssh_key_id   = hcloud_ssh_key.this[each.value.ssh_key_name].id
  user_data    = file("${path.module}/files/${each.value.cloud_init_file}")
  labels = {
    "server-pool" = each.key,
    "managed-by"  = "Terraform",
    "role"        = each.value.cluster_role
  }
}

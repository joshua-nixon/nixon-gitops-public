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
      ssh_key_name    = "default-ssh-key"
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
  user_data = templatefile("${path.module}/files/${each.value.cloud_init_file}", {
    netbird_setup_key = var.netbird_setup_key
  })
  labels = {
    "k3s-server"  = "true"
    "server-pool" = each.key
    "managed-by"  = "Terraform"
    "role"        = each.value.cluster_role
  }
}

resource "hcloud_ssh_key" "this" {
  for_each   = { for k in var.ssh_keys : k.name => k }
  name       = each.value.name
  public_key = file(each.value.public_key_path)
}

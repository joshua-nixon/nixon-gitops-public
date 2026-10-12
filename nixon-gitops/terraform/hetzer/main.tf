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
      location        = sp.location
    }
  }
}

module "hcloud_server_pools" {
  for_each     = { for n in local.server_pools : n.name => n }
  source       = "git::https://github.com/joshua-nixon/terraform-modules.git//hcloud_server_pool?ref=main"
  name         = each.key
  location     = each.value.location
  image        = each.value.image
  server_type  = each.value.server_type
  server_count = each.value.count
  ssh_key_id   = module.hcloud_ssh_key.id
  labels       = { "cluster-role" = each.value.cluster_role }
  user_data    = templatefile("${path.module}/templates/cloud-init.tpl.yaml", {
    netbird_setup_key = var.netbird_setup_key
  })
}

module "hcloud_ssh_key" {
  source           = "git::https://github.com/joshua-nixon/terraform-modules.git//hcloud_ssh_key?ref=main"
  name             = "ssh-key"
  private_key_path = var.ssh_private_key_path
}

module "hcloud_firewall" {
  for_each             = { for f in var.firewalls : f.name => f }
  source               = "git::https://github.com/joshua-nixon/terraform-modules.git//hcloud_firewall?ref=main"
  name                 = each.key
  attachment_selectors = [each.value.attachment_selector]
  rules                = each.value.rules
}

output "servers" {
  value = local.created_servers
}
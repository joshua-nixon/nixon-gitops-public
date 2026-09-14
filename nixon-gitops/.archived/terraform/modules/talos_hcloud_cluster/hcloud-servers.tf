locals {
  hcloud_servers = {
    for server in var.servers : server.name => merge(
      server,
      module.hcloud_server[server.name],
    )
  }

  created_hcloud_servers = values(local.hcloud_servers)
}

resource "imager_image" "talos_x86" {
  image_url    = "https://factory.talos.dev/image/${var.talos_schematic}/${var.talos_version}/hcloud-amd64.raw.xz"
  architecture = "x86"
  server_type  = "cpx22"
  labels = {
    "version" = var.talos_version
  }
  timeouts {
    create = "15m"
  }
}

module "hcloud_server" {
  source       = "../../modules/hcloud_server"
  for_each     = { for server in var.servers : server.name => server }
  name         = each.value.name
  image        = imager_image.talos_x86.id
  server_type  = each.value.server_type
  location     = each.value.location
  firewall_ids = var.firewall_ids
  labels = {
    "talos-server"       = "true",
    "talos-cluster-name" = var.cluster_name
  }
}

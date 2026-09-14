resource "hcloud_server" "this" {
  name         = var.name
  image        = var.image
  server_type  = var.server_type
  location     = var.location
  ssh_keys     = var.ssh_key_id == null ? null : [var.ssh_key_id]
  firewall_ids = var.firewall_ids
  keep_disk    = true
  user_data    = var.user_data
  labels       = var.labels != null ? var.labels : {}

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  lifecycle {
    ignore_changes = [name, ssh_keys, user_data]
  }
}

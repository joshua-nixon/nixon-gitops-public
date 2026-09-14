resource "hcloud_ssh_key" "this" {
  for_each   = { for k in var.ssh_keys : k.name => k }
  name       = each.value.name
  public_key = file(each.value.public_key_path)
}

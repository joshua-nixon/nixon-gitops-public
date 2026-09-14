output "servers" {
  value = [
    for s in hcloud_server.servers : {
      name          = s.name
      ipv4_address  = s.ipv4_address
    }
  ]
}

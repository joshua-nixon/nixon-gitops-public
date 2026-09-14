output "private_ipv4_address" {
  value = split("/", data.external.netbird_ip.result.address)[0] # Remove /16
}

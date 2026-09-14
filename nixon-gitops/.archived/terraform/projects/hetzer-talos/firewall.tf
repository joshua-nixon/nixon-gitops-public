
data "http" "cloudflare_ipv4" {
  url = "https://www.cloudflare.com/ips-v4"
}

data "http" "cloudflare_ipv6" {
  url = "https://www.cloudflare.com/ips-v6"
}

data "http" "machine_ipv4" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  firewall_source_ips = {
    cloudflare = concat(
      compact(split("\n", data.http.cloudflare_ipv4.response_body)),
      compact(split("\n", data.http.cloudflare_ipv6.response_body))
    )
    me = concat(
      compact(split("\n", data.http.machine_ipv4.response_body))
    )

  }

  firewall_rules = flatten([
    for rule in var.hcloud_firewall_rules : [
      for group in rule.groups : {
        description = "${rule.description} (@${title(group)})"
        protocol    = rule.protocol
        port        = rule.port
        source_ips  = lookup(local.firewall_source_ips, group, [])
        group       = group
      }
    ]
  ])
}

resource "hcloud_firewall" "talos_firewall" {
  name = "talos-cluster-firewall"

  dynamic "rule" {
    for_each = local.firewall_rules
    content {
      description = rule.value.description
      direction   = "in"
      protocol    = rule.value.protocol
      port        = rule.value.port
      source_ips  = rule.value.source_ips
    }
  }
}

resource "hcloud_firewall_attachment" "fw_servers" {
  firewall_id     = hcloud_firewall.talos_firewall.id
  label_selectors = ["talos-server=true"]
}

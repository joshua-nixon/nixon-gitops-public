

/*
    The firewall is attached to all created servers to ensure that the necessary ports are open for the cluster to function properly.
    NB, we use a firewall attachment as we require the servers being created before we can attach the firewall
*/

locals {
  firewall_source_ips = {
    cloudflare = local.cloudflare_ips
    me         = local.local_ips
  }

  firewall_rules = flatten([
    for rule in var.firewall.rules : [
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

resource "hcloud_firewall" "this" {
  name = "k3s-cluster-firewall"

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
  firewall_id     = hcloud_firewall.this.id
  label_selectors = [var.firewall.label_selector]
}

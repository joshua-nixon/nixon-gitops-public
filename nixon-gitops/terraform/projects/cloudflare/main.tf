data "terraform_remote_state" "hetzer" {
  backend = "azurerm"

  config = {
    resource_group_name  = "rg-v1-tfstate"
    storage_account_name = "nixontfstatestorage"
    container_name       = "tfstate-hetzner"
    key                  = "tfstate/terraform.tfstate"
    use_azuread_auth     = true
  }
}

locals {
  server_ips = [
    for s in data.terraform_remote_state.hetzer.outputs.servers : s.ipv4_address if s.cluster_role == "controlplane"
  ]

  expanded_records = {
    for zone_name, zone in var.cloudflare_zones : zone_name => {
      id        = zone.id
      redirects = zone.redirects == null ? [] : zone.redirects
      waf_rules = zone.waf_rules == null ? [] : zone.waf_rules
      records = flatten([
        for r in zone.records : lookup(r, "content", null) != null ? [r] : [
          for ip in local.server_ips : merge(r, { content = ip })
        ]
      ])
    }
  }
}

module "cloudflare_zones" {
  for_each  = local.expanded_records
  source    = "../../modules/cloudflare_zone"
  zone_id   = each.value.id
  records   = each.value.records
  redirects = each.value.redirects
  waf_rules = each.value.waf_rules
}

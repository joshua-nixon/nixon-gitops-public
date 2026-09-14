module "talos_cluster" {
  source = "../../modules/talos_hcloud_cluster"
  servers = [
    {
      name         = "controlplane-fsn1-cx33"
      location     = "fsn1"
      server_type  = "cx33"
      machine_type = "controlplane"
      bootstrap    = true
    }
  ]
  cluster_name      = "talos-cluster"
  netbird_setup_key = var.netbird_setup_key
  issuer_url        = var.cluster_issuer_url
  talos_version     = "v1.13.10"
  firewall_ids      = [hcloud_firewall.talos_firewall.id]
  talosconfig_path  = "../../../.config/talosconfig"
  kubeconfig_path   = "../../../.config/kubeconfig"
  talos_schematic   = "7326f0cbca7a0e700ac1efa3f32e88df9ebe5010e6e842a8ed36fdc99ee98ead"
}

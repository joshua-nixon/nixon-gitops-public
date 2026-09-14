resource "local_file" "talosconfig" {
  content  = data.talos_client_configuration.this.talos_config
  filename = var.talosconfig_path
}

resource "local_file" "kubeconfig" {
  content = replace(
    talos_cluster_kubeconfig.this.kubeconfig_raw,
    local.talos_cluster_endpoint,
    local.talos_cluster_private_ipv4
  )
  filename = var.kubeconfig_path
}

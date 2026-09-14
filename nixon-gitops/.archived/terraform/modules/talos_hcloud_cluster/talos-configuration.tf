
resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [local.talos_cluster_endpoint]
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [module.talos_server]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.talos_cluster_endpoint
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${local.talos_cluster_endpoint}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
  config_patches = concat(
    [
      templatefile("${path.module}/templates/netbird.yaml.tftpl", {
        setup_key = var.netbird_setup_key
      }),
      file("${path.module}/templates/controlplane.yaml")
    ],
    var.issuer_url == null || var.issuer_url == "" ? [] : [
      templatefile("${path.module}/templates/controlplane-issuer.yaml.tftpl", {
        ISSUER_URL = var.issuer_url
      })
    ]
  )
}

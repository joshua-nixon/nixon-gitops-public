locals {
  node_ipv4_address = var.public_ipv4_address
}

resource "talos_machine_configuration_apply" "this" {
  client_configuration        = var.machine_secrets.client_configuration
  machine_configuration_input = var.machine_configuration.machine_configuration
  node                        = local.node_ipv4_address
}

# -----------------------------------------------------------------

data "external" "netbird_ip" {
  depends_on = [
    talos_machine_configuration_apply.this
  ]

  query = {
    talosconfig = var.client_configuration.talos_config
    node_ip     = local.node_ipv4_address
  }

  program = [
    "bash",
    "-c",
    <<-EOT
      eval "$(jq -r '@sh "TALOS_CONFIG_DATA=\(.talosconfig) NODE_IP=\(.node_ip)"')"

      IP=""
      for i in {1..24}; do
        IP=$(talosctl -n "$NODE_IP" --talosconfig <(echo "$TALOS_CONFIG_DATA") get addresses -o json 2>/dev/null \
          | jq -r 'select(.spec.linkName=="wt0") | .spec.address' | head -n 1)

        if [ -n "$IP" ] && [ "$IP" != "null" ]; then
          break
        fi
        sleep 5
      done

      jq -n --arg ip "$IP" '{"address": $ip}'
    EOT
  ]
}

# -----------------------------------------------------------------

resource "talos_machine_bootstrap" "this" {
  count                = var.bootstrap ? 1 : 0
  depends_on           = [talos_machine_configuration_apply.this]
  client_configuration = var.machine_secrets.client_configuration
  node                 = local.node_ipv4_address
}

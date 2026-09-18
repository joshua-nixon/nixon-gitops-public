resource "time_static" "updated_at" {
  triggers = var.update_change_triggers
}


output "all_tags" {
  value = {
    "managed-by" = "terraform",
    "updated-at" = time_static.updated_at.rfc3339
  }
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_zones" {
  type = map(
    object({
      id = string
      redirects = optional(list(
        object({
          request_url           = string
          target_url            = string
          status_code           = number
          preserve_query_string = bool
          description           = string
        })
      ))
      waf_rules = optional(list(
        object({
          expression        = string
          description       = string
        })
      ))
      records = list(
        object({
          type    = string
          name    = string
          proxied = bool
          content = optional(string)
        })
      )
    })
  )
}

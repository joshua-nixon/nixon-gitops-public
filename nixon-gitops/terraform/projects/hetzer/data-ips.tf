
/*
  Fetch Cloudflare's IP ranges to allowlist them in firewall rules for HTTP/HTTPS traffic, 
  ensuring that legitimate traffic from Cloudflare's network is not blocked.
  Our IP is also added to the allowlist.
*/

data "http" "machine_ipv4" {
  url = "https://ipv4.icanhazip.com"
}

data "http" "cloudflare_ipv4" {
  url = "https://www.cloudflare.com/ips-v4"
}

data "http" "cloudflare_ipv6" {
  url = "https://www.cloudflare.com/ips-v6"
}

locals {
  local_ips = concat(
    compact(split("\n", data.http.machine_ipv4.response_body))
  )

  cloudflare_ips = concat(
    compact(split("\n", data.http.cloudflare_ipv4.response_body)),
    compact(split("\n", data.http.cloudflare_ipv6.response_body))
  )
}

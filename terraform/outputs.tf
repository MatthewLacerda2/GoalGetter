output "tunnel_token" {
  description = "Tunnel token to use with cloudflared (add this to .env as CLOUDFLARE_TUNNEL_TOKEN)"
  value       = cloudflare_tunnel.goalgetter_tunnel.tunnel_token
  sensitive   = true
}

output "tunnel_id" {
  description = "Cloudflare Tunnel ID"
  value       = cloudflare_tunnel.goalgetter_tunnel.id
}

output "tunnel_name" {
  description = "Cloudflare Tunnel name"
  value       = cloudflare_tunnel.goalgetter_tunnel.name
}

output "dns_record" {
  description = "DNS record details"
  value = {
    name    = cloudflare_record.tunnel_dns.name
    value   = cloudflare_record.tunnel_dns.value
    proxied = cloudflare_record.tunnel_dns.proxied
  }
}

output "domain_fqdn" {
  description = "Full domain name (FQDN) that will be used"
  value       = var.subdomain == "@" ? var.domain : "${var.subdomain}.${var.domain}"
}

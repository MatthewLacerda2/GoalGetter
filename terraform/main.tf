terraform {
  required_version = ">= 1.0"
  
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Create a Cloudflare Tunnel
resource "cloudflare_tunnel" "goalgetter_tunnel" {
  account_id = var.cloudflare_account_id
  name       = var.tunnel_name
}

# Create tunnel configuration (route)
resource "cloudflare_tunnel_config" "goalgetter_tunnel_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_tunnel.goalgetter_tunnel.id

  config {
    ingress_rule {
      hostname = var.subdomain == "@" ? var.domain : "${var.subdomain}.${var.domain}"
      service  = "http://frontend:80"
    }

    # Catch-all rule - must be last
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# Create DNS CNAME record pointing to the tunnel
resource "cloudflare_record" "tunnel_dns" {
  zone_id = data.cloudflare_zone.domain.id
  name    = var.subdomain == "@" ? var.domain : var.subdomain
  value   = "${cloudflare_tunnel.goalgetter_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  comment = "Cloudflare Tunnel for GoalGetter"
}

# Get the zone ID for the domain
data "cloudflare_zone" "domain" {
  name = var.domain
}

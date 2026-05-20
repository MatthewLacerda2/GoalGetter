variable "cloudflare_api_token" {
  description = "Cloudflare API token with permissions to create tunnels and manage DNS"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "Domain name (e.g., example.com)"
  type        = string
}

variable "subdomain" {
  description = "Subdomain to use (use '@' for root domain, or 'app' for app.example.com)"
  type        = string
  default     = "@"
}

variable "tunnel_name" {
  description = "Name for the Cloudflare Tunnel"
  type        = string
  default     = "goalgetter-tunnel"
}

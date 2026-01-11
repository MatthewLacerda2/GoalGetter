# Cloudflare Tunnel Terraform Configuration

This Terraform configuration sets up a Cloudflare Tunnel for GoalGetter, creating the tunnel resource, DNS records, and tunnel routing configuration.

## Prerequisites

1. **Cloudflare Account** - You need a Cloudflare account
2. **Domain Added to Cloudflare FIRST** - Your domain must be added to Cloudflare BEFORE running Terraform (this is the "onboarding" step):
   - Go to [Cloudflare Dashboard](https://dash.cloudflare.com/) → "Add a Site"
   - Enter your domain name
   - Cloudflare will provide nameservers (you'll point your domain to these later at your registrar)
   - **Important**: The domain must exist in your Cloudflare account before Terraform can manage it. Terraform will fail if the domain isn't already added to Cloudflare.
3. **Cloudflare API Token** - Create an API token with the following permissions:
   - Account: Cloudflare Tunnel: Edit
   - Zone: Zone: Read, DNS: Edit
4. **Account ID** - Found in Cloudflare dashboard (right sidebar on overview page)

## Getting Your Cloudflare API Token

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Use "Edit Cloudflare Tunnel" template or create custom token with:
   - Account: Cloudflare Tunnel: Edit
   - Zone: Zone: Read, DNS: Edit
4. Copy the token (you won't see it again!)

## Getting Your Account ID

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Select any domain
3. Scroll down to the right sidebar
4. Copy your "Account ID"

## Setup Instructions

1. **Create `terraform.tfvars` file** (this file is gitignored):

   ```hcl
   cloudflare_api_token = "your-api-token-here"
   cloudflare_account_id = "your-account-id-here"
   domain = "yourdomain.com"
   subdomain = "@"  # Use "@" for root domain, or "app" for app.yourdomain.com
   tunnel_name = "goalgetter-tunnel"  # Optional, defaults to this
   ```

2. **Initialize Terraform**:

   ```bash
   cd terraform
   terraform init
   ```

3. **Review the plan**:

   ```bash
   terraform plan
   ```

4. **Apply the configuration**:

   ```bash
   terraform apply
   ```

5. **Get the tunnel token**:
   After applying, Terraform will output the tunnel token. Copy it:

   ```bash
   terraform output -raw tunnel_token
   ```

   Or check the outputs:

   ```bash
   terraform output
   ```

6. **Add token to .env file**:
   Add the tunnel token to your `.env` file:

   ```
   CLOUDFLARE_TUNNEL_TOKEN=<token-from-terraform-output>
   ```

7. **Point nameservers to Cloudflare** (Manual step):

   - Go to your domain registrar
   - Update nameservers to the ones provided by Cloudflare
   - Cloudflare shows you the nameservers when you add the domain (in Prerequisites step 2)
   - This step is done outside of Terraform
   - DNS propagation can take up to 48 hours (usually much faster)

8. **Start your services** (After DNS propagates):
   - Run `docker-compose up -d` to start all services including cloudflared
   - The cloudflared container will connect to Cloudflare using the tunnel token
   - Your domain should now be accessible via the internet!

## How It Works

**Architecture:**

```
Internet → Cloudflare DNS → Cloudflare Tunnel → cloudflared (your machine) → frontend:80 (nginx)
```

**What Terraform Does:**

- Creates a Cloudflare Tunnel resource in your Cloudflare account
- Creates DNS records (CNAME) pointing your domain to the tunnel
- Configures tunnel routing rules (domain → your local service)
- Outputs a tunnel token for the cloudflared container

**What Runs Locally:**

- The `cloudflared` Docker container runs on **your local machine** (via docker-compose)
- It establishes an **outbound connection** to Cloudflare (no need to open firewall ports)
- The tunnel connects your local `frontend:80` service to Cloudflare's network
- Traffic flows: Internet → Cloudflare → Tunnel → Your local Docker container → nginx

**Benefits:**

- No need to open ports on your router/firewall (outbound-only connection)
- Cloudflare provides DDoS protection and SSL/TLS termination
- Traffic is encrypted through the tunnel
- Your services remain on localhost (not directly exposed to the internet)
- Perfect for home servers without static IPs or port forwarding

## Tunnel Configuration

The tunnel is configured to:

- Route traffic from your domain to the `frontend` service on port 80 (via Docker network)
- Use Cloudflare's proxy (orange cloud) for DDoS protection and SSL/TLS
- The cloudflared container runs on your local machine and connects to Cloudflare

## Updating Configuration

To update the tunnel configuration:

1. Modify the Terraform files as needed
2. Run `terraform plan` to see changes
3. Run `terraform apply` to apply changes

## Destroying Resources

To remove all created resources:

```bash
terraform destroy
```

**Warning**: This will delete the tunnel and DNS records. Make sure you want to do this!

## Troubleshooting

### Tunnel token not working

- Make sure you copied the entire token (it's very long)
- Check that the token is in your `.env` file as `CLOUDFLARE_TUNNEL_TOKEN`
- Verify the cloudflared container can access the token
- Check cloudflared logs: `docker logs goalgetter_cloudflared`

### DNS not resolving

- Check that nameservers are pointed to Cloudflare at your registrar
- Verify DNS propagation with `dig yourdomain.com` or online tools
- Check Cloudflare dashboard to see if the CNAME record exists
- Wait for DNS propagation (can take up to 48 hours, usually much faster)

### Tunnel connection issues

- Check cloudflared container logs: `docker logs goalgetter_cloudflared`
- Verify frontend service is running: `docker ps`
- Ensure tunnel token is correct and not expired
- Verify cloudflared container is on the same Docker network as frontend

### Domain not found error in Terraform

- Make sure you added the domain to Cloudflare FIRST (see Prerequisites step 2)
- Verify the domain exists in your Cloudflare account
- Check that you're using the correct domain name in `terraform.tfvars`

## Notes

- The tunnel token is sensitive - keep it secret
- DNS changes can take up to 48 hours to propagate (usually much faster)
- Cloudflare provides free SSL/TLS certificates automatically
- The tunnel uses Cloudflare's network for DDoS protection
- The cloudflared container must run continuously for the tunnel to work
- All traffic flows through Cloudflare's network (they can see it, but it's encrypted)

# =============================================================================
# DNS ZONE OUTPUTS
# =============================================================================
# These outputs provide important information about the created DNS zone
# that will be needed for domain delegation and verification.
# =============================================================================

output "name_servers" {
  description = "The Google Cloud DNS name servers for this zone. These name servers must be configured in your domain registrar (e.g., Cloudflare, GoDaddy) as NS records for the subdomain to delegate DNS authority to Google Cloud DNS. Without this delegation, the BTP platform will not be accessible via the custom domain."
  
  # This output will contain a list of name servers like:
  # [
  #   "ns-cloud-a1.googledomains.com.",
  #   "ns-cloud-a2.googledomains.com.",
  #   "ns-cloud-a3.googledomains.com.",
  #   "ns-cloud-a4.googledomains.com."
  # ]
  value = module.gcp_dns_zone.name_servers
  
  # IMPORTANT: After terraform apply completes, use these name servers to:
  # 1. Create NS records in your domain registrar's DNS settings
  # 2. Point your subdomain (e.g., btp.example.com) to these name servers
  # 3. Wait for DNS propagation (can take up to 48 hours, usually much faster)
  # 4. Verify delegation using: dig NS your-subdomain.com
}
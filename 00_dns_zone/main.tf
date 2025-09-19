# =============================================================================
# DNS ZONE CONFIGURATION
# =============================================================================
# This module creates a Google Cloud DNS zone that will be used to manage
# DNS records for the SettleMint Blockchain Transformation Platform (BTP).
# The DNS zone is essential for:
# - Providing public access to the BTP platform via a custom domain
# - Enabling SSL certificate provisioning through Let's Encrypt
# - Supporting wildcard subdomains for various BTP services
# =============================================================================

module "gcp_dns_zone" {
  # Using the official Google Cloud DNS Terraform module
  # This module simplifies the creation and management of Cloud DNS zones
  source  = "terraform-google-modules/cloud-dns/google"
  version = "5.3.0"

  # The GCP project where the DNS zone will be created
  project_id = var.gcp_project_id
  
  # Type of DNS zone - "public" means it's accessible from the internet
  # This is required for external access to the BTP platform
  type       = "public"
  
  # Name of the DNS zone resource in GCP (used internally by GCP)
  # This will be used to reference the zone in other resources
  name       = var.gcp_platform_name
  
  # The actual domain name for the DNS zone
  # The trailing dot is required by DNS standards to indicate a fully qualified domain name
  # Example: if gcp_dns_zone is "btp.example.com", this becomes "btp.example.com."
  domain     = "${var.gcp_dns_zone}."
}

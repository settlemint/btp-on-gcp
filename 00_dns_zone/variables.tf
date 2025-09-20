# ============================================================================
# DNS ZONE MODULE VARIABLES
# ============================================================================
# 
# This file defines the input variables required for the DNS zone module.
# These variables must be configured by DevOps teams and Enterprise Architects
# to customize the DNS infrastructure for their specific BTP deployment.
# 
# VARIABLE CONFIGURATION GUIDE:
# 
# 1. REQUIRED VARIABLES (must be provided):
#    - gcp_project_id: GCP project where DNS zone will be created
#    - gcp_dns_zone: The domain name for the BTP platform
# 
# 2. OPTIONAL VARIABLES (have sensible defaults):
#    - gcp_platform_name: Identifier for the BTP instance
#    - gcp_region: GCP region for regional resources
# 
# ENTERPRISE DEPLOYMENT CONSIDERATIONS:
# - Use descriptive platform names for multi-environment deployments
# - Choose regions based on data residency and latency requirements
# - Ensure domain names follow organizational naming conventions
# - Consider DNS propagation time when planning deployments
# 
# ============================================================================

# Google Cloud Project Configuration
# The GCP project ID where the DNS zone and all related resources will be created.
# This project must have the Cloud DNS API enabled and the Terraform service
# account must have dns.admin permissions.
# 
# REQUIREMENTS:
# - Must be a valid GCP project ID (not project name or number)
# - Cloud DNS API must be enabled
# - Billing must be enabled on the project
# - Service account must have dns.admin role
# 
# EXAMPLE: "my-company-btp-production"
variable "gcp_project_id" {
  type        = string
  description = "The Google Cloud Platform project ID where DNS zone will be created"
  nullable    = false
  
  validation {
    condition     = length(var.gcp_project_id) > 0
    error_message = "GCP project ID cannot be empty. Provide a valid GCP project ID."
  }
}

# Platform Instance Identifier
# A unique name identifier for this BTP platform instance. This name is used
# across multiple resources including DNS zones, Kubernetes clusters, and
# service accounts to maintain consistency and avoid naming conflicts.
# 
# NAMING CONVENTIONS:
# - Use lowercase letters, numbers, and hyphens only
# - Should be descriptive of the environment (e.g., "btp-prod", "btp-dev")
# - Maximum 63 characters (GCP resource name limit)
# - Must start and end with alphanumeric character
# 
# USAGE ACROSS INFRASTRUCTURE:
# - DNS zone name: Used as the zone identifier in GCP
# - Kubernetes cluster name: Combined with suffix for uniqueness
# - Service account prefixes: Used in workload identity configurations
# - Resource tagging: Applied to all created resources for organization
variable "gcp_platform_name" {
  type        = string
  description = "Unique identifier for this BTP platform instance (used for DNS zone, cluster, and resource naming)"
  default     = "btp"
  
  validation {
    condition = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.gcp_platform_name)) && length(var.gcp_platform_name) <= 63
    error_message = "Platform name must be lowercase, contain only letters, numbers, and hyphens, start and end with alphanumeric character, and be max 63 characters."
  }
}

# Google Cloud Region Selection
# The GCP region where regional resources will be created. While DNS zones
# are global resources, this region setting is used for consistency with
# the infrastructure module and for any regional dependencies.
# 
# REGION SELECTION CRITERIA:
# - Data residency requirements and compliance regulations
# - Latency considerations for end users and blockchain networks
# - Service availability and feature support in the region
# - Cost optimization based on regional pricing differences
# 
# POPULAR REGIONS FOR ENTERPRISE DEPLOYMENTS:
# - europe-west1 (Belgium): GDPR compliant, low latency for EU users
# - us-central1 (Iowa): Cost-effective, good for North American users
# - asia-southeast1 (Singapore): Optimal for APAC region
# - us-east1 (South Carolina): Extensive service availability
# 
# NOTE: Ensure chosen region supports all required GCP services including
# GKE, Cloud DNS, KMS, and any blockchain-specific services.
variable "gcp_region" {
  type        = string
  description = "GCP region for regional resources (affects latency, compliance, and costs)"
  default     = "europe-west1"
  
  validation {
    condition = can(regex("^[a-z]+-[a-z0-9]+-[0-9]+$", var.gcp_region))
    error_message = "GCP region must be in format like 'europe-west1' or 'us-central1'."
  }
}

# DNS Domain Configuration
# The fully qualified domain name (FQDN) that will serve as the base domain
# for all BTP platform services. This domain must be registered and owned
# by your organization.
# 
# DOMAIN REQUIREMENTS:
# - Must be a valid, registered domain name
# - Organization must control DNS nameserver delegation
# - Should not include protocol (http/https) or trailing dot
# - Subdomains will be automatically created under this domain
# 
# POST-DEPLOYMENT CONFIGURATION:
# After Terraform creates the DNS zone, you must:
# 1. Note the nameservers from the Terraform output
# 2. Update your domain registrar to use these nameservers
# 3. Wait for DNS propagation (up to 48 hours)
# 4. Verify DNS resolution before deploying applications
# 
# SUBDOMAIN STRUCTURE:
# The BTP platform will create various subdomains:
# - Platform services: app.yourdomain.com
# - API endpoints: api.yourdomain.com
# - Blockchain nodes: ethereum.yourdomain.com
# - Monitoring: grafana.yourdomain.com
# 
# SECURITY IMPLICATIONS:
# - Domain will be publicly resolvable
# - SSL certificates will be automatically provisioned
# - Consider using dedicated domains for different environments
# 
# EXAMPLE: "blockchain.mycompany.com"
variable "gcp_dns_zone" {
  type        = string
  description = "Fully qualified domain name for the BTP platform (must be owned and registered by your organization)"
  nullable    = false
  
  validation {
    condition = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\\.[a-zA-Z]{2,}$", var.gcp_dns_zone)) && length(var.gcp_dns_zone) > 0
    error_message = "DNS zone must be a valid domain name (e.g., 'blockchain.mycompany.com') without protocol or trailing dot."
  }
}

# =============================================================================
# DNS ZONE VARIABLES
# =============================================================================
# These variables define the configuration parameters for the DNS zone setup.
# They must be provided when running terraform apply or set as environment
# variables with the TF_VAR_ prefix.
# =============================================================================

variable "gcp_project_id" {
  type        = string
  description = "The Google Cloud Platform project ID where the DNS zone will be created. This should be a valid GCP project ID that you have permissions to manage DNS resources in."
  nullable    = false
  
  # Example: "my-btp-project-123456"
  # This project must have the Cloud DNS API enabled
}

variable "gcp_platform_name" {
  type        = string
  description = "The name used for the DNS zone resource in GCP. This is an internal identifier and will be used as the zone name in the Google Cloud Console."
  default     = "btp"
  
  # This name must be unique within your GCP project
  # It will appear in the Cloud DNS console as the zone name
}

variable "gcp_region" {
  type        = string
  description = "The GCP region where related resources will be created. While DNS zones are global, this region is used for consistency with other infrastructure components."
  default     = "europe-west1"
  
  # Common regions:
  # - "us-central1" (Iowa, USA)
  # - "europe-west1" (Belgium, Europe)
  # - "asia-east1" (Taiwan, Asia)
}

variable "gcp_dns_zone" {
  type        = string
  description = "The public DNS zone (domain/subdomain) that will be used to access the BTP platform. This should be a domain or subdomain that you control and can delegate to Google Cloud DNS."
  nullable    = false
  
  # Examples:
  # - "btp.example.com" (subdomain)
  # - "blockchain.mycompany.com" (subdomain)
  # 
  # IMPORTANT: You must own the parent domain and be able to create NS records
  # pointing to Google Cloud DNS nameservers for this subdomain to work
}

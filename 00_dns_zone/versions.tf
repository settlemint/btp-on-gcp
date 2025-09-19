# =============================================================================
# TERRAFORM VERSION CONSTRAINTS - DNS ZONE
# =============================================================================
# This file defines the minimum Terraform version and required provider
# versions for the DNS zone configuration. Version constraints ensure
# compatibility and prevent issues with provider API changes.
# =============================================================================

terraform {
  # Required provider configurations
  required_providers {
    # Google Cloud Platform provider for DNS zone management
    google = {
      source = "hashicorp/google"
      # No version constraint - uses latest compatible version
      # In production, consider pinning to specific version: version = "~> 5.0"
    }
  }
  
  # Minimum Terraform version required
  # This version is tested and known to work with the configuration
  required_version = "1.12.2"
  
  # Note: This configuration is kept minimal for the DNS zone setup
  # The main infrastructure configuration has more detailed version constraints
}

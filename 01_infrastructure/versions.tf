# =============================================================================
# TERRAFORM VERSION CONSTRAINTS - MAIN INFRASTRUCTURE
# =============================================================================
# This file defines the minimum Terraform version and required provider
# versions for the main BTP infrastructure deployment. Version constraints
# ensure compatibility and reproducible deployments across environments.
# =============================================================================

terraform {
  # Required provider configurations with version constraints
  required_providers {
    # Google Cloud Platform provider for GKE, KMS, DNS, and IAM
    google = {
      source = "hashicorp/google"
      # No version constraint - uses latest compatible version
      # Recommended for production: version = "~> 5.0"
    }
    
    # Kubernetes provider for native Kubernetes resources
    kubernetes = {
      source = "hashicorp/kubernetes"
      # No version constraint - uses latest compatible version
      # Recommended for production: version = "~> 2.20"
    }
    
    # kubectl provider for advanced Kubernetes operations and CRDs
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"  # Pinned version for stability with cert-manager CRDs
    }
    
    # Additional providers used implicitly:
    # - hashicorp/helm (configured in providers.tf)
    # - hashicorp/random (configured in providers.tf)
    # - hashicorp/local (configured in providers.tf)
  }
  
  # Minimum Terraform version required
  # This version supports all features used in the configuration
  required_version = "1.12.2"
  
  # Version compatibility notes:
  # - Terraform 1.12.2+ required for enhanced provider authentication
  # - kubectl provider 2.1.3 tested with cert-manager v1.18.2
  # - Configuration tested with Google provider 5.x series
}

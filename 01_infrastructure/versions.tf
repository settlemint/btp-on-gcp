# ============================================================================
# INFRASTRUCTURE MODULE - TERRAFORM VERSION AND PROVIDER REQUIREMENTS
# ============================================================================
# 
# This file defines the Terraform version and provider requirements for the
# complete BTP infrastructure module. This module orchestrates the deployment
# of a production-ready Kubernetes environment with all necessary supporting
# services for SettleMint's Blockchain Transformation Platform.
# 
# PROVIDER ECOSYSTEM OVERVIEW:
# The infrastructure module requires multiple providers to manage the complex
# ecosystem of cloud resources, Kubernetes deployments, and configuration:
# 
# 1. GOOGLE CLOUD PROVIDER: Core GCP infrastructure management
# 2. KUBERNETES PROVIDER: Kubernetes resource management  
# 3. KUBECTL PROVIDER: Advanced Kubernetes operations
# 4. HELM PROVIDER: Application deployment via Helm charts
# 5. RANDOM PROVIDER: Secure random value generation
# 6. LOCAL PROVIDER: Local file and template processing
# 
# ENTERPRISE DEPLOYMENT REQUIREMENTS:
# 
# VERSION CONSISTENCY:
# - All team members must use identical Terraform version (1.12.2)
# - Provider versions should be pinned for production stability
# - CI/CD pipelines must enforce version constraints
# - Version upgrades require coordinated testing across environments
# 
# SECURITY CONSIDERATIONS:
# - Regularly audit provider versions for security vulnerabilities
# - Implement automated scanning for outdated dependencies
# - Maintain security patch procedures for critical updates
# - Document security implications of version changes
# 
# OPERATIONAL REQUIREMENTS:
# - Validate provider compatibility before version changes
# - Test infrastructure changes in isolated environments
# - Maintain rollback procedures for version downgrades
# - Document provider-specific configuration requirements
# 
# ============================================================================

# Terraform Configuration Block
# Defines the exact Terraform version and all required providers for the
# BTP infrastructure module. This configuration ensures reproducible
# deployments across all environments and prevents compatibility issues.
terraform {
  # Required Provider Configurations
  # Each provider is configured with specific version constraints and sources
  # to ensure stable, predictable infrastructure deployments.
  required_providers {
    # Google Cloud Platform Provider
    # Primary provider for managing GCP infrastructure including GKE clusters,
    # DNS zones, IAM policies, KMS keys, and all other Google Cloud resources.
    # 
    # MANAGED RESOURCES:
    # - Google Kubernetes Engine (GKE) clusters and node pools
    # - Cloud DNS zones and DNS records  
    # - Identity and Access Management (IAM) policies and service accounts
    # - Key Management Service (KMS) encryption keys and key rings
    # - Compute Engine networks, subnets, and firewall rules
    # - Cloud Storage buckets and object lifecycle policies
    # 
    # VERSION STRATEGY:
    # - No version constraint allows automatic updates to latest stable version
    # - Consider pinning to major version (e.g., "~> 6.0") for production
    # - Monitor Google Cloud provider releases for new features and fixes
    google = {
      source = "hashicorp/google"
      # version = "~> 6.0"  # Uncomment for production version pinning
    }

    # Kubernetes Provider
    # Manages native Kubernetes resources including namespaces, services,
    # deployments, config maps, secrets, and RBAC configurations.
    # 
    # MANAGED RESOURCES:
    # - Kubernetes namespaces for logical resource separation
    # - Service accounts and role-based access control (RBAC)
    # - Config maps and secrets for application configuration
    # - Services, ingress rules, and network policies
    # - Jobs and cron jobs for operational tasks
    # 
    # AUTHENTICATION:
    # - Uses Google Cloud authentication tokens for GKE cluster access
    # - Automatically configured via GKE module outputs
    # - Supports workload identity for secure pod-to-GCP communication
    kubernetes = {
      source = "hashicorp/kubernetes"
      # version = "~> 2.35"  # Uncomment for production version pinning
    }

    # Kubectl Provider (Community)
    # Provides advanced Kubernetes operations not available in the standard
    # Kubernetes provider, including raw YAML manifest application and
    # complex resource management scenarios.
    # 
    # USAGE SCENARIOS:
    # - Applying raw YAML manifests (CRDs, complex configurations)
    # - Managing resources that require kubectl-specific operations
    # - Handling Kubernetes resources with complex dependencies
    # - Applying manifests that need server-side validation
    # 
    # VERSION PINNING:
    # - Exact version (2.1.3) ensures consistent kubectl functionality
    # - Community provider requires careful version management
    # - Test thoroughly before upgrading to newer versions
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }

    # Additional providers are configured in providers.tf:
    # - helm: Application deployment via Helm charts
    # - random: Secure password and key generation  
    # - local: Template processing and file operations
  }
  
  # Terraform Version Requirement
  # Specifies the exact Terraform version (1.12.2) required for this module.
  # Exact versioning ensures maximum reproducibility and prevents issues
  # from Terraform version differences across development teams and environments.
  # 
  # ENTERPRISE RATIONALE:
  # - Eliminates "works on my machine" deployment issues
  # - Ensures consistent state file format and compatibility
  # - Prevents breaking changes from Terraform updates
  # - Facilitates precise bug reproduction and resolution
  # 
  # UPGRADE STRATEGY:
  # - Test new Terraform versions in development environments first
  # - Review Terraform changelog for breaking changes and new features
  # - Update all team environments simultaneously to maintain consistency
  # - Validate all infrastructure operations after version upgrades
  required_version = "1.14.4"

}

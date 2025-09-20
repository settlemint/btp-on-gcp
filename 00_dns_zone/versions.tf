# ============================================================================
# TERRAFORM VERSION AND PROVIDER REQUIREMENTS
# ============================================================================
# 
# This file defines the minimum Terraform version and required providers for
# the DNS zone module. Version constraints ensure compatibility and prevent
# issues from provider API changes or deprecated features.
# 
# TERRAFORM VERSION STRATEGY:
# - Uses exact version pinning (1.12.2) for maximum reproducibility
# - Ensures consistent behavior across development, staging, and production
# - Prevents unexpected breaking changes from Terraform updates
# - Facilitates precise environment replication for troubleshooting
# 
# PROVIDER REQUIREMENTS:
# - Google Cloud Provider: Manages GCP resources (DNS zones, IAM, etc.)
# - Version constraints ensure API compatibility and feature availability
# 
# ENTERPRISE DEPLOYMENT CONSIDERATIONS:
# 
# 1. VERSION MANAGEMENT:
#    - Pin exact versions in production environments
#    - Test version upgrades in non-production environments first
#    - Maintain version consistency across team members
#    - Document version upgrade procedures and testing results
# 
# 2. SECURITY AND COMPLIANCE:
#    - Regularly review provider versions for security updates
#    - Validate provider versions against security scanning tools
#    - Consider using Terraform version managers (tfenv, tfswitch)
#    - Implement automated version checking in CI/CD pipelines
# 
# 3. OPERATIONAL REQUIREMENTS:
#    - Ensure all team members use the same Terraform version
#    - Configure CI/CD systems to use the specified version
#    - Document version requirements in deployment procedures
#    - Plan for version upgrades and compatibility testing
# 
# VERSION UPGRADE PROCESS:
# When upgrading Terraform or provider versions:
# 1. Test in development environment first
# 2. Review provider changelog for breaking changes
# 3. Update version constraints gradually
# 4. Validate all resources after upgrade
# 5. Update documentation and team procedures
# 
# ============================================================================

# Terraform Configuration Block
# Specifies the minimum Terraform version and required providers for this module.
# These constraints ensure reproducible deployments and prevent compatibility issues.
terraform {
  # Required Terraform Providers
  # Lists all providers needed for this module with their sources and version constraints
  required_providers {
    # Google Cloud Provider
    # Manages Google Cloud Platform resources including DNS zones, IAM roles,
    # and service accounts. This provider is essential for all GCP operations.
    # 
    # PROVIDER CAPABILITIES:
    # - DNS zone creation and management
    # - IAM policy and service account management  
    # - Resource lifecycle management
    # - State management and drift detection
    # 
    # VERSION CONSIDERATIONS:
    # - No version constraint allows automatic updates to latest version
    # - Consider pinning to specific version for production stability
    # - Monitor provider releases for new features and security fixes
    # - Test provider updates in non-production environments first
    google = {
      source = "hashicorp/google"
      # version = "~> 6.0"  # Uncomment to pin to major version 6.x
    }
  }
  
  # Minimum Terraform Version
  # Specifies the exact Terraform version required for this module.
  # Using exact version (=1.12.2) ensures maximum reproducibility and
  # prevents issues from Terraform version differences across environments.
  # 
  # RATIONALE FOR EXACT VERSIONING:
  # - Ensures identical behavior across all environments
  # - Prevents state file compatibility issues
  # - Eliminates version-related deployment failures
  # - Facilitates precise bug reproduction and troubleshooting
  # 
  # UPGRADE CONSIDERATIONS:
  # - Test new versions thoroughly before updating
  # - Review Terraform changelog for breaking changes
  # - Update all environments simultaneously to maintain consistency
  # - Consider using version ranges (~> 1.12.0) for patch updates only
  required_version = "1.12.2"

}

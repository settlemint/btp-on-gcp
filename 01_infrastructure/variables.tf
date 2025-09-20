# ============================================================================
# INFRASTRUCTURE MODULE VARIABLES
# ============================================================================
# 
# This file defines all input variables required for the BTP infrastructure
# module. These variables enable customization of the deployment for different
# environments, organizations, and use cases while maintaining security and
# operational best practices.
# 
# VARIABLE CATEGORIES:
# 1. SETTLEMINT PLATFORM: BTP version and registry access
# 2. GOOGLE CLOUD PLATFORM: Project, region, and service configuration
# 3. KUBERNETES NAMESPACES: Logical separation and organization
# 4. WORKLOAD IDENTITY: Secure GCP-to-Kubernetes authentication
# 5. OAUTH CONFIGURATION: Google Cloud OAuth for user authentication
# 6. KEY MANAGEMENT: KMS configuration for Vault encryption
# 
# ENTERPRISE CONFIGURATION GUIDE:
# - Required variables must be provided via terraform.tfvars or environment
# - Sensitive variables should use secure storage (Vault, Secret Manager)
# - Default values are optimized for production deployments
# - Validation rules ensure configuration correctness and security
# 
# ============================================================================

# ============================================================================
# SETTLEMINT PLATFORM CONFIGURATION
# ============================================================================

# SettleMint OCI Registry Username
# Username for accessing SettleMint's private OCI registry containing
# proprietary BTP platform Helm charts and container images.
# 
# SECURITY REQUIREMENTS:
# - Must be provided by SettleMint as part of platform licensing
# - Should be stored securely and not committed to version control
# - Required for accessing private BTP platform components
# - Validate credentials before deployment to prevent authentication failures
# 
# OPERATIONAL CONSIDERATIONS:
# - Credentials may have expiration dates requiring periodic updates
# - Different credentials may be used for different environments
# - Monitor registry access logs for security and compliance
# - Implement credential rotation procedures for security
variable "oci_registry_username" {
  type        = string
  description = "Username for SettleMint's private OCI registry (required for BTP platform access)"
  nullable    = false
  
  validation {
    condition     = length(var.oci_registry_username) > 0
    error_message = "OCI registry username cannot be empty. Contact SettleMint for valid credentials."
  }
}

# SettleMint OCI Registry Password
# Password or access token for SettleMint's private OCI registry.
# This credential enables download of proprietary BTP platform components.
# 
# SECURITY BEST PRACTICES:
# - Marked as sensitive to prevent exposure in logs and console output
# - Store in secure credential management systems (Vault, Secret Manager)
# - Rotate regularly according to security policies
# - Use environment variables or secure CI/CD variable storage
# 
# ACCESS CONTROL:
# - Required for Helm provider to authenticate with SettleMint registry
# - Enables download of BTP platform charts and container images
# - Provides access to platform updates and security patches
# - Essential for complete BTP platform deployment
variable "oci_registry_password" {
  type        = string
  description = "Password/token for SettleMint's private OCI registry (store securely)"
  nullable    = false
  sensitive   = true
  
  validation {
    condition     = length(var.oci_registry_password) > 0
    error_message = "OCI registry password cannot be empty. Contact SettleMint for valid credentials."
  }
}

# BTP Platform Version
# Specifies the version of SettleMint's Blockchain Transformation Platform
# to deploy. Version pinning ensures reproducible deployments and controlled
# platform updates across environments.
# 
# VERSION STRATEGY:
# - Default version represents latest stable, tested release
# - Use semantic versioning (vX.Y.Z) for precise version control
# - Test version upgrades in non-production environments first
# - Coordinate version updates across development teams
# 
# UPGRADE CONSIDERATIONS:
# - Review release notes for breaking changes and new features
# - Validate compatibility with existing blockchain networks
# - Plan maintenance windows for production upgrades
# - Implement rollback procedures for version downgrades
# 
# SUPPORTED VERSIONS:
# - Check SettleMint documentation for supported version matrix
# - Ensure chosen version is compatible with Kubernetes version
# - Validate integration with third-party services and APIs
variable "btp_version" {
  type        = string
  default     = "v7.6.19"
  description = "SettleMint BTP platform version (use semantic versioning: vX.Y.Z)"
  nullable    = false
  
  validation {
    condition = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+(-[a-zA-Z0-9]+)?$", var.btp_version))
    error_message = "BTP version must follow semantic versioning format (e.g., v7.6.19 or v7.6.19-beta)."
  }
}

# ============================================================================
# GOOGLE CLOUD PLATFORM CONFIGURATION
# ============================================================================

# Google Cloud Project ID
# The GCP project where all BTP infrastructure resources will be created.
# This project serves as the billing and security boundary for the deployment.
# 
# PROJECT REQUIREMENTS:
# - Must have billing enabled for resource provisioning
# - Required APIs must be enabled: GKE, Compute, DNS, KMS, IAM
# - Terraform service account must have appropriate IAM permissions
# - Project quotas must be sufficient for planned resource allocation
# 
# SECURITY CONSIDERATIONS:
# - Use dedicated projects for production environments
# - Implement project-level IAM policies for access control
# - Enable audit logging and security monitoring
# - Configure organizational policies for compliance
# 
# OPERATIONAL REQUIREMENTS:
# - Document project purpose and ownership
# - Implement resource labeling and cost allocation
# - Plan for backup and disaster recovery procedures
# - Monitor resource usage and costs regularly
variable "gcp_project_id" {
  type        = string
  description = "Google Cloud project ID for BTP infrastructure deployment (must have required APIs enabled)"
  nullable    = false
  
  validation {
    condition     = length(var.gcp_project_id) > 0 && can(regex("^[a-z][-a-z0-9]{4,28}[a-z0-9]$", var.gcp_project_id))
    error_message = "GCP project ID must be 6-30 characters, start with lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

# Platform Instance Name
# Unique identifier for this BTP platform instance, used consistently
# across all infrastructure resources for organization and management.
# 
# NAMING IMPACT:
# - GKE cluster: "${platform_name}-${random_suffix}"
# - DNS zone: Uses this name as the zone identifier
# - Service accounts: Prefixed with this name for consistency
# - Resource labels: Applied for cost tracking and organization
# 
# MULTI-ENVIRONMENT STRATEGY:
# - Use descriptive names for different environments (btp-prod, btp-dev)
# - Maintain consistent naming across related deployments
# - Consider organizational naming conventions and policies
# - Enable easy identification in monitoring and billing systems
# 
# ENTERPRISE CONSIDERATIONS:
# - Align with organizational resource naming standards
# - Support automated resource discovery and management
# - Enable clear cost attribution and chargeback procedures
# - Facilitate disaster recovery and environment replication
variable "gcp_platform_name" {
  type        = string
  description = "Unique name for this BTP platform instance (used across all resources for consistency)"
  default     = "btp"
  
  validation {
    condition = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.gcp_platform_name)) && length(var.gcp_platform_name) <= 63
    error_message = "Platform name must be lowercase, contain only letters, numbers, and hyphens, start and end with alphanumeric character, and be max 63 characters."
  }
}

# Google Cloud Region
# Primary region for BTP infrastructure deployment. Region selection impacts
# performance, compliance, costs, and service availability.
# 
# REGION SELECTION CRITERIA:
# - Latency: Choose region closest to primary users and blockchain networks
# - Compliance: Ensure region meets data residency and regulatory requirements
# - Services: Verify all required GCP services are available in the region
# - Costs: Consider regional pricing differences for compute and storage
# - Disaster Recovery: Plan for multi-region backup and recovery strategies
# 
# RECOMMENDED REGIONS FOR ENTERPRISE:
# - europe-west1 (Belgium): GDPR compliant, comprehensive service availability
# - us-central1 (Iowa): Cost-effective, extensive service portfolio
# - asia-southeast1 (Singapore): Optimal for APAC deployments
# - us-east1 (South Carolina): Maximum service availability and features
# 
# MULTI-REGION CONSIDERATIONS:
# - Plan for disaster recovery in secondary regions
# - Consider data replication and backup strategies
# - Evaluate network connectivity and latency between regions
# - Implement monitoring and alerting across regions
variable "gcp_region" {
  type        = string
  description = "Primary GCP region for infrastructure deployment (affects performance, compliance, and costs)"
  nullable    = false
  
  validation {
    condition = can(regex("^[a-z]+-[a-z0-9]+-[0-9]+$", var.gcp_region))
    error_message = "GCP region must be in format like 'europe-west1' or 'us-central1'."
  }
}

# DNS Zone Domain Name
# The fully qualified domain name that will serve as the base domain for
# all BTP platform services and blockchain network endpoints.
# 
# DOMAIN REQUIREMENTS:
# - Must be a registered domain owned by your organization
# - DNS zone must be created in the DNS module before infrastructure deployment
# - Domain registrar must be configured with Google Cloud DNS nameservers
# - Should follow organizational domain naming conventions
# 
# SUBDOMAIN ARCHITECTURE:
# The BTP platform will create various service subdomains:
# - Platform UI: app.yourdomain.com
# - API Gateway: api.yourdomain.com
# - Blockchain nodes: ethereum.yourdomain.com, fabric.yourdomain.com
# - Infrastructure: grafana.yourdomain.com, vault.yourdomain.com
# 
# SSL/TLS CERTIFICATE MANAGEMENT:
# - Automatic wildcard certificate provisioning via Let's Encrypt
# - DNS-01 ACME challenges for certificate validation
# - Automatic certificate renewal and lifecycle management
# - Support for custom certificate authorities if required
# 
# SECURITY AND COMPLIANCE:
# - Domain will be publicly resolvable for certificate validation
# - Consider using dedicated domains for different environments
# - Implement DNS monitoring and security scanning
# - Plan for domain renewal and lifecycle management
variable "gcp_dns_zone" {
  type        = string
  description = "Base domain name for BTP platform (must be registered and owned by your organization)"
  nullable    = false
  
  validation {
    condition = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\\.[a-zA-Z]{2,}$", var.gcp_dns_zone)) && length(var.gcp_dns_zone) > 0
    error_message = "DNS zone must be a valid domain name (e.g., 'blockchain.company.com') without protocol or trailing dot."
  }
}

# ============================================================================
# KUBERNETES NAMESPACE CONFIGURATION
# ============================================================================

# Cluster Dependencies Namespace
# Namespace for essential infrastructure services that support the BTP platform.
# These services include databases, caching, object storage, and security components.
# 
# DEPLOYED SERVICES:
# - PostgreSQL: Primary relational database for BTP applications
# - Redis: In-memory caching and session storage
# - MinIO: S3-compatible object storage for blockchain data
# - HashiCorp Vault: Secrets management and encryption
# - cert-manager: Automated SSL/TLS certificate management
# - ingress-nginx: HTTP/HTTPS load balancing and routing
# 
# NAMESPACE CHARACTERISTICS:
# - Long-running, stateful services with persistent storage
# - Shared infrastructure components used by multiple applications
# - Requires elevated privileges for cluster-wide operations
# - Critical for overall platform availability and security
variable "dependencies_namespace" {
  type        = string
  description = "Kubernetes namespace for infrastructure dependencies (databases, storage, security)"
  default     = "cluster-dependencies"
  
  validation {
    condition = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.dependencies_namespace)) && length(var.dependencies_namespace) <= 63
    error_message = "Namespace must be lowercase, contain only letters, numbers, and hyphens, and be max 63 characters."
  }
}

# Deployment Namespace
# Namespace for user applications, blockchain networks, and custom deployments.
# Provides isolation for customer workloads while maintaining access to shared services.
# 
# TYPICAL DEPLOYMENTS:
# - Ethereum blockchain nodes and private networks
# - Hyperledger Fabric networks and smart contracts
# - IPFS nodes for distributed file storage
# - Custom blockchain applications and DApps
# - Development and testing environments
# 
# ISOLATION BENEFITS:
# - User workloads separated from infrastructure services
# - Independent resource quotas and scaling policies
# - Separate RBAC configurations for user access control
# - Simplified monitoring and cost allocation per deployment
variable "deployment_namespace" {
  type        = string
  description = "Kubernetes namespace for user deployments and blockchain networks"
  default     = "deployments"
  
  validation {
    condition = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.deployment_namespace)) && length(var.deployment_namespace) <= 63
    error_message = "Namespace must be lowercase, contain only letters, numbers, and hyphens, and be max 63 characters."
  }
}

# ============================================================================
# WORKLOAD IDENTITY CONFIGURATION
# ============================================================================

# Cert-Manager Workload Identity
# Name prefix for the Google Cloud service account used by cert-manager
# for automated SSL/TLS certificate provisioning via Let's Encrypt.
# 
# CERT-MANAGER CAPABILITIES:
# - Performs DNS-01 ACME challenges for domain validation
# - Creates and manages wildcard SSL certificates
# - Automatically renews certificates before expiration
# - Integrates with multiple certificate authorities
# 
# SECURITY SCOPE:
# - DNS admin permissions for challenge record creation
# - Limited to DNS operations (principle of least privilege)
# - Temporary credentials with automatic rotation
# - Comprehensive audit logging of all operations
variable "cert_manager_workload_identity" {
  type        = string
  description = "Name prefix for cert-manager's Google Cloud service account (enables SSL certificate automation)"
  default     = "cert-manager"
  
  validation {
    condition = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.cert_manager_workload_identity)) && length(var.cert_manager_workload_identity) <= 30
    error_message = "Service account name must start with lowercase letter, contain only lowercase letters, numbers, and hyphens, and be max 30 characters."
  }
}

# External DNS Workload Identity
# Name prefix for the Google Cloud service account used by external-dns
# for automatic DNS record management based on Kubernetes resources.
# 
# EXTERNAL-DNS FUNCTIONALITY:
# - Monitors Kubernetes ingress and service resources
# - Automatically creates and updates DNS records
# - Maintains DNS record lifecycle with Kubernetes resources
# - Supports multiple DNS providers and record types
# 
# OPERATIONAL BENEFITS:
# - Eliminates manual DNS record management
# - Enables dynamic service discovery through DNS
# - Supports blue-green and canary deployment strategies
# - Integrates seamlessly with CI/CD pipelines
variable "external_dns_workload_identity" {
  type        = string
  description = "Name prefix for external-dns's Google Cloud service account (enables automatic DNS management)"
  default     = "external-dns"
  
  validation {
    condition = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.external_dns_workload_identity)) && length(var.external_dns_workload_identity) <= 30
    error_message = "Service account name must start with lowercase letter, contain only lowercase letters, numbers, and hyphens, and be max 30 characters."
  }
}

# Vault Unseal Workload Identity
# Name prefix for the Google Cloud service account used by HashiCorp Vault
# for automatic unsealing operations using Google Cloud KMS.
# 
# VAULT AUTO-UNSEAL BENEFITS:
# - Eliminates manual Vault unsealing procedures
# - Enables automatic Vault recovery after pod restarts
# - Provides enterprise-grade key management integration
# - Supports high availability Vault deployments
# 
# KMS INTEGRATION:
# - Uses Google Cloud KMS for encryption key management
# - Leverages Hardware Security Module (HSM) backing
# - Provides automatic key rotation and lifecycle management
# - Maintains compliance with enterprise security requirements
variable "vault_unseal_workload_identity" {
  type        = string
  description = "Name prefix for Vault's Google Cloud service account (enables KMS-based auto-unsealing)"
  default     = "vault-unseal"
  
  validation {
    condition = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.vault_unseal_workload_identity)) && length(var.vault_unseal_workload_identity) <= 30
    error_message = "Service account name must start with lowercase letter, contain only lowercase letters, numbers, and hyphens, and be max 30 characters."
  }
}

# ============================================================================
# OAUTH AND AUTHENTICATION CONFIGURATION
# ============================================================================

# Google Cloud OAuth Client ID
# Client identifier for Google Cloud OAuth integration with the BTP platform.
# Enables users to authenticate using their Google Cloud accounts and provides
# single sign-on (SSO) capabilities for the platform.
# 
# OAUTH SETUP REQUIREMENTS:
# - Must be created in Google Cloud Console OAuth consent screen
# - Configure authorized redirect URIs for BTP platform domains
# - Set appropriate OAuth scopes for user authentication
# - Ensure consent screen is configured for production use
# 
# SECURITY CONSIDERATIONS:
# - Store client ID securely and avoid committing to version control
# - Implement proper OAuth flow validation in BTP application
# - Monitor OAuth usage and authentication patterns
# - Regularly review and update OAuth consent screen configuration
# 
# ENTERPRISE INTEGRATION:
# - Can be integrated with existing identity providers via Google Cloud
# - Supports multi-domain authentication for large organizations
# - Enables centralized user access management and auditing
variable "gcp_client_id" {
  type        = string
  description = "Google Cloud OAuth client ID for BTP platform user authentication (create in GCP Console)"
  nullable    = false
  
  validation {
    condition     = length(var.gcp_client_id) > 0
    error_message = "Google Cloud OAuth client ID cannot be empty. Create OAuth credentials in Google Cloud Console."
  }
}

# Google Cloud OAuth Client Secret
# Client secret for Google Cloud OAuth integration. This sensitive credential
# is used alongside the client ID to authenticate the BTP platform with Google's
# OAuth services for user authentication flows.
# 
# SECURITY REQUIREMENTS:
# - Marked as sensitive to prevent exposure in logs and outputs
# - Must be stored in secure credential management systems
# - Implement regular rotation procedures for enhanced security
# - Use environment variables or secure CI/CD variable storage
# 
# OAUTH FLOW INTEGRATION:
# - Required for server-side OAuth token exchange
# - Enables secure user authentication and authorization
# - Supports refresh token functionality for persistent sessions
# - Integrates with BTP platform's authentication middleware
variable "gcp_client_secret" {
  type        = string
  description = "Google Cloud OAuth client secret for secure authentication (store securely, rotate regularly)"
  nullable    = false
  sensitive   = true
  
  validation {
    condition     = length(var.gcp_client_secret) > 0
    error_message = "Google Cloud OAuth client secret cannot be empty. Use the secret from GCP Console OAuth credentials."
  }
}

# ============================================================================
# GOOGLE CLOUD KEY MANAGEMENT SERVICE (KMS) CONFIGURATION
# ============================================================================

# KMS Key Ring Name
# Name for the Google Cloud KMS key ring that will contain encryption keys
# used by HashiCorp Vault for auto-unsealing operations.
# 
# KEY RING CHARACTERISTICS:
# - Logical container for organizing related encryption keys
# - Regional resource for optimal performance and compliance
# - Immutable after creation (cannot be deleted, only disabled)
# - Supports multiple crypto keys for different security purposes
# 
# NAMING STRATEGY:
# - Descriptive name indicating purpose (vault operations)
# - Will be suffixed with unique identifier to prevent conflicts
# - Follows Google Cloud naming conventions and best practices
# - Enables easy identification in KMS console and billing
variable "gcp_key_ring_name" {
  description = "Name for Google Cloud KMS key ring containing Vault encryption keys"
  type        = string
  default     = "vault-key-ring"
  
  validation {
    condition = can(regex("^[a-zA-Z0-9_-]+$", var.gcp_key_ring_name)) && length(var.gcp_key_ring_name) <= 63
    error_message = "Key ring name must contain only letters, numbers, underscores, and hyphens, and be max 63 characters."
  }
}

# KMS Crypto Key Name
# Name for the specific encryption key within the key ring used by Vault
# for seal and unseal operations. This key provides the cryptographic
# foundation for Vault's security model.
# 
# CRYPTO KEY FEATURES:
# - AES-256 encryption with Google Cloud HSM backing
# - Automatic key rotation based on configured policies
# - Version management for key lifecycle operations
# - Integration with Google Cloud audit logging and monitoring
# 
# VAULT INTEGRATION:
# - Referenced in Vault's GCP KMS seal configuration
# - Enables automatic unsealing after Vault pod restarts
# - Provides enterprise-grade key management without key exposure
# - Supports Vault high availability and disaster recovery scenarios
variable "gcp_crypto_key_name" {
  description = "Name for Google Cloud KMS crypto key used by Vault for auto-unsealing"
  type        = string
  default     = "vault-key"
  
  validation {
    condition = can(regex("^[a-zA-Z0-9_-]+$", var.gcp_crypto_key_name)) && length(var.gcp_crypto_key_name) <= 63
    error_message = "Crypto key name must contain only letters, numbers, underscores, and hyphens, and be max 63 characters."
  }
}

# Vault Google Cloud Service Account ConfigMap
# Name for the Kubernetes ConfigMap containing Google Cloud service account
# credentials used by Vault for KMS operations and auto-unsealing.
# 
# CONFIGMAP CONTENTS:
# - Google Cloud service account key in JSON format
# - Mounted as volume in Vault pods for authentication
# - Enables Vault to authenticate with Google Cloud KMS
# - Required for Vault auto-unseal functionality
# 
# SECURITY CONSIDERATIONS:
# - Contains sensitive service account credentials
# - Should be created with appropriate Kubernetes RBAC restrictions
# - Monitor access patterns and implement audit logging
# - Consider using Workload Identity as alternative to static keys
variable "vault_gcp_sa" {
  description = "Name for Kubernetes ConfigMap containing Vault's Google Cloud service account credentials"
  type        = string
  default     = "vault-gcp-sa"
  
  validation {
    condition = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.vault_gcp_sa)) && length(var.vault_gcp_sa) <= 63
    error_message = "ConfigMap name must be lowercase, contain only letters, numbers, and hyphens, and be max 63 characters."
  }
}
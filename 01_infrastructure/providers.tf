# ============================================================================
# INFRASTRUCTURE MODULE - PROVIDER CONFIGURATIONS
# ============================================================================
# 
# This file configures all Terraform providers required for the BTP infrastructure
# deployment. Each provider is configured with appropriate authentication,
# endpoints, and registry settings to enable secure, reliable infrastructure
# management across Google Cloud Platform and Kubernetes environments.
# 
# PROVIDER AUTHENTICATION STRATEGY:
# The configuration uses Google Cloud authentication tokens and certificates
# to establish secure connections to GKE clusters and GCP APIs. This approach:
# - Leverages Google Cloud IAM for centralized access control
# - Eliminates need for static credentials or service account keys
# - Provides automatic token refresh and rotation
# - Enables audit logging of all infrastructure operations
# 
# SECURITY ARCHITECTURE:
# - All provider connections use TLS encryption
# - Authentication tokens are automatically managed by Google Cloud SDK
# - Cluster CA certificates ensure secure Kubernetes API communication
# - OCI registry credentials are managed as sensitive variables
# - No static credentials are stored in configuration files
# 
# OPERATIONAL CONSIDERATIONS:
# - Providers are configured to connect to dynamically created GKE clusters
# - Authentication depends on successful GKE cluster deployment
# - Registry authentication enables private Helm chart access
# - Provider configurations support both development and production environments
# 
# ============================================================================

# Helm Provider Configuration
# Manages Helm chart deployments to the Kubernetes cluster. Helm is used
# extensively in BTP deployments for managing complex application stacks
# including databases, monitoring, security, and the BTP platform itself.
# 
# AUTHENTICATION ARCHITECTURE:
# - Connects to GKE cluster using Google Cloud authentication tokens
# - Uses cluster CA certificate for secure TLS communication
# - Automatically refreshes authentication tokens as needed
# - Supports both public and private Helm chart repositories
# 
# REGISTRY CONFIGURATION:
# - Configured for SettleMint's private OCI registry
# - Enables access to proprietary BTP Helm charts
# - Uses secure credential management via Terraform variables
# - Supports OCI-compliant registry operations
# 
# MANAGED HELM CHARTS:
# - cert-manager: Automated SSL certificate management
# - ingress-nginx: HTTP/HTTPS load balancing and routing
# - postgresql: Relational database for BTP applications
# - redis: In-memory caching and session storage
# - minio: S3-compatible object storage
# - vault: Secrets management and encryption
# - settlemint: Core BTP platform components
provider "helm" {
  # Kubernetes Cluster Connection Configuration
  # Establishes secure connection to the GKE cluster for Helm operations
  kubernetes {
    # GKE cluster API endpoint - dynamically obtained from GKE module
    # Format: https://[cluster-ip-address] or https://[cluster-fqdn]
    host = module.gke.endpoint
    
    # Google Cloud access token for cluster authentication
    # Automatically managed by Google Cloud SDK and refreshed as needed
    # Provides temporary, scoped access to GKE cluster resources
    token = data.google_client_config.default.access_token
    
    # Cluster Certificate Authority (CA) certificate
    # Validates the authenticity of the GKE cluster API server
    # Decoded from base64 format provided by GKE module
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  }

  # SettleMint Private OCI Registry Configuration
  # Provides access to proprietary BTP Helm charts hosted in SettleMint's
  # private OCI (Open Container Initiative) compliant registry
  registry {
    # OCI registry URL for SettleMint platform charts
    # Uses OCI protocol for modern container and chart distribution
    url = "oci://registry.settlemint.com/settlemint-platform/settlemint"
    
    # Registry authentication credentials
    # Managed as sensitive Terraform variables for security
    # Required for accessing private BTP platform charts
    username = var.oci_registry_username
    password = var.oci_registry_password
  }
}

# Kubernetes Provider Configuration
# Manages native Kubernetes resources including namespaces, services, deployments,
# config maps, secrets, and RBAC policies. This provider handles the core
# Kubernetes infrastructure required for BTP platform deployment.
# 
# RESOURCE MANAGEMENT SCOPE:
# - Namespace creation and management for logical separation
# - Service accounts and RBAC configurations for security
# - Config maps and secrets for application configuration
# - Services and ingress rules for network routing
# - Jobs and cron jobs for operational tasks
# 
# AUTHENTICATION SECURITY:
# - Uses Google Cloud IAM-based authentication
# - Leverages GKE workload identity for pod-to-GCP communication
# - Supports automatic token refresh and rotation
# - Maintains audit trail of all Kubernetes operations
provider "kubernetes" {
  # GKE Cluster API Server Endpoint
  # Secure HTTPS connection to the Kubernetes API server
  # Endpoint is dynamically determined from GKE module output
  host = "https://${module.gke.endpoint}"
  
  # Google Cloud Authentication Token
  # Temporary, scoped access token for Kubernetes API operations
  # Automatically managed and refreshed by Google Cloud SDK
  token = data.google_client_config.default.access_token
  
  # Cluster Certificate Authority Certificate
  # Ensures secure, authenticated communication with Kubernetes API
  # Prevents man-in-the-middle attacks and validates cluster identity
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

# Kubectl Provider Configuration
# Provides advanced Kubernetes operations not available in the standard
# Kubernetes provider. Used for applying raw YAML manifests and handling
# complex resource scenarios that require kubectl-specific functionality.
# 
# ADVANCED OPERATIONS:
# - Raw YAML manifest application (CRDs, complex configurations)
# - Server-side resource validation and admission control
# - Custom resource management and lifecycle operations
# - Complex dependency handling between Kubernetes resources
# 
# USE CASES IN BTP DEPLOYMENT:
# - Applying cert-manager ClusterIssuer configurations
# - Managing custom resource definitions (CRDs)
# - Handling resources with complex validation requirements
# - Applying manifests that need server-side processing
provider "kubectl" {
  # GKE Cluster Connection Parameters
  # Identical to Kubernetes provider for consistency and security
  host = "https://${module.gke.endpoint}"
  
  # Authentication using Google Cloud access tokens
  # Maintains consistency with other Kubernetes providers
  token = data.google_client_config.default.access_token
  
  # Cluster CA certificate for secure communication
  # Ensures all kubectl operations are authenticated and encrypted
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

# Random Provider Configuration
# Generates cryptographically secure random values for passwords, keys,
# and other sensitive configuration data. Essential for maintaining
# security best practices across the BTP infrastructure.
# 
# SECURITY APPLICATIONS:
# - Database passwords and authentication credentials
# - Encryption keys and cryptographic material
# - Session secrets and JWT signing keys
# - Service account keys and API tokens
# - Platform-specific identifiers and suffixes
# 
# ENTROPY AND SECURITY:
# - Uses cryptographically secure random number generation
# - Provides sufficient entropy for production security requirements
# - Generates values that meet complexity requirements for enterprise systems
# - Ensures uniqueness across multiple deployments and environments
provider "random" {
  # No explicit configuration required
  # Provider uses system entropy sources for secure random generation
}

# Local Provider Configuration  
# Handles local file operations, template processing, and data transformations
# required during infrastructure deployment. Used for generating configuration
# files, processing templates, and managing local resources.
# 
# OPERATIONAL FUNCTIONS:
# - Template file processing for dynamic configurations
# - Local file generation for application configurations
# - Data transformation and formatting operations
# - Temporary file management during deployment processes
# 
# USAGE IN BTP DEPLOYMENT:
# - Processing Helm values templates with dynamic variables
# - Generating Kubernetes manifests from templates
# - Creating configuration files for applications
# - Managing local resources during deployment workflows
provider "local" {
  # No explicit configuration required
  # Provider operates on local filesystem with Terraform execution context
}
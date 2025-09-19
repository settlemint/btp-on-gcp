# =============================================================================
# SETTLEMINT BTP INFRASTRUCTURE VARIABLES
# =============================================================================
# This file defines all input variables required for deploying the SettleMint
# Blockchain Transformation Platform on Google Cloud Platform. Variables are
# organized by category for better maintainability.
# 
# Usage: Set these variables via:
# - Environment variables: export TF_VAR_variable_name=value
# - terraform.tfvars file
# - Command line: terraform apply -var="variable_name=value"
# =============================================================================

# =============================================================================
# SETTLEMINT PLATFORM CREDENTIALS
# =============================================================================
# These credentials are provided by SettleMint Customer Success team and
# are required to access the private OCI registry containing BTP Helm charts.
# =============================================================================

variable "oci_registry_username" {
  type        = string
  description = "Username for accessing the SettleMint OCI registry. This credential is provided by SettleMint Customer Success team and is required to download the BTP Helm chart."
  nullable    = false
  
  # Example: "customer-username"
  # Obtain from: SettleMint Customer Success representative
}

variable "oci_registry_password" {
  type        = string
  description = "Password for accessing the SettleMint OCI registry. This credential is provided by SettleMint Customer Success team and is required to download the BTP Helm chart."
  nullable    = false
  sensitive   = true  # Marked as sensitive to prevent exposure in logs
  
  # Example: "secure-customer-password-123"
  # Obtain from: SettleMint Customer Success representative
}

variable "btp_version" {
  type        = string
  default     = "v7.6.19"
  description = "The version of the SettleMint Blockchain Transformation Platform to install. This should match the version provided by SettleMint Customer Success team."
  nullable    = false
  
  # Format: Semantic versioning (e.g., v7.6.19)
  # Obtain from: SettleMint Customer Success representative
  # Note: Different versions may have different requirements
}

# =============================================================================
# GOOGLE CLOUD PLATFORM CONFIGURATION
# =============================================================================
# Core GCP settings that define where and how the BTP platform will be deployed.
# These variables control the fundamental infrastructure placement and naming.
# =============================================================================

variable "gcp_project_id" {
  type        = string
  description = "The Google Cloud Platform project ID where all resources will be created. This project must have billing enabled and the required APIs activated."
  nullable    = false
  
  # Example: "my-btp-project-123456"
  # Requirements:
  # - Valid GCP project with billing enabled
  # - APIs enabled: container, dns, cloudkms, compute, iam
  # - Sufficient quotas for GKE clusters and load balancers
}

variable "gcp_platform_name" {
  type        = string
  description = "A unique identifier used as prefix for resource names (GKE cluster, DNS zone, etc.). This helps organize resources and avoid naming conflicts."
  default     = "btp"
  
  # This name will be used for:
  # - GKE cluster name: "btp-{random_suffix}"
  # - DNS zone name: "btp"
  # - Database name: "btp"
  # - Storage bucket: "btp"
}

variable "gcp_region" {
  type        = string
  description = "The GCP region where the infrastructure will be deployed. Choose a region close to your users for optimal performance."
  nullable    = false
  
  # Popular regions:
  # - "us-central1" (Iowa, USA)
  # - "europe-west1" (Belgium, Europe)
  # - "asia-east1" (Taiwan, Asia)
  # - "us-west1" (Oregon, USA)
  # 
  # Consider: latency, compliance requirements, and service availability
}

variable "gcp_dns_zone" {
  type        = string
  description = "The public DNS zone (domain/subdomain) that will be used to access the BTP platform. You must own this domain and be able to delegate it to Google Cloud DNS."
  nullable    = false
  
  # Examples:
  # - "btp.yourcompany.com"
  # - "blockchain.example.org"
  # 
  # Requirements:
  # - You must own the parent domain
  # - Ability to create NS records in parent domain
  # - Domain should be dedicated to BTP platform
}

# =============================================================================
# KUBERNETES NAMESPACE CONFIGURATION
# =============================================================================
# These variables define the Kubernetes namespace organization for the BTP
# platform components and user deployments.
# =============================================================================

variable "dependencies_namespace" {
  type        = string
  description = "Kubernetes namespace where infrastructure dependencies will be deployed (PostgreSQL, Redis, MinIO, Vault, cert-manager, ingress-nginx). Separating dependencies helps with resource management and troubleshooting."
  default     = "cluster-dependencies"
  
  # This namespace will contain:
  # - PostgreSQL database
  # - Redis cache
  # - MinIO object storage
  # - HashiCorp Vault
  # - cert-manager
  # - ingress-nginx controller
}

variable "deployment_namespace" {
  type        = string
  description = "Kubernetes namespace where user blockchain deployments will be created. This provides isolation between the platform infrastructure and user-created blockchain networks."
  default     = "deployments"
  
  # This namespace will contain:
  # - User-deployed blockchain networks
  # - Smart contracts
  # - IPFS nodes
  # - Custom applications
}

# =============================================================================
# WORKLOAD IDENTITY SERVICE ACCOUNT NAMES
# =============================================================================
# Workload Identity allows Kubernetes service accounts to act as Google Cloud
# service accounts without storing keys. These variables define the names of
# the service accounts used by various platform components.
# =============================================================================

variable "cert_manager_workload_identity" {
  type        = string
  description = "Base name for the cert-manager workload identity GCP service account. This service account will have DNS admin permissions to manage DNS records for SSL certificate validation."
  default     = "cert-manager"
  
  # Full name will be: "cert-manager-{random_suffix}"
  # Permissions: roles/dns.admin
  # Used by: cert-manager for Let's Encrypt DNS-01 challenges
}

variable "external_dns_workload_identity" {
  type        = string
  description = "Base name for the external-dns workload identity GCP service account. This service account will have DNS admin permissions to automatically create DNS records for Kubernetes services."
  default     = "external-dns"
  
  # Full name will be: "external-dns-{random_suffix}"
  # Permissions: roles/dns.admin
  # Used by: external-dns controller for automatic DNS record management
}

variable "vault_unseal_workload_identity" {
  type        = string
  description = "Base name for the vault unseal workload identity GCP service account. This service account will have KMS permissions for Vault auto-unsealing operations."
  default     = "vault-unseal"
  
  # Full name will be: "vault-unseal-{random_suffix}"
  # Permissions: roles/cloudkms.cryptoKeyEncrypterDecrypter, roles/cloudkms.viewer
  # Used by: HashiCorp Vault for Google Cloud KMS auto-unsealing
}

# =============================================================================
# OAUTH2 AUTHENTICATION CONFIGURATION
# =============================================================================
# Google OAuth2 credentials for user authentication to the BTP platform.
# These must be obtained from the Google Cloud Console OAuth2 setup.
# =============================================================================

variable "gcp_client_id" {
  type        = string
  description = "Google OAuth2 client ID for user authentication. This is obtained from the Google Cloud Console when setting up OAuth2 credentials for the BTP platform."
  nullable    = false
  
  # Format: "123456789-abcdefghijklmnop.apps.googleusercontent.com"
  # Obtain from: Google Cloud Console > APIs & Services > Credentials
  # Used for: User authentication via Google Sign-In
}

variable "gcp_client_secret" {
  type        = string
  description = "Google OAuth2 client secret for user authentication. This is obtained from the Google Cloud Console when setting up OAuth2 credentials for the BTP platform."
  nullable    = false
  sensitive   = true  # Marked as sensitive to prevent exposure in logs
  
  # Format: "GOCSPX-abcdefghijklmnopqrstuvwxyz"
  # Obtain from: Google Cloud Console > APIs & Services > Credentials
  # Used for: OAuth2 token exchange during authentication
}

# =============================================================================
# GOOGLE CLOUD KMS CONFIGURATION
# =============================================================================
# Configuration for Google Cloud Key Management Service (KMS) used by
# HashiCorp Vault for auto-unsealing operations.
# =============================================================================

variable "gcp_key_ring_name" {
  description = "Base name for the Google Cloud KMS key ring that will contain the Vault unsealing key. The key ring provides a logical grouping for cryptographic keys in a specific location."
  type        = string
  default     = "vault-key-ring"
  
  # Full name will be: "vault-key-ring-{random_suffix}"
  # Location: Same as gcp_region for optimal performance
  # Purpose: Container for Vault unsealing cryptographic keys
}

variable "gcp_crypto_key_name" {
  description = "Name of the Google Cloud KMS cryptographic key used by Vault for auto-unsealing. This key encrypts/decrypts the Vault master key, eliminating the need for manual unsealing."
  type        = string
  default     = "vault-key"
  
  # Key properties:
  # - Purpose: ENCRYPT_DECRYPT
  # - Algorithm: GOOGLE_SYMMETRIC_ENCRYPTION
  # - Used by: Vault auto-unsealing process
}

# =============================================================================
# VAULT CONFIGURATION
# =============================================================================
# Additional configuration variables for HashiCorp Vault deployment.
# =============================================================================

variable "vault_gcp_sa" {
  description = "Name of the Kubernetes ConfigMap that stores the Google Cloud service account credentials for Vault. This ConfigMap is mounted into the Vault pod to provide KMS access."
  type        = string
  default     = "vault-gcp-sa"
  
  # ConfigMap contents:
  # - credentials.json: Service account key for KMS access
  # - Mounted at: /vault/userconfig/vault-gcp-sa/
  # - Used by: Vault for Google Cloud KMS authentication
}
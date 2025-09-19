# ============================================================================
# MINIO S3-COMPATIBLE OBJECT STORAGE DEPLOYMENT
# ============================================================================
# 
# Deploys and configures MinIO, a high-performance, S3-compatible object
# storage system that serves as the primary file and data storage solution
# for the BTP platform. MinIO provides scalable, secure object storage
# essential for blockchain data, smart contracts, and application assets.
# 
# MINIO OVERVIEW:
# MinIO is chosen for the BTP platform due to its:
# - S3 API compatibility enabling seamless integration with existing tools
# - High performance with multi-part uploads and parallel processing
# - Enterprise-grade security with encryption and access controls
# - Kubernetes-native deployment and scaling capabilities
# - Cost-effective alternative to cloud storage for on-premises deployments
# - Built-in versioning and lifecycle management for data governance
# 
# BTP PLATFORM INTEGRATION:
# In the BTP deployment, MinIO serves critical functions:
# - Smart contract artifacts and bytecode storage
# - Blockchain data backups and archival storage
# - User-uploaded files and application assets
# - Log aggregation and audit trail storage
# - Container image registry backend (when configured)
# - Data lake storage for blockchain analytics and reporting
# 
# ============================================================================

# MinIO Root User Password Generation
# Generates a cryptographically secure random password for the MinIO
# root administrator account. This account has full administrative
# privileges for bucket management, user administration, and system configuration.
resource "random_password" "minio_root_password" {
  length  = 16
  special = false  # Avoid special characters for compatibility
}

# MinIO Provisioning User Password Generation
# Generates a password for the MinIO provisioning user account, which is
# used for automated bucket and policy configuration during deployment.
# This account enables infrastructure-as-code management of MinIO resources.
resource "random_password" "minio_provisioning_password" {
  length  = 16
  special = false  # Avoid special characters for compatibility
}

# MinIO Service Account Access Key Generation
# Generates an access key for MinIO service account authentication.
# Service accounts provide programmatic access to MinIO resources
# with specific permissions and policies.
resource "random_password" "minio_svcacct_access_key" {
  length  = 16
  special = false  # Avoid special characters for compatibility
}

# MinIO Service Account Secret Key Generation
# Generates a secret key paired with the access key for MinIO service
# account authentication. This key-pair enables secure, programmatic
# access to MinIO storage resources.
resource "random_password" "minio_svcacct_secret_key" {
  length  = 16
  special = false  # Avoid special characters for compatibility
}

# MinIO Helm Release
# Deploys MinIO using the official Bitnami Helm chart, providing a complete
# S3-compatible object storage solution with web UI, API access, and
# comprehensive management capabilities.
resource "helm_release" "minio" {
  # Release identification and metadata
  name       = "minio"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "minio"
  version    = "17.0.21"  # Stable version with latest features and security fixes
  namespace  = var.dependencies_namespace

  create_namespace = true

  # Default Bucket Configuration
  # Creates initial bucket using platform name for consistency
  # Provides immediate storage availability for BTP applications
  set {
    name  = "defaultBuckets"
    value = var.gcp_platform_name
  }

  # Web UI Configuration
  # Enables MinIO Console for administrative and monitoring tasks
  # Provides graphical interface for bucket and user management
  set {
    name  = "disableWebUI"
    value = "false"
  }

  # Root Administrator Configuration
  # Sets up primary administrative account with full system privileges
  # Uses platform name for consistent resource identification
  set {
    name  = "auth.rootUser"
    value = var.gcp_platform_name
  }

  set {
    name  = "auth.rootPassword"
    value = random_password.minio_root_password.result
  }

  # Deployment Architecture
  # Single replica deployment suitable for development and small production
  # For high availability, increase replica count and configure distributed mode
  set {
    name  = "statefulset.replicaCount"
    value = "1"
  }

  # Automatic Provisioning Configuration
  # Enables infrastructure-as-code management of MinIO resources
  # Automatically configures buckets, users, and policies during deployment
  set {
    name  = "provisioning.enabled"
    value = "true"
  }

  # Region Configuration
  # Sets MinIO region for bucket placement and data locality
  # Aligns with GCP region for consistent geographic placement
  set {
    name  = "provisioning.config[0].name"
    value = "region"
  }

  set {
    name  = "provisioning.config[0].options.name"
    value = var.gcp_region
  }

  # Application User Configuration
  # Creates dedicated user account for BTP application access
  # Provides scoped permissions for application-level operations
  set {
    name  = "provisioning.users[0].username"
    value = "pulumi"
  }

  set {
    name  = "provisioning.users[0].password"
    value = random_password.minio_provisioning_password.result
  }

  set {
    name  = "provisioning.users[0].disabled"
    value = "false"
  }

  # User Permission Configuration
  # Assigns read-write permissions for application data access
  # Enables full CRUD operations on assigned buckets
  set {
    name  = "provisioning.users[0].policies[0]"
    value = "readwrite"
  }

  set {
    name  = "provisioning.users[0].setPolicies"
    value = "true"
  }

  # Service Account Provisioning
  # Creates service account with access/secret key pair for programmatic access
  # Enables S3-compatible API authentication for applications
  set_sensitive {
    name  = "provisioning.extraCommands"
    value = "if [[ ! $(mc admin user svcacct ls provisioning ${var.gcp_platform_name} | grep ${random_password.minio_svcacct_access_key.result}) ]]; then mc admin user svcacct add --access-key \"${random_password.minio_svcacct_access_key.result}\" --secret-key \"${random_password.minio_svcacct_secret_key.result}\" provisioning ${var.gcp_platform_name}; fi"
  }

  # Deployment Dependencies
  # Ensures GKE cluster and namespace are ready before MinIO deployment
  depends_on = [module.gke, kubernetes_namespace.cluster_dependencies_namespace]
}
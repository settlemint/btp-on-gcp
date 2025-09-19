# =============================================================================
# MINIO OBJECT STORAGE CONFIGURATION
# =============================================================================
# MinIO provides S3-compatible object storage for the BTP platform, storing:
# - Blockchain network state and configuration files
# - Smart contract artifacts and deployment packages
# - User-uploaded files and documents
# - Backup and archive data
# - Container images and build artifacts
# 
# MinIO is deployed as a single-node instance for demo purposes.
# For production, consider multi-node deployment for high availability.
# =============================================================================

# Generate root password for MinIO administrator access
# This is the main administrative account for MinIO management
resource "random_password" "minio_root_password" {
  length  = 16        # 16 characters for good security
  special = false     # Alphanumeric only to avoid web UI issues
}

# Generate password for MinIO provisioning user
# This user is created during initial setup for automated provisioning
resource "random_password" "minio_provisioning_password" {
  length  = 16        # 16 characters for good security
  special = false     # Alphanumeric only for compatibility
}

# Generate access key for MinIO service account
# This acts as the "username" for S3 API access
resource "random_password" "minio_svcacct_access_key" {
  length  = 16        # 16 characters (S3 access key format)
  special = false     # Alphanumeric only for S3 compatibility
}

# Generate secret key for MinIO service account
# This acts as the "password" for S3 API access
resource "random_password" "minio_svcacct_secret_key" {
  length  = 16        # 16 characters (S3 secret key format)
  special = false     # Alphanumeric only for S3 compatibility
}

# Deploy MinIO using the Bitnami Helm chart
# This provides a production-ready S3-compatible object storage solution
resource "helm_release" "minio" {
  # Helm release name
  name       = "minio"
  # Bitnami OCI registry (reliable, well-maintained charts)
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "minio"
  # Deploy in the dependencies namespace

  version    = "17.0.21"  # MinIO with Bitnami chart optimizations

  namespace  = var.dependencies_namespace

  # Create namespace if it doesn't exist (redundant with explicit creation)
  create_namespace = true

  # Create a default bucket for the BTP platform
  # This bucket will store all BTP-related files and data
  set {
    name  = "defaultBuckets"
    value = var.gcp_platform_name  # e.g., "btp" bucket
  }

  # Enable the MinIO web UI for administration
  # This provides a browser-based interface for managing buckets and objects
  set {
    name  = "disableWebUI"
    value = "false"
  }

  # Configure the root user (administrator account)
  set {
    name  = "auth.rootUser"
    value = var.gcp_platform_name  # Use platform name as root username
  }

  # Set the root user password
  set {
    name  = "auth.rootPassword"
    value = random_password.minio_root_password.result
  }

  # Deploy as single replica for demo purposes
  # For production, consider multiple replicas with distributed mode
  set {
    name  = "statefulset.replicaCount"
    value = "1"
  }

  # Enable automatic provisioning of users, policies, and service accounts
  set {
    name  = "provisioning.enabled"
    value = "true"
  }

  # Configure the default region for S3 compatibility
  set {
    name  = "provisioning.config[0].name"
    value = "region"
  }

  # Set the region to match the GCP region for consistency
  set {
    name  = "provisioning.config[0].options.name"
    value = var.gcp_region
  }

  # Create a provisioning user for automated operations
  # This user will be used for creating service accounts and managing policies
  set {
    name  = "provisioning.users[0].username"
    value = "pulumi"  # Named for compatibility with deployment tools
  }

  # Set password for the provisioning user
  set {
    name  = "provisioning.users[0].password"
    value = random_password.minio_provisioning_password.result
  }

  # Enable the provisioning user
  set {
    name  = "provisioning.users[0].disabled"
    value = "false"
  }

  # Grant read-write permissions to the provisioning user
  set {
    name  = "provisioning.users[0].policies[0]"
    value = "readwrite"
  }

  # Apply the policies to the user
  set {
    name  = "provisioning.users[0].setPolicies"
    value = "true"
  }

  # Create a service account for the BTP platform to use
  # This command creates S3-compatible access keys for programmatic access
  set_sensitive {
    name  = "provisioning.extraCommands"
    value = "if [[ ! $(mc admin user svcacct ls provisioning ${var.gcp_platform_name} | grep ${random_password.minio_svcacct_access_key.result}) ]]; then mc admin user svcacct add --access-key \"${random_password.minio_svcacct_access_key.result}\" --secret-key \"${random_password.minio_svcacct_secret_key.result}\" provisioning ${var.gcp_platform_name}; fi"
  }

  # Ensure cluster and namespace exist before deploying MinIO
  depends_on = [module.gke, kubernetes_namespace.cluster_dependencies_namespace]
}
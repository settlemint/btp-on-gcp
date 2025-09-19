# =============================================================================
# POSTGRESQL DATABASE CONFIGURATION
# =============================================================================
# PostgreSQL serves as the primary database for the SettleMint BTP platform,
# storing:
# - User accounts and authentication data
# - Project and deployment metadata
# - Blockchain network configurations
# - Application state and settings
# - Audit logs and activity tracking
# =============================================================================

# Generate a secure random password for PostgreSQL
# This password will be used for both the postgres superuser and the BTP application user
resource "random_password" "postgresql_password" {
  length  = 16        # 16 characters for good security
  special = false     # Alphanumeric only to avoid connection string issues
}

# Deploy PostgreSQL using the Bitnami Helm chart
# This provides a production-ready PostgreSQL instance with proper configuration
resource "helm_release" "postgresql" {
  # Helm release name
  name       = "postgresql"
  # Bitnami OCI registry (reliable, well-maintained charts)
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  version    = "16.7.26"  # PostgreSQL 16.x with Bitnami chart optimizations
  
  # Deploy in the dependencies namespace
  namespace  = var.dependencies_namespace

  # Create namespace if it doesn't exist (redundant with explicit creation)
  create_namespace = true

  # Configure the application database user
  # This user will be used by the BTP platform to connect to PostgreSQL
  set {
    name  = "global.postgresql.auth.username"
    value = var.gcp_platform_name  # Use platform name as username (e.g., "btp")
  }

  # Set the password for the application user
  set {
    name  = "global.postgresql.auth.password"
    value = random_password.postgresql_password.result
  }

  # Set the password for the PostgreSQL superuser (postgres)
  # Using the same password for simplicity in demo environment
  set {
    name  = "global.postgresql.auth.postgresPassword"
    value = random_password.postgresql_password.result
  }

  # Create a database for the BTP platform
  # This database will contain all BTP application data
  set {
    name  = "global.postgresql.auth.database"
    value = var.gcp_platform_name  # Use platform name as database name (e.g., "btp")
  }

  # Ensure cluster and namespace exist before deploying PostgreSQL
  depends_on = [module.gke, kubernetes_namespace.cluster_dependencies_namespace]
}
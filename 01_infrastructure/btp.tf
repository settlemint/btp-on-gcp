# =============================================================================
# SETTLEMINT BTP PLATFORM DEPLOYMENT
# =============================================================================
# This file contains the configuration for deploying the SettleMint Blockchain
# Transformation Platform (BTP) using Helm. It includes:
# - Random password generation for security
# - Values template processing for configuration
# - Helm chart deployment with all dependencies
# =============================================================================

# Generate a secure JWT signing key for authentication
# This key is used to sign and verify JSON Web Tokens for user sessions
resource "random_password" "jwtSigningKey" {
  length  = 32        # 32 characters for strong security
  special = false     # Alphanumeric only to avoid encoding issues
}

# Generate an encryption key for sensitive data
# This key is used to encrypt sensitive configuration data in the platform
resource "random_password" "encryption_key" {
  length  = 16        # 16 characters sufficient for AES encryption
  special = false     # Alphanumeric only for compatibility
}

# Generate a password for Grafana monitoring dashboard
# This allows access to the observability and monitoring interface
resource "random_password" "grafana_password" {
  length  = 16        # 16 characters for reasonable security
  special = false     # Alphanumeric only to avoid shell escaping issues
}

# =============================================================================
# HELM VALUES TEMPLATE PROCESSING
# =============================================================================
# This local value processes the Helm values template file by substituting
# all the dynamic values (passwords, connection strings, etc.) that are
# generated or configured during the Terraform deployment.
# =============================================================================

locals {
  # Process the values.yaml.tmpl template file with all required variables
  # This creates the final Helm values configuration for the BTP platform
  values_yaml = templatefile("${path.module}/values.yaml.tmpl", {
    # DNS and networking configuration
    gcp_dns_zone                   = var.gcp_dns_zone
    gcp_project_id                 = var.gcp_project_id
    gcp_region                     = var.gcp_region
    gcp_platform_name              = var.gcp_platform_name
    
    # Kubernetes namespace configuration
    dependencies_namespace         = var.dependencies_namespace
    deployment_namespace           = var.deployment_namespace
    
    # Database connection details
    postgresql_password            = random_password.postgresql_password.result
    redis_password                 = random_password.redis_password.result
    
    # Object storage (MinIO) credentials
    minio_svcacct_access_key       = random_password.minio_svcacct_access_key.result
    minio_svcacct_secret_key       = random_password.minio_svcacct_secret_key.result
    
    # Authentication and security
    jwtSigningKey                  = random_password.jwtSigningKey.result
    encryption_key                 = random_password.encryption_key.result
    gcp_client_id                  = var.gcp_client_id
    gcp_client_secret              = var.gcp_client_secret
    
    # Vault authentication (AppRole method)
    role_id                        = local.role_id
    secret_id                      = local.secret_id
    
    # Monitoring and observability
    grafana_password               = random_password.grafana_password.result
    
    # Service account for external DNS management
    external_dns_workload_identity = "${var.external_dns_workload_identity}-${random_id.platform_suffix.hex}"
  })
}

# =============================================================================
# SETTLEMINT BTP HELM CHART DEPLOYMENT
# =============================================================================
# This resource deploys the SettleMint BTP platform using the official Helm chart
# from the SettleMint OCI registry. The deployment includes all platform components:
# - Web UI for blockchain development
# - API services for platform operations
# - Deployment engine for blockchain networks
# - Cluster manager for infrastructure management
# - Observability stack (Grafana, Prometheus, Loki)
# =============================================================================

resource "helm_release" "settlemint" {
  # Helm release name (will appear in 'helm list')
  name = "settlemint"
  
  # SettleMint OCI registry containing the official BTP Helm chart
  # Access requires credentials provided by SettleMint Customer Success team
  repository = "oci://registry.settlemint.com/settlemint-platform"
  
  # The Helm chart name within the repository
  chart = "settlemint"
  
  # Kubernetes namespace where BTP platform will be deployed
  namespace = "settlemint"
  
  # BTP platform version to deploy (provided by SettleMint)
  # This should match the version provided by Customer Success team
  version = var.btp_version
  
  # Create the namespace if it doesn't exist (redundant with our explicit namespace creation)
  create_namespace = true
  
  # Apply the processed Helm values configuration
  # This contains all the customized settings for the GCP deployment
  values = [local.values_yaml]
  
  # Ensure all dependencies are ready before deploying BTP platform
  # - Vault must be configured with proper secrets and policies
  # - Namespace must exist for proper resource organization
  depends_on = [kubernetes_job.vault_configure, kubernetes_namespace.settlemint]
}
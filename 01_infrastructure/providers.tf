# =============================================================================
# TERRAFORM PROVIDER CONFIGURATION
# =============================================================================
# This file configures all Terraform providers required for deploying the
# SettleMint BTP platform on Google Cloud Platform. Each provider is
# configured with the necessary authentication and connection details.
# =============================================================================

# =============================================================================
# HELM PROVIDER
# =============================================================================
# The Helm provider manages Kubernetes applications using Helm charts.
# It's configured to connect to the GKE cluster and authenticate with
# the SettleMint OCI registry for BTP chart access.
# =============================================================================

provider "helm" {
  # Kubernetes cluster connection configuration
  kubernetes {
    # GKE cluster API server endpoint
    host                   = module.gke.endpoint
    # OAuth2 access token for cluster authentication
    token                  = data.google_client_config.default.access_token
    # Cluster CA certificate for TLS verification
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  }

  # SettleMint OCI registry configuration
  # This registry contains the private BTP Helm charts
  registry {
    # SettleMint OCI registry URL
    url      = "oci://registry.settlemint.com/settlemint-platform/settlemint"
    # Registry authentication credentials (provided by SettleMint)
    username = var.oci_registry_username
    password = var.oci_registry_password
  }
}

# =============================================================================
# KUBERNETES PROVIDER
# =============================================================================
# The Kubernetes provider manages native Kubernetes resources like
# namespaces, services, deployments, and RBAC configurations.
# =============================================================================

provider "kubernetes" {
  # GKE cluster API server endpoint with HTTPS protocol
  host                   = "https://${module.gke.endpoint}"
  # OAuth2 access token for cluster authentication
  token                  = data.google_client_config.default.access_token
  # Cluster CA certificate for TLS verification
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

# =============================================================================
# KUBECTL PROVIDER
# =============================================================================
# The kubectl provider allows direct application of YAML manifests
# and execution of kubectl commands. Used for resources not supported
# by the standard Kubernetes provider (e.g., cert-manager CRDs).
# =============================================================================

provider "kubectl" {
  # GKE cluster API server endpoint with HTTPS protocol
  host                   = "https://${module.gke.endpoint}"
  # OAuth2 access token for cluster authentication
  token                  = data.google_client_config.default.access_token
  # Cluster CA certificate for TLS verification
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

# =============================================================================
# RANDOM PROVIDER
# =============================================================================
# The random provider generates random values used for:
# - Unique resource naming (platform suffix)
# - Secure password generation (databases, services)
# - Cryptographic keys and tokens
# =============================================================================

provider "random" {
  # No configuration required - uses secure random number generation
}

# =============================================================================
# LOCAL PROVIDER
# =============================================================================
# The local provider handles local file operations and template processing.
# Used for generating configuration files from templates.
# =============================================================================

provider "local" {
  # No configuration required - operates on local filesystem
}
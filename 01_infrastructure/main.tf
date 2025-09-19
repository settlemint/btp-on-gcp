# =============================================================================
# MAIN INFRASTRUCTURE CONFIGURATION
# =============================================================================
# This file contains the core infrastructure components for the SettleMint
# Blockchain Transformation Platform (BTP) on Google Cloud Platform.
# It includes:
# - Google Kubernetes Engine (GKE) cluster setup
# - Kubernetes namespaces for organizing resources
# - Workload Identity configuration for secure service account access
# - Google Cloud KMS setup for Vault encryption
# =============================================================================

# Data source to get the current Google Cloud client configuration
# This provides access tokens and other authentication details needed
# by the Kubernetes and Helm providers to interact with the GKE cluster
data "google_client_config" "default" {}

# Generate a random suffix to ensure unique resource names
# This prevents naming conflicts when multiple BTP instances are deployed
# in the same GCP project or when redeploying after resource cleanup
resource "random_id" "platform_suffix" {
  byte_length = 4  # Creates an 8-character hex string (4 bytes = 8 hex chars)
}

# =============================================================================
# GOOGLE KUBERNETES ENGINE (GKE) CLUSTER
# =============================================================================
# This module creates a production-ready GKE cluster optimized for running
# the SettleMint BTP platform. The cluster is configured with:
# - Regional deployment for high availability
# - Auto-scaling node pools to handle variable workloads
# - Security features like Shielded GKE nodes
# - Necessary OAuth scopes for platform operations
# =============================================================================

module "gke" {
  # Using the official Google Cloud GKE Terraform module
  # This module provides best practices and simplified cluster management
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "36.3.0"

  # Basic cluster configuration
  project_id        = var.gcp_project_id
  name              = var.gcp_platform_name  # Cluster name in GCP Console
  regional          = true                   # Regional cluster for HA (vs zonal)
  region            = var.gcp_region
  
  # Network configuration - using default VPC for simplicity
  # In production, consider creating a custom VPC with private subnets
  network           = "default"
  subnetwork        = "default"
  ip_range_pods     = null  # Use default pod IP range
  ip_range_services = null  # Use default service IP range

  # Release channel determines the Kubernetes version and update cadence
  # STABLE provides a balance between new features and stability
  release_channel = "STABLE"

  # Node pool configuration
  # This defines the compute resources available to the BTP platform
  node_pools = [
    {
      name         = "default-node-pool"
      machine_type = "e2-standard-4"  # 4 vCPUs, 16GB RAM - suitable for BTP workloads
      min_count    = 1                # Minimum nodes for cost efficiency
      max_count    = 50               # Maximum nodes for handling peak loads
      disk_size_gb = 50               # Boot disk size per node
      disk_type    = "pd-balanced"    # Balanced persistent disk (good price/performance)
      image_type   = "COS_CONTAINERD" # Container-Optimized OS with containerd runtime
      auto_repair  = true             # Automatically repair unhealthy nodes
      auto_upgrade = true             # Automatically upgrade nodes with cluster
    }
  ]

  # OAuth scopes define what Google Cloud APIs the nodes can access
  # These scopes are required for BTP platform operations
  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/devstorage.read_only",      # Read from Cloud Storage
      "https://www.googleapis.com/auth/logging.write",            # Write logs to Cloud Logging
      "https://www.googleapis.com/auth/monitoring",               # Send metrics to Cloud Monitoring
      "https://www.googleapis.com/auth/servicecontrol",           # Service control (required)
      "https://www.googleapis.com/auth/service.management.readonly", # Service management (required)
      "https://www.googleapis.com/auth/trace.append"              # Send traces to Cloud Trace
    ]
  }

  # Security and operational settings
  enable_cost_allocation      = false # Cost allocation tracking (disabled for demo)
  enable_binary_authorization = false # Binary authorization (disabled for simplicity)
  gcs_fuse_csi_driver         = false # GCS FUSE CSI driver (not needed for BTP)
  deletion_protection         = false # Allow cluster deletion (enabled for demo cleanup)
  enable_shielded_nodes       = true  # Enable Shielded GKE nodes for security

  # Node pool management settings
  remove_default_node_pool   = true  # Remove the default node pool (we define our own)
  initial_node_count         = 1     # Initial number of nodes per zone
  default_max_pods_per_node  = 110   # Maximum pods per node (GKE default)
  
  # Cluster add-ons and features
  http_load_balancing        = true   # Enable HTTP load balancing (required for ingress)
  horizontal_pod_autoscaling = true   # Enable horizontal pod autoscaling
  network_policy             = false  # Disable network policy (Calico) for simplicity
  
  # Additional add-ons
  dns_cache         = false # Disable NodeLocal DNSCache (not needed for demo)
  gce_pd_csi_driver = true  # Enable Persistent Disk CSI driver (required for storage)
}


# =============================================================================
# KUBERNETES NAMESPACES
# =============================================================================
# These namespaces organize the BTP platform components and dependencies
# into logical groups for better resource management and security isolation.
# =============================================================================

# Namespace for cluster-level dependencies (databases, message queues, etc.)
# This includes PostgreSQL, Redis, MinIO, Vault, cert-manager, and ingress-nginx
resource "kubernetes_namespace" "cluster_dependencies_namespace" {
  depends_on = [module.gke]  # Ensure cluster exists before creating namespace
  
  metadata {
    annotations = {
      name = var.dependencies_namespace
    }
    name = var.dependencies_namespace  # Default: "cluster-dependencies"
  }
}

# Namespace for BTP application deployments created by users
# This is where blockchain networks and smart contracts will be deployed
resource "kubernetes_namespace" "deployment_namespace" {
  depends_on = [module.gke]  # Ensure cluster exists before creating namespace
  
  metadata {
    annotations = {
      name = var.deployment_namespace
    }
    name = var.deployment_namespace  # Default: "deployments"
  }
}

# Namespace for the core SettleMint BTP platform components
# This includes the web UI, API, deployment engine, and cluster manager
resource "kubernetes_namespace" "settlemint" {
  depends_on = [module.gke]  # Ensure cluster exists before creating namespace
  
  metadata {
    annotations = {
      name = "settlemint"
    }
    name = "settlemint"  # Fixed namespace name for BTP platform
  }
}

# =============================================================================
# WORKLOAD IDENTITY CONFIGURATION
# =============================================================================
# Workload Identity allows Kubernetes service accounts to act as Google Cloud
# service accounts without storing service account keys in the cluster.
# This provides secure, keyless authentication for GCP services.
# =============================================================================

# Workload Identity for cert-manager
# This allows cert-manager to manage DNS records for Let's Encrypt certificate validation
module "cert_manager_workload_identity" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  
  # Create a new Kubernetes service account (don't use existing)
  use_existing_k8s_sa = false
  
  # Cluster configuration
  cluster_name = "${var.gcp_platform_name}-${random_id.platform_suffix.hex}"
  location     = var.gcp_region
  
  # Service account naming (must be unique across GCP project)
  name = "${var.cert_manager_workload_identity}-${random_id.platform_suffix.hex}"
  
  # Grant DNS admin role to manage Cloud DNS records for certificate validation
  roles = ["roles/dns.admin"]
  
  # Deploy in the dependencies namespace where cert-manager runs
  namespace = var.dependencies_namespace
  
  # GCP project configuration
  project_id = var.gcp_project_id
  
  # Allow automatic mounting of service account token in pods
  automount_service_account_token = true
  
  # Ensure namespace exists before creating workload identity
  depends_on = [kubernetes_namespace.cluster_dependencies_namespace]
}

# Workload Identity for external-dns
# This allows external-dns to automatically create DNS records for ingress resources
module "external_dns_workload_identity" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  
  # Create a new Kubernetes service account (don't use existing)
  use_existing_k8s_sa = false
  
  # Cluster configuration
  cluster_name = "${var.gcp_platform_name}-${random_id.platform_suffix.hex}"
  location     = var.gcp_region
  
  # Service account naming (must be unique across GCP project)
  name = "${var.external_dns_workload_identity}-${random_id.platform_suffix.hex}"
  
  # Grant DNS admin role to manage Cloud DNS records for services
  roles = ["roles/dns.admin"]
  
  # Deploy in the settlemint namespace where external-dns runs
  namespace = "settlemint"
  
  # GCP project configuration
  project_id = var.gcp_project_id
  
  # Allow automatic mounting of service account token in pods
  automount_service_account_token = true
  
  # Ensure namespace exists before creating workload identity
  depends_on = [kubernetes_namespace.settlemint]
}

# =============================================================================
# GOOGLE CLOUD KMS (KEY MANAGEMENT SERVICE)
# =============================================================================
# KMS provides encryption keys for HashiCorp Vault auto-unsealing.
# This eliminates the need to manually unseal Vault after restarts
# and provides enterprise-grade key management and security.
# =============================================================================

# Create the KMS Key Ring
# A key ring is a logical grouping of cryptographic keys in a specific location
resource "google_kms_key_ring" "vault_key_ring" {
  # Unique name with random suffix to avoid conflicts
  name = "${var.gcp_key_ring_name}-${random_id.platform_suffix.hex}"
  
  # GCP project where the key ring will be created
  project = var.gcp_project_id
  
  # Location for the key ring (must match Vault's region for optimal performance)
  location = var.gcp_region
}

# Create the KMS Crypto Key
# This key will be used by Vault for auto-unsealing operations
resource "google_kms_crypto_key" "vault_crypto_key" {
  # Name of the cryptographic key
  name = var.gcp_crypto_key_name
  
  # Reference to the key ring that will contain this key
  key_ring = google_kms_key_ring.vault_key_ring.id
  
  # The key will be created with default settings:
  # - Purpose: ENCRYPT_DECRYPT (suitable for Vault unsealing)
  # - Algorithm: GOOGLE_SYMMETRIC_ENCRYPTION
  # - Rotation: Manual (can be automated in production)
}

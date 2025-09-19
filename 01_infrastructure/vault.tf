# =============================================================================
# HASHICORP VAULT CONFIGURATION
# =============================================================================
# HashiCorp Vault provides enterprise-grade secrets management for the BTP
# platform. This configuration includes:
# - Google Cloud KMS integration for automatic unsealing
# - Service account setup for secure GCP access
# - Secret engines for different blockchain types
# - AppRole authentication for BTP platform access
# - Automated initialization and configuration
# =============================================================================

# =============================================================================
# GOOGLE CLOUD SERVICE ACCOUNT FOR VAULT
# =============================================================================
# This service account allows Vault to access Google Cloud KMS for auto-unsealing.
# Auto-unsealing eliminates the need for manual unsealing after Vault restarts.
# =============================================================================

module "service_accounts" {
  # Using the official Google Cloud service accounts Terraform module
  source        = "terraform-google-modules/service-accounts/google"
  version       = "4.5.4"
  
  # GCP project where the service account will be created
  project_id    = var.gcp_project_id
  
  # Unique prefix to avoid naming conflicts
  prefix        = "vault-${random_id.platform_suffix.hex}"
  
  # Service account name (will be prefixed)
  names         = ["unseal-sa"]
  
  # IAM roles required for KMS access
  project_roles = [
    # Permission to encrypt/decrypt with KMS keys
    "${var.gcp_project_id}=>roles/cloudkms.cryptoKeyEncrypterDecrypter",
    # Permission to view KMS resources
    "${var.gcp_project_id}=>roles/cloudkms.viewer",
  ]
  
  # Generate service account keys for authentication
  generate_keys = true
}

# =============================================================================
# KUBERNETES CONFIGMAP FOR SERVICE ACCOUNT CREDENTIALS
# =============================================================================
# This ConfigMap stores the Google Cloud service account credentials that
# Vault will use to authenticate with Google Cloud KMS for auto-unsealing.
# =============================================================================

resource "kubernetes_config_map" "vault_gcp_sa" {
  metadata {
    # ConfigMap name (configurable via variable)
    name      = var.vault_gcp_sa
    # Deploy in the dependencies namespace where Vault runs
    namespace = var.dependencies_namespace
  }

  # Store the service account key as a JSON file
  data = {
    "credentials.json" = module.service_accounts.keys["unseal-sa"]
  }
}

# =============================================================================
# VAULT HELM CHART DEPLOYMENT
# =============================================================================
# Deploys HashiCorp Vault using the official Helm chart with:
# - Google Cloud KMS auto-unsealing configuration
# - File storage backend for persistent data
# - Service account credentials mounting
# - UI enabled for administrative access
# =============================================================================

resource "helm_release" "vault" {
  # Helm release name
  name             = "vault"
  # Official HashiCorp Helm repository
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  version          = "0.30.1"  # Stable version with GCP KMS support
  
  # Deploy in dependencies namespace
  namespace        = var.dependencies_namespace
  create_namespace = true

  # Configure persistent storage for Vault data
  set {
    name  = "server.dataStorage.size"
    value = "1Gi"  # 1GB sufficient for demo; increase for production
  }

  # Environment variables for Google Cloud KMS integration
  set {
    name  = "server.extraEnvironmentVars.GOOGLE_REGION"
    value = var.gcp_region
  }

  set {
    name  = "server.extraEnvironmentVars.GOOGLE_PROJECT"
    value = var.gcp_project_id
  }

  # Path to Google Cloud service account credentials
  set {
    name  = "server.extraEnvironmentVars.GOOGLE_APPLICATION_CREDENTIALS"
    value = "/vault/userconfig/vault-gcp-sa/credentials.json"
  }

  # Mount the service account credentials ConfigMap as a volume
  set {
    name  = "server.volumes[0].name"
    value = var.vault_gcp_sa
  }

  set {
    name  = "server.volumes[0].configMap.name"
    value = kubernetes_config_map.vault_gcp_sa.metadata[0].name
  }

  # Mount the volume inside the Vault container
  set {
    name  = "server.volumeMounts[0].name"
    value = var.vault_gcp_sa
  }

  set {
    name  = "server.volumeMounts[0].mountPath"
    value = "/vault/userconfig/${var.vault_gcp_sa}"
  }

  # Vault server configuration in HCL format
  set {
    name  = "server.standalone.config"
    value = <<-EOT
      # Enable Vault UI for administrative access
      ui = true

      # TCP listener configuration
      listener "tcp" {
        tls_disable = 1                    # Disable TLS (handled by ingress)
        address = "[::]:8200"              # Listen on all interfaces
        cluster_address = "[::]:8201"      # Cluster communication port
        # Enable unauthenticated metrics access (necessary for Prometheus Operator)
        #telemetry {
        #  unauthenticated_metrics_access = "true"
        #}
      }
      
      # File storage backend (simple for demo; use integrated storage for production)
      storage "file" {
        path = "/vault/data"
      }

      # Google Cloud KMS auto-unseal configuration
      # This eliminates the need for manual unsealing after restarts
      seal "gcpckms" {
        project     = "${var.gcp_project_id}"
        region      = "${var.gcp_region}"
        key_ring    = "${var.gcp_key_ring_name}-${random_id.platform_suffix.hex}"
        crypto_key  = "${var.gcp_crypto_key_name}"
      }
    EOT
  }

  # Ensure all dependencies are ready before deploying Vault
  depends_on = [module.gke, google_kms_crypto_key.vault_crypto_key, kubernetes_namespace.cluster_dependencies_namespace, google_kms_key_ring.vault_key_ring]
}

# =============================================================================
# RBAC CONFIGURATION FOR VAULT INITIALIZATION
# =============================================================================
# These RBAC resources allow the initialization jobs to interact with
# Vault pods and manage ConfigMaps for storing initialization output.
# =============================================================================

# Kubernetes Role with permissions needed for Vault initialization
resource "kubernetes_role" "vault_access" {
  metadata {
    name      = "vault-access"
    namespace = var.dependencies_namespace
  }
  
  # Define permissions for Vault initialization operations
  rule {
    api_groups = [""]
    resources  = [
      "pods",          # Access to Vault pods
      "pods/exec",     # Execute commands in Vault pods
      "pods/log",      # Read pod logs for debugging
      "configmaps"     # Create/manage ConfigMaps for storing secrets
    ]
    verbs      = ["get", "list", "watch", "create", "delete"]
  }

  depends_on = [ helm_release.vault ]
}

# Bind the vault-access role to the default service account
# This allows initialization jobs to perform Vault operations
resource "kubernetes_role_binding" "vault_access_binding" {
  metadata {
    name      = "vault-access-binding"
    namespace = var.dependencies_namespace
  }
  
  # Reference to the role defined above
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.vault_access.metadata[0].name
  }
  
  # Bind to the default service account in the namespace
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = var.dependencies_namespace
  }
  
  depends_on = [ helm_release.vault ]
}

# =============================================================================
# VAULT INITIALIZATION JOB
# =============================================================================
# This Kubernetes Job initializes Vault by:
# - Waiting for Vault pod to be ready
# - Running 'vault operator init' to generate unseal keys and root token
# - Storing the initialization output in a ConfigMap for later use
# 
# Note: This is a one-time operation that creates the master key shares
# and initial root token. The unseal keys are not needed due to auto-unsealing.
# =============================================================================

resource "kubernetes_job" "vault_init" {
  metadata {
    name      = "vault-init"
    namespace = var.dependencies_namespace
  }
  
  spec {
    template {
      metadata {
        name = "vault-init"
      }
      
      spec {
        # Use default service account with vault-access permissions
        service_account_name = "default"
        
        container {
          name  = "vault-init"
          # Using Bitnami kubectl image for reliable Kubernetes operations
          image = "bitnami/kubectl:latest"
          
          # Shell script to initialize Vault
          command = [
            "sh", "-c",
            <<EOF
# Wait for Vault pod to be in Running state before initialization
while [ "$(kubectl get pod vault-0 -n ${var.dependencies_namespace} -o jsonpath='{.status.phase}')" != "Running" ]; do
  echo "Waiting for vault-0 pod to be in Running state..."
  sleep 2
done

# Clean up any existing initialization output
if kubectl get configmap vault-init-output -n ${var.dependencies_namespace}; then
  kubectl delete configmap vault-init-output -n ${var.dependencies_namespace}
fi

# Initialize Vault and capture output
# This generates unseal keys and root token (unseal keys not needed with auto-unseal)
kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault operator init > /mnt/vault-init.txt
cat /mnt/vault-init.txt

# Store initialization output in ConfigMap for later retrieval
kubectl create configmap vault-init-output -n ${var.dependencies_namespace} --from-file=/mnt/vault-init.txt
EOF
          ]
          
          # Mount temporary volume for storing initialization output
          volume_mount {
            name       = "vault-init"
            mount_path = "/mnt"
          }
        }
        
        # Temporary storage for initialization output
        volume {
          name = "vault-init"
          empty_dir {}
        }
        
        # Job should not restart on failure
        restart_policy = "Never"
      }
    }
    
    # No retries - initialization should succeed on first attempt
    backoff_limit = 0
  }
  
  # Ensure Vault is deployed and KMS key is available
  depends_on = [helm_release.vault, google_kms_crypto_key.vault_crypto_key]
}

# =============================================================================
# VAULT INITIALIZATION OUTPUT DATA SOURCE
# =============================================================================
# Retrieves the Vault initialization output from the ConfigMap created by
# the initialization job. This contains the root token needed for further
# Vault configuration operations.
# =============================================================================

data "kubernetes_config_map" "vault_init_output" {
  metadata {
    name      = "vault-init-output"
    namespace = var.dependencies_namespace
  }

  # Wait for initialization job to complete
  depends_on = [kubernetes_job.vault_init]
}

# =============================================================================
# EXTRACT ROOT TOKEN FROM INITIALIZATION OUTPUT
# =============================================================================
# Parse the Vault initialization output to extract the root token.
# This token has full administrative privileges and is used for initial
# Vault configuration (secret engines, policies, auth methods).
# =============================================================================

locals {
  # Use regex to extract the root token from initialization output
  # Format: "Initial Root Token: hvs.XXXXXXXXXXXXXXXXXXXX"
  root_token = regex("Initial Root Token: (.+)", data.kubernetes_config_map.vault_init_output.data["vault-init.txt"])[0]
}

# =============================================================================
# VAULT CONFIGURATION JOB
# =============================================================================
# This job configures Vault with the necessary secret engines, policies,
# and authentication methods required by the BTP platform:
# 
# Secret Engines:
# - ethereum/ : For Ethereum private keys and wallet data
# - ipfs/     : For IPFS node keys and configurations
# - fabric/   : For Hyperledger Fabric certificates and MSP data
# 
# Authentication:
# - AppRole   : Machine-to-machine authentication for BTP platform
# 
# Policies:
# - ethereum  : Access control for Ethereum secrets
# - ipfs      : Access control for IPFS secrets  
# - fabric    : Access control for Fabric secrets
# =============================================================================

resource "kubernetes_job" "vault_configure" {
  metadata {
    name      = "vault-configure"
    namespace = var.dependencies_namespace
  }
  
  spec {
    template {
      metadata {
        name = "vault-configure"
      }
      
      spec {
        container {
          name  = "vault-configure"
          # Using Bitnami kubectl image for Kubernetes and Vault operations
          image = "bitnami/kubectl:latest"
          
          # Provide root token as environment variable
          env {
            name  = "VAULT_TOKEN"
            value = local.root_token
          }
          
          # Complex shell script to configure Vault
          command = [
            "sh", "-c",
            <<EOF
# Create a comprehensive Vault configuration script
echo 'kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault login ${local.root_token}

# Enable KV-v2 secret engines for different blockchain types
# These engines store key-value pairs with versioning support
if ! kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault secrets list | grep -q "ethereum/"; then
  kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault secrets enable -path=ethereum kv-v2
fi
if ! kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault secrets list | grep -q "ipfs/"; then
  kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault secrets enable -path=ipfs kv-v2
fi
if ! kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault secrets list | grep -q "fabric/"; then
  kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault secrets enable -path=fabric kv-v2
fi

# Enable AppRole authentication method for machine-to-machine access
if ! kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault auth list | grep -q "approle/"; then
  kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault auth enable approle
fi

# Create policy for Ethereum secrets access
echo "path \\"ethereum/*\\" {
  capabilities = [\\"create\\", \\"read\\", \\"update\\", \\"delete\\", \\"list\\"]
}" > /tmp/ethereum-policy.hcl
kubectl cp /tmp/ethereum-policy.hcl ${var.dependencies_namespace}/vault-0:/tmp/ethereum-policy.hcl
kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault policy write ethereum /tmp/ethereum-policy.hcl

# Create policy for IPFS secrets access
echo "path \\"ipfs/*\\" {
  capabilities = [\\"create\\", \\"read\\", \\"update\\", \\"delete\\", \\"list\\"]
}" > /tmp/ipfs-policy.hcl
kubectl cp /tmp/ipfs-policy.hcl ${var.dependencies_namespace}/vault-0:/tmp/ipfs-policy.hcl
kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault policy write ipfs /tmp/ipfs-policy.hcl

# Create policy for Hyperledger Fabric secrets access
echo "path \\"fabric/*\\" {
  capabilities = [\\"create\\", \\"read\\", \\"update\\", \\"delete\\", \\"list\\"]
}" > /tmp/fabric-policy.hcl
kubectl cp /tmp/fabric-policy.hcl ${var.dependencies_namespace}/vault-0:/tmp/fabric-policy.hcl
kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault policy write fabric /tmp/fabric-policy.hcl

# Create AppRole for BTP platform with combined policies
# Token TTL: 1 hour (renewable)
# Max TTL: 4 hours (maximum token lifetime)
# Secret ID TTL: 0 (never expires - suitable for long-running applications)
kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault write auth/approle/role/platform-role token_ttl=1h token_max_ttl=4h secret_id_ttl=0 policies="ethereum,ipfs,fabric"' > /tmp/vault-configure.sh

# Execute the configuration script
sh /tmp/vault-configure.sh
EOF
          ]
          
          # Mount temporary volume for script storage
          volume_mount {
            name       = "vault-configure"
            mount_path = "/tmp"
          }
        }
        
        # Temporary storage for configuration scripts
        volume {
          name = "vault-configure"
          empty_dir {}
        }
        
        # Job should not restart on failure
        restart_policy = "Never"
      }
    }
    
    # No retries - configuration should succeed on first attempt
    backoff_limit = 0
  }
  
  # Wait for Vault initialization to complete
  depends_on = [kubernetes_job.vault_init]
}

# =============================================================================
# VAULT APPROLE CREDENTIALS RETRIEVAL JOB
# =============================================================================
# This job retrieves the AppRole credentials (role_id and secret_id) that
# the BTP platform will use for authentication with Vault. These credentials
# are stored in a ConfigMap for use by the BTP platform deployment.
# 
# AppRole Authentication Flow:
# 1. BTP platform presents role_id and secret_id to Vault
# 2. Vault validates credentials and returns a time-limited token
# 3. BTP platform uses token to access secrets in enabled paths
# =============================================================================

resource "kubernetes_job" "vault_get_approle_ids" {
  metadata {
    name      = "vault-get-approle-ids"
    namespace = var.dependencies_namespace
  }
  
  spec {
    template {
      metadata {
        name = "vault-get-approle-ids"
      }
      
      spec {
        # Use default service account with vault-access permissions
        service_account_name = "default"
        
        container {
          name  = "vault-get-approle-ids"
          # Using Bitnami kubectl image for Vault operations
          image = "bitnami/kubectl:latest"
          
          # Shell script to retrieve AppRole credentials
          command = [
            "sh", "-c",
            <<EOF
# Retrieve the role_id (static identifier for the AppRole)
role_id=`kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault read -field=role_id auth/approle/role/platform-role/role-id`

# Generate a new secret_id (dynamic credential paired with role_id)
secret_id=`kubectl exec vault-0 -n ${var.dependencies_namespace} -- vault write -force -field=secret_id auth/approle/role/platform-role/secret-id`

# Create a file with both credentials
echo "role_id=$${role_id}" > /mnt/vault-approle-ids.txt
echo "secret_id=$${secret_id}" >> /mnt/vault-approle-ids.txt

# Clean up any existing ConfigMap
if kubectl get configmap vault-approle-ids -n ${var.dependencies_namespace}; then
  kubectl delete configmap vault-approle-ids -n ${var.dependencies_namespace}
fi

# Store credentials in ConfigMap for BTP platform access
kubectl create configmap vault-approle-ids -n ${var.dependencies_namespace} --from-file=/mnt/vault-approle-ids.txt
EOF
          ]
          
          # Mount temporary volume for credential storage
          volume_mount {
            name       = "vault-get-approle-ids"
            mount_path = "/mnt"
          }
        }
        
        # Temporary storage for credentials file
        volume {
          name = "vault-get-approle-ids"
          empty_dir {}
        }
        
        # Job should not restart on failure
        restart_policy = "Never"
      }
    }
    
    # No retries - credential retrieval should succeed on first attempt
    backoff_limit = 0
  }
  
  # Wait for Vault configuration to complete
  depends_on = [kubernetes_job.vault_configure]
}

# =============================================================================
# VAULT APPROLE CREDENTIALS DATA SOURCE
# =============================================================================
# Retrieves the AppRole credentials from the ConfigMap created by the
# credential retrieval job. These credentials are used by Terraform to
# configure the BTP platform's Vault authentication.
# =============================================================================

data "kubernetes_config_map" "vault_approle_ids" {
  metadata {
    name      = "vault-approle-ids"
    namespace = var.dependencies_namespace
  }

  # Wait for credential retrieval job to complete
  depends_on = [kubernetes_job.vault_get_approle_ids]
}

# =============================================================================
# EXTRACT APPROLE CREDENTIALS FROM CONFIGMAP
# =============================================================================
# Parse the AppRole credentials file to extract role_id and secret_id.
# These credentials will be used by the BTP platform to authenticate
# with Vault and access blockchain secrets.
# =============================================================================

locals {
  # Extract role_id using regex pattern matching
  # Format: "role_id=role-id-uuid-string"
  role_id   = regex("role_id=(.+)", data.kubernetes_config_map.vault_approle_ids.data["vault-approle-ids.txt"])[0]
  
  # Extract secret_id using regex pattern matching  
  # Format: "secret_id=secret-id-uuid-string"
  secret_id = regex("secret_id=(.+)", data.kubernetes_config_map.vault_approle_ids.data["vault-approle-ids.txt"])[0]
}

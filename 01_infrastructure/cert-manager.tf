# =============================================================================
# CERT-MANAGER CONFIGURATION
# =============================================================================
# cert-manager is a Kubernetes add-on that automates the management and
# issuance of TLS certificates from various issuing sources, including
# Let's Encrypt. It's essential for providing HTTPS access to the BTP platform.
# 
# Key features:
# - Automatic certificate provisioning and renewal
# - Integration with Let's Encrypt for free SSL certificates
# - DNS-01 challenge support for wildcard certificates
# - Integration with Google Cloud DNS via Workload Identity
# =============================================================================

# Deploy cert-manager using the official Helm chart
resource "helm_release" "cert_manager" {
  # Helm release name
  name = "cert-manager"

  # Official cert-manager Helm repository
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.18.2"  # Stable version with good GCP integration
  
  # Deploy in the dependencies namespace
  namespace  = var.dependencies_namespace

  # Don't create a new service account - use the one from Workload Identity
  # This enables secure access to Google Cloud DNS without storing keys
  set {
    name  = "serviceAccount.create"
    value = false
  }

  # Use the service account created by the Workload Identity module
  # This service account has DNS admin permissions for certificate validation
  set {
    name  = "serviceAccount.name"
    value = "${var.cert_manager_workload_identity}-${random_id.platform_suffix.hex}"
  }

  # Install Custom Resource Definitions (CRDs) for cert-manager
  # These define Certificate, Issuer, and ClusterIssuer resources
  set {
    name  = "crds.enabled"
    value = "true"
  }

  # Ensure dependencies are ready before deploying cert-manager
  depends_on = [module.cert_manager_workload_identity, kubernetes_namespace.cluster_dependencies_namespace]
}


# =============================================================================
# LET'S ENCRYPT CLUSTER ISSUER
# =============================================================================
# This ClusterIssuer configures cert-manager to obtain SSL certificates from
# Let's Encrypt using DNS-01 challenge validation. This approach allows for
# wildcard certificates and works even when services are not publicly accessible.
# =============================================================================

resource "kubectl_manifest" "cluster_issuer" {
  # Disable schema validation for custom resources
  validate_schema = false
  
  # Define the ClusterIssuer resource using YAML
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
  namespace: ${var.dependencies_namespace}
spec:
  acme:
    # Email address for Let's Encrypt account registration and notifications
    # This should be a valid email address for certificate expiry warnings
    email: trial-demo@settlemint.com
    
    # Let's Encrypt ACME server URL (production endpoint)
    # For testing, you can use: https://acme-staging-v02.api.letsencrypt.org/directory
    server: https://acme-v02.api.letsencrypt.org/directory
    
    # Secret to store the ACME account private key
    privateKeySecretRef:
      name: example-issuer-account-key
    
    # Challenge solvers for domain validation
    solvers:
    - dns01:
        # Use Google Cloud DNS for DNS-01 challenge
        # This allows cert-manager to create DNS records to prove domain ownership
        cloudDNS:
          # GCP project containing the DNS zone
          project: ${var.gcp_project_id}
          # Authentication is handled via Workload Identity (no service account key needed)
YAML

  # Ensure cert-manager is deployed before creating the issuer
  depends_on = [helm_release.cert_manager]
}


# =============================================================================
# SSL CERTIFICATE REQUEST
# =============================================================================
# This Certificate resource requests a wildcard SSL certificate from Let's Encrypt
# for the BTP platform domain. The certificate will be automatically provisioned
# and renewed by cert-manager using DNS-01 challenge validation.
# =============================================================================

resource "kubectl_manifest" "certificate" {
  # Define the Certificate resource using YAML
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  # Certificate resource name (for identification in Kubernetes)
  name: ${var.gcp_platform_name}
  # Deploy in dependencies namespace where ingress-nginx can access it
  namespace: ${var.dependencies_namespace}
spec:
  # Name of the Kubernetes secret that will store the certificate and private key
  # This secret will be used by ingress-nginx for HTTPS termination
  secretName: nginx-tls-secret
  
  # Reference to the ClusterIssuer that will provide the certificate
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  
  # Domain names to include in the certificate
  dnsNames:
  - ${var.gcp_dns_zone}        # Main domain (e.g., btp.example.com)
  - "*.${var.gcp_dns_zone}"    # Wildcard for subdomains (e.g., *.btp.example.com)
  
  # The certificate will include both the main domain and all subdomains
  # This allows services like grafana.btp.example.com, logs.btp.example.com, etc.
YAML

  # Ensure the ClusterIssuer exists before requesting certificates
  depends_on = [kubectl_manifest.cluster_issuer]
}
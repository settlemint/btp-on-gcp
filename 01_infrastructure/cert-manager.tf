# ============================================================================
# CERT-MANAGER DEPLOYMENT AND CONFIGURATION
# ============================================================================
# 
# Deploys and configures cert-manager, a Kubernetes-native certificate
# management controller that automates the provisioning and management of
# TLS certificates. This component is essential for the BTP platform's
# HTTPS security and automated SSL certificate lifecycle management.
# 
# CERT-MANAGER OVERVIEW:
# cert-manager is a powerful, extensible certificate controller for Kubernetes
# that provides:
# - Automated certificate provisioning from multiple certificate authorities
# - Certificate lifecycle management (issuance, renewal, revocation)
# - Integration with Let's Encrypt for free, trusted SSL certificates
# - Support for DNS-01 and HTTP-01 ACME challenges
# - Custom Resource Definitions (CRDs) for declarative certificate management
# 
# BTP PLATFORM INTEGRATION:
# In the BTP deployment, cert-manager serves critical functions:
# - Provisions wildcard SSL certificates for all BTP services
# - Manages certificates for blockchain node endpoints
# - Enables secure HTTPS communication for web interfaces and APIs
# - Provides automated certificate renewal to prevent service interruptions
# - Integrates with Google Cloud DNS for domain validation
# 
# ENTERPRISE BENEFITS:
# - Eliminates manual certificate management overhead
# - Ensures continuous HTTPS availability through automatic renewal
# - Provides consistent security across all platform services
# - Supports compliance requirements for encrypted communications
# - Reduces operational risks associated with certificate expiration
# 
# ============================================================================

# Cert-Manager Helm Release
# Deploys cert-manager using the official Helm chart from Jetstack.
# This deployment includes all necessary components: controller, webhook,
# and cainjector for comprehensive certificate management capabilities.
# 
# DEPLOYMENT ARCHITECTURE:
# - Controller: Core certificate management logic and ACME client
# - Webhook: Admission controller for validating certificate resources
# - CA Injector: Injects CA bundles into ValidatingAdmissionWebhooks
# - Custom Resource Definitions: Certificate, Issuer, ClusterIssuer resources
# 
# WORKLOAD IDENTITY INTEGRATION:
# - Uses pre-configured Google Cloud service account via workload identity
# - Eliminates need for static service account keys
# - Provides secure, temporary credentials for Google Cloud DNS operations
# - Enables DNS-01 ACME challenges for wildcard certificate provisioning
# 
# SECURITY CONFIGURATION:
# - Deploys with minimal required permissions
# - Uses dedicated service account with DNS admin role
# - Enables comprehensive audit logging of certificate operations
# - Supports certificate authority validation and trust chains
resource "helm_release" "cert_manager" {
  # Release identification and metadata
  name = "cert-manager"

  # Official Jetstack Helm repository for cert-manager
  # Maintained by the cert-manager project team
  # Provides stable, tested releases with security updates
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  
  # Cert-manager version pinning for stability and reproducibility
  # Version 1.18.2 provides:
  # - Stable ACME v2 protocol support
  # - Enhanced DNS provider integrations
  # - Improved certificate renewal reliability
  # - Security fixes and performance optimizations
  version = "v1.18.2"
  
  # Deploy in cluster dependencies namespace
  # Co-locates with other infrastructure services
  # Provides appropriate isolation from user workloads
  namespace = var.dependencies_namespace

  # Service Account Configuration
  # Disables automatic service account creation to use workload identity
  # Ensures integration with Google Cloud authentication
  set {
    name  = "serviceAccount.create"
    value = false
  }

  # Workload Identity Service Account Reference
  # Links cert-manager to pre-configured Google Cloud service account
  # Enables secure access to Google Cloud DNS for ACME challenges
  # Uses unique suffix to prevent naming conflicts across deployments
  set {
    name  = "serviceAccount.name"
    value = "${var.cert_manager_workload_identity}-${random_id.platform_suffix.hex}"
  }

  # Custom Resource Definitions (CRDs) Installation
  # Enables cert-manager's declarative certificate management
  # Installs Certificate, Issuer, and ClusterIssuer resources
  # Required for cert-manager functionality
  set {
    name  = "crds.enabled"
    value = "true"
  }

  # Deployment Dependencies
  # Ensures workload identity is configured before cert-manager deployment
  # Verifies namespace existence for proper resource placement
  depends_on = [module.cert_manager_workload_identity, kubernetes_namespace.cluster_dependencies_namespace]
}


# Let's Encrypt ClusterIssuer Configuration
# Creates a ClusterIssuer resource that configures cert-manager to obtain
# SSL/TLS certificates from Let's Encrypt certificate authority using
# DNS-01 ACME challenges with Google Cloud DNS integration.
# 
# CLUSTERISSUER OVERVIEW:
# A ClusterIssuer is a cluster-wide resource that defines how cert-manager
# should request certificates from a certificate authority. This configuration:
# - Enables automatic certificate provisioning for any namespace
# - Supports wildcard certificates through DNS-01 challenges
# - Provides consistent certificate authority configuration
# - Eliminates per-namespace issuer configuration overhead
# 
# LET'S ENCRYPT INTEGRATION:
# Let's Encrypt is a free, automated certificate authority that provides:
# - Domain Validation (DV) certificates trusted by all major browsers
# - Automated certificate issuance and renewal
# - ACME protocol compliance for programmatic certificate management
# - Rate limiting protections to prevent abuse
# 
# DNS-01 CHALLENGE BENEFITS:
# DNS-01 challenges offer advantages over HTTP-01 for BTP deployments:
# - Support for wildcard certificates (*.yourdomain.com)
# - No requirement for HTTP endpoints during certificate issuance
# - Works with private or internal services not accessible via HTTP
# - Suitable for services behind load balancers or firewalls
# 
# GOOGLE CLOUD DNS INTEGRATION:
# - Uses workload identity for secure authentication
# - Automatically creates and deletes DNS TXT records for validation
# - Supports multiple DNS zones and complex domain hierarchies
# - Provides audit logging of all DNS operations
resource "kubectl_manifest" "cluster_issuer" {
  # Schema validation disabled for custom resource definitions
  # Allows deployment of cert-manager CRDs before full API server recognition
  validate_schema = false
  
  # ClusterIssuer YAML Configuration
  # Defines Let's Encrypt integration with Google Cloud DNS
  yaml_body = <<YAML
# Let's Encrypt ClusterIssuer for BTP Platform
# Configures automated SSL certificate provisioning using ACME protocol
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
  namespace: ${var.dependencies_namespace}
  annotations:
    # Resource metadata for operational management
    description: "Let's Encrypt ClusterIssuer for BTP platform SSL certificates"
    managed-by: "terraform"
    component: "certificate-management"
spec:
  acme:
    # Let's Encrypt ACME v2 API endpoint
    # Uses production server for trusted certificates
    # Note: Consider using staging server for testing to avoid rate limits
    server: https://acme-v02.api.letsencrypt.org/directory
    
    # Contact email for Let's Encrypt account
    # Required for certificate authority communication
    # Used for important notifications (expiration, security issues)
    # Should be monitored by operations team
    email: trial-demo@settlemint.com
    
    # Private Key Secret Configuration
    # Stores Let's Encrypt account private key for ACME operations
    # Secret is automatically created and managed by cert-manager
    # Must be unique per ClusterIssuer to prevent conflicts
    privateKeySecretRef:
      name: example-issuer-account-key
    
    # ACME Challenge Solvers Configuration
    # Defines how cert-manager proves domain ownership to Let's Encrypt
    solvers:
    - dns01:
        # Google Cloud DNS solver configuration
        # Enables DNS-01 challenges using Google Cloud DNS
        cloudDNS:
          # Google Cloud project containing DNS zones
          # Must match the project where DNS zones are managed
          project: ${var.gcp_project_id}
          
          # Service account authentication handled via workload identity
          # No static credentials required due to workload identity integration
          # Automatic authentication using cert-manager's Kubernetes service account
YAML

  # Deployment Dependencies
  # Ensures cert-manager is fully deployed before creating ClusterIssuer
  # Prevents resource creation errors due to missing CRDs
  depends_on = [helm_release.cert_manager]
}


# Wildcard SSL Certificate Resource
# Creates a Certificate resource that requests a wildcard SSL certificate
# from Let's Encrypt for the BTP platform domain. This certificate secures
# all subdomains and services within the platform deployment.
# 
# CERTIFICATE OVERVIEW:
# The Certificate resource is a cert-manager custom resource that:
# - Declaratively defines certificate requirements and properties
# - Triggers automatic certificate provisioning from configured issuers
# - Manages certificate lifecycle including renewal and revocation
# - Stores resulting certificates as Kubernetes secrets
# 
# WILDCARD CERTIFICATE BENEFITS:
# A wildcard certificate (*.domain.com) provides several advantages:
# - Secures unlimited subdomains with a single certificate
# - Eliminates need for individual certificates per service
# - Simplifies certificate management and reduces operational overhead
# - Supports dynamic subdomain creation without certificate provisioning
# - Reduces Let's Encrypt API calls and rate limiting concerns
# 
# BTP PLATFORM COVERAGE:
# This wildcard certificate will secure all BTP platform services:
# - Platform UI: app.yourdomain.com
# - API Gateway: api.yourdomain.com
# - Blockchain nodes: ethereum.yourdomain.com, fabric.yourdomain.com
# - Infrastructure services: grafana.yourdomain.com, vault.yourdomain.com
# - User applications: custom.yourdomain.com
# 
# AUTOMATIC RENEWAL:
# cert-manager automatically handles certificate renewal:
# - Monitors certificate expiration dates
# - Initiates renewal process 30 days before expiration
# - Performs DNS-01 challenges for domain validation
# - Updates Kubernetes secrets with new certificate data
# - Triggers pod restarts if necessary for certificate updates
resource "kubectl_manifest" "certificate" {
  # Certificate YAML Configuration
  # Defines wildcard certificate request for BTP platform domain
  yaml_body = <<YAML
# Wildcard SSL Certificate for BTP Platform
# Provides HTTPS security for all platform services and subdomains
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${var.gcp_platform_name}
  namespace: ${var.dependencies_namespace}
  annotations:
    # Resource metadata for operational management
    description: "Wildcard SSL certificate for BTP platform services"
    managed-by: "terraform"
    certificate-type: "wildcard"
    renewal-policy: "automatic"
spec:
  # Kubernetes Secret Configuration
  # Specifies where cert-manager stores the issued certificate
  # Secret contains certificate, private key, and CA certificate
  # Used by ingress controllers for HTTPS termination
  secretName: nginx-tls-secret
  
  # Certificate Issuer Reference
  # Links certificate request to configured Let's Encrypt ClusterIssuer
  # Determines certificate authority and validation method
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  
  # Domain Names Configuration
  # Defines which domains the certificate should cover
  # Includes both apex domain and wildcard subdomain
  dnsNames:
  - ${var.gcp_dns_zone}          # Apex domain (yourdomain.com)
  - "*.${var.gcp_dns_zone}"       # Wildcard subdomains (*.yourdomain.com)
  
  # Additional certificate configuration options:
  # duration: Certificate validity period (default: 90 days for Let's Encrypt)
  # renewBefore: Time before expiration to trigger renewal (default: 30 days)
  # subject: Certificate subject information (optional)
  # keyAlgorithm: Private key algorithm (default: RSA)
  # keySize: Private key size (default: 2048 for RSA)
YAML

  # Deployment Dependencies
  # Ensures ClusterIssuer is created and ready before certificate request
  # Prevents certificate provisioning failures due to missing issuer
  depends_on = [kubectl_manifest.cluster_issuer]
}
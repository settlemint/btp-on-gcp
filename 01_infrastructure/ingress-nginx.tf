# ============================================================================
# INGRESS NGINX CONTROLLER DEPLOYMENT AND DNS CONFIGURATION
# ============================================================================
# 
# Deploys and configures the NGINX Ingress Controller, which serves as the
# primary HTTP/HTTPS load balancer and reverse proxy for the BTP platform.
# This component provides external access to all platform services and
# manages SSL termination, routing, and traffic management.
# 
# INGRESS CONTROLLER OVERVIEW:
# The NGINX Ingress Controller is a Kubernetes-native load balancer that:
# - Provides HTTP/HTTPS load balancing for Kubernetes services
# - Manages SSL/TLS termination using automatically provisioned certificates
# - Supports advanced routing based on hostnames, paths, and headers
# - Offers traffic management features like rate limiting and authentication
# - Integrates with cert-manager for automatic certificate provisioning
# 
# BTP PLATFORM INTEGRATION:
# In the BTP deployment, the ingress controller serves critical functions:
# - Routes traffic to BTP web interfaces and APIs
# - Provides secure HTTPS access to blockchain node endpoints
# - Manages SSL certificates for all platform services
# - Enables external access to monitoring and management interfaces
# - Supports blue-green and canary deployment strategies
# 
# ENTERPRISE FEATURES:
# - High availability through Google Cloud Load Balancer integration
# - Automatic SSL certificate management via cert-manager integration
# - Comprehensive traffic monitoring and logging
# - Support for custom authentication and authorization policies
# - Integration with Google Cloud DNS for automatic DNS management
# 
# ============================================================================

# NGINX Ingress Controller Helm Release
# Deploys the official NGINX Ingress Controller using the community-maintained
# Helm chart. This provides a production-ready HTTP/HTTPS load balancer
# with comprehensive traffic management capabilities.
# 
# CONTROLLER FEATURES:
# - Layer 7 load balancing with advanced routing capabilities
# - SSL/TLS termination with automatic certificate management
# - WebSocket and gRPC protocol support for modern applications
# - Rate limiting, authentication, and security policy enforcement
# - Comprehensive metrics and monitoring integration
# 
# GOOGLE CLOUD INTEGRATION:
# - Automatically provisions Google Cloud Load Balancer
# - Integrates with Google Cloud DNS for domain management
# - Supports Google Cloud Armor for DDoS protection
# - Leverages Google Cloud monitoring and logging services
resource "helm_release" "nginx_ingress" {
  # Release identification and versioning
  name    = "ingress-nginx"
  version = "4.14.2"  # Stable version with security fixes and performance improvements

  # Official NGINX Ingress Controller Helm repository
  # Maintained by the Kubernetes community
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  
  # Deploy in cluster dependencies namespace
  # Co-locates with other infrastructure services
  namespace = var.dependencies_namespace

  # SSL Certificate Configuration
  # Configures default SSL certificate for HTTPS termination
  # Uses wildcard certificate provisioned by cert-manager
  set {
    name  = "controller.extraArgs.default-ssl-certificate"
    value = "${var.dependencies_namespace}/nginx-tls-secret"
  }

  # Namespace creation (redundant but safe)
  create_namespace = true

  # Deployment dependencies
  # Ensures GKE cluster and namespace are ready before deployment
  depends_on = [module.gke, kubernetes_namespace.cluster_dependencies_namespace]
}

# NGINX Ingress Controller Service Data Source
# Retrieves information about the deployed ingress controller service,
# particularly the external IP address assigned by Google Cloud Load Balancer.
# This IP address is used for DNS record configuration.
# 
# LOAD BALANCER INTEGRATION:
# - Google Cloud automatically provisions a Network Load Balancer
# - External IP address provides public access to ingress controller
# - Supports high availability across multiple zones
# - Integrates with Google Cloud health checking and monitoring
data "kubernetes_service" "nginx_ingress" {
  metadata {
    # Standard service name created by NGINX Ingress Controller Helm chart
    name      = "ingress-nginx-controller"
    namespace = var.dependencies_namespace
  }

  # Wait for ingress controller deployment to complete
  depends_on = [helm_release.nginx_ingress]
}

# Google Cloud DNS Managed Zone Data Source
# Retrieves information about the DNS zone created by the DNS module.
# This zone is used for creating DNS records that point to the ingress controller.
# 
# DNS ZONE INTEGRATION:
# - References DNS zone created in the 00_dns_zone module
# - Provides zone metadata for DNS record creation
# - Ensures DNS records are created in the correct zone
data "google_dns_managed_zone" "dns_zone" {
  name    = var.gcp_platform_name
  project = var.gcp_project_id
}

# Apex Domain DNS Record
# Creates an A record for the apex domain (yourdomain.com) pointing to
# the ingress controller's external IP address. This enables direct access
# to the BTP platform using the primary domain name.
# 
# APEX DOMAIN BENEFITS:
# - Provides clean, professional domain access (https://yourdomain.com)
# - Supports root domain redirects and primary service access
# - Enables consistent branding and user experience
# - Supports SEO optimization for web-based platform interfaces
resource "google_dns_record_set" "ingress_nginx_dns" {
  # DNS record configuration
  name         = "${var.gcp_dns_zone}."  # Apex domain with trailing dot
  type         = "A"                     # IPv4 address record
  ttl          = 300                     # 5-minute TTL for reasonable caching
  managed_zone = data.google_dns_managed_zone.dns_zone.name

  # External IP address from ingress controller load balancer
  rrdatas = [
    data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
  ]

  project = var.gcp_project_id

  # Wait for ingress controller service to receive external IP
  depends_on = [data.kubernetes_service.nginx_ingress]
}

# Wildcard Subdomain DNS Record
# Creates a wildcard A record (*.yourdomain.com) pointing to the ingress
# controller's external IP address. This enables all subdomains to resolve
# to the ingress controller for flexible service routing.
# 
# WILDCARD BENEFITS:
# - Supports unlimited subdomains without additional DNS configuration
# - Enables dynamic subdomain creation for new services
# - Simplifies DNS management for microservices architectures
# - Supports multi-tenant deployments with customer-specific subdomains
# 
# BTP SUBDOMAIN EXAMPLES:
# - app.yourdomain.com: Main BTP platform interface
# - api.yourdomain.com: BTP REST API endpoints
# - ethereum.yourdomain.com: Ethereum blockchain node access
# - grafana.yourdomain.com: Monitoring and metrics dashboard
resource "google_dns_record_set" "wildcard_ingress_nginx_dns" {
  # Wildcard DNS record configuration
  name         = "*.${var.gcp_dns_zone}."  # Wildcard subdomain with trailing dot
  type         = "A"                       # IPv4 address record
  ttl          = 300                       # 5-minute TTL for reasonable caching
  managed_zone = data.google_dns_managed_zone.dns_zone.name

  # Same external IP as apex domain - ingress controller handles routing
  rrdatas = [
    data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
  ]

  project = var.gcp_project_id

  # Wait for ingress controller service to receive external IP
  depends_on = [data.kubernetes_service.nginx_ingress]
}
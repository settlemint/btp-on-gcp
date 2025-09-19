# =============================================================================
# INGRESS-NGINX CONTROLLER
# =============================================================================
# ingress-nginx is a Kubernetes ingress controller that uses NGINX as a reverse
# proxy and load balancer. It provides:
# - HTTP/HTTPS traffic routing to services
# - SSL termination with automatic certificate management
# - Load balancing across multiple pods
# - Integration with Google Cloud Load Balancer
# =============================================================================

# Deploy ingress-nginx using the official Helm chart
resource "helm_release" "nginx_ingress" {
  # Helm release name
  name    = "ingress-nginx"
  version = "4.12.3"  # Stable version with good GCP integration


  # Official ingress-nginx Helm repository
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  
  # Deploy in the dependencies namespace
  namespace  = var.dependencies_namespace

  # Configure default SSL certificate for HTTPS termination
  # This certificate will be used for all ingress resources that don't specify their own
  set {
    name  = "controller.extraArgs.default-ssl-certificate"
    value = "${var.dependencies_namespace}/nginx-tls-secret"
  }

  # Create namespace if it doesn't exist (redundant with explicit creation)
  create_namespace = true

  # Ensure dependencies are ready before deploying ingress controller
  depends_on = [module.gke, kubernetes_namespace.cluster_dependencies_namespace]
}

# =============================================================================
# INGRESS CONTROLLER SERVICE DATA
# =============================================================================
# This data source retrieves information about the ingress-nginx service,
# specifically the external IP address assigned by the Google Cloud Load Balancer.
# This IP is needed to create DNS A records pointing to the ingress controller.
# =============================================================================

data "kubernetes_service" "nginx_ingress" {
  metadata {
    # Service name created by the ingress-nginx Helm chart
    name      = "ingress-nginx-controller"
    # Namespace where the service is deployed
    namespace = var.dependencies_namespace
  }

  # Wait for the ingress controller to be deployed before reading service data
  depends_on = [helm_release.nginx_ingress]
}

# =============================================================================
# DNS ZONE DATA SOURCE
# =============================================================================
# This data source retrieves information about the DNS zone created in the
# 00_dns_zone step. It's needed to create DNS records pointing to the ingress
# controller's load balancer IP address.
# =============================================================================

data "google_dns_managed_zone" "dns_zone" {
  # DNS zone name (must match the zone created in 00_dns_zone)
  name    = var.gcp_platform_name
  # GCP project containing the DNS zone
  project = var.gcp_project_id
}

# =============================================================================
# MAIN DOMAIN DNS RECORD
# =============================================================================
# This creates an A record for the main domain (e.g., btp.example.com)
# pointing to the ingress controller's load balancer IP address.
# This enables direct access to the BTP platform via the custom domain.
# =============================================================================

resource "google_dns_record_set" "ingress_nginx_dns" {
  # Fully qualified domain name with trailing dot (DNS standard)
  name         = "${var.gcp_dns_zone}."
  # A record type for IPv4 addresses
  type         = "A"
  # Time-to-live in seconds (5 minutes for reasonable caching)
  ttl          = 300
  # Reference to the managed DNS zone
  managed_zone = data.google_dns_managed_zone.dns_zone.name

  # IP address of the ingress controller's load balancer
  # This is automatically assigned by GCP when the service is created
  rrdatas = [
    data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
  ]

  # GCP project containing the DNS zone
  project = var.gcp_project_id

  # Wait for the load balancer IP to be assigned before creating DNS record
  depends_on = [data.kubernetes_service.nginx_ingress]
}

# =============================================================================
# WILDCARD SUBDOMAIN DNS RECORD
# =============================================================================
# This creates a wildcard A record (*.btp.example.com) pointing to the same
# ingress controller IP address. This enables access to all subdomains like:
# - grafana.btp.example.com (monitoring dashboard)
# - logs.btp.example.com (log aggregation)
# - metrics.btp.example.com (metrics collection)
# - Any blockchain network subdomains created by users
# =============================================================================

resource "google_dns_record_set" "wildcard_ingress_nginx_dns" {
  # Wildcard DNS record with trailing dot (matches all subdomains)
  name         = "*.${var.gcp_dns_zone}."
  # A record type for IPv4 addresses
  type         = "A"
  # Time-to-live in seconds (5 minutes for reasonable caching)
  ttl          = 300
  # Reference to the managed DNS zone
  managed_zone = data.google_dns_managed_zone.dns_zone.name

  # Same IP address as the main domain (all traffic goes through ingress controller)
  rrdatas = [
    data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
  ]

  # GCP project containing the DNS zone
  project = var.gcp_project_id

  # Wait for the load balancer IP to be assigned before creating DNS record
  depends_on = [data.kubernetes_service.nginx_ingress]
}
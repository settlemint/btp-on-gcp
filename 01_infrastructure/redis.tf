# =============================================================================
# REDIS CACHE CONFIGURATION
# =============================================================================
# Redis serves as the caching layer and session store for the BTP platform,
# providing:
# - Session management for user authentication
# - Caching for frequently accessed data
# - Temporary storage for background job queues
# - Real-time data for WebSocket connections
# - Performance optimization for database queries
# =============================================================================

# Generate a secure random password for Redis authentication
# Redis requires authentication to prevent unauthorized access
resource "random_password" "redis_password" {
  length  = 16        # 16 characters for good security
  special = false     # Alphanumeric only to avoid connection string issues
}

# Deploy Redis using the Bitnami Helm chart
# This provides a production-ready Redis instance optimized for Kubernetes
resource "helm_release" "redis" {
  # Helm release name
  name       = "redis"
  # Bitnami OCI registry (reliable, well-maintained charts)
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "redis"
  version    = "20.13.4"  # Redis 7.x with Bitnami chart optimizations
  
  # Deploy in the dependencies namespace
  namespace  = var.dependencies_namespace

  # Create namespace if it doesn't exist (redundant with explicit creation)
  create_namespace = true

  # Configure Redis architecture
  # "standalone" mode for demo (single instance)
  # For production, consider "replication" mode for high availability
  set {
    name  = "architecture"
    value = "standalone"
  }

  # Set the Redis authentication password
  # This password will be required for all Redis connections
  set {
    name  = "global.redis.password"
    value = random_password.redis_password.result
  }

  # Additional configuration notes:
  # - Persistence is enabled by default (data survives pod restarts)
  # - Memory limit and eviction policies use Bitnami defaults
  # - Network policies can be configured for additional security

  # Ensure cluster and namespace exist before deploying Redis
  depends_on = [module.gke, kubernetes_namespace.cluster_dependencies_namespace]
}
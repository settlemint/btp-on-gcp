# ============================================================================
# SETTLEMINT BLOCKCHAIN TRANSFORMATION PLATFORM (BTP) DEPLOYMENT
# ============================================================================
# 
# Deploys and configures SettleMint's Blockchain Transformation Platform,
# the core application suite that provides comprehensive blockchain
# development, deployment, and management capabilities. This deployment
# represents the culmination of the infrastructure setup, bringing together
# all supporting services to deliver a complete blockchain platform.
# 
# BTP PLATFORM OVERVIEW:
# SettleMint's BTP is an enterprise blockchain platform that provides:
# - Multi-blockchain support (Ethereum, Hyperledger Fabric, IPFS)
# - Low-code/no-code blockchain application development
# - Comprehensive blockchain network management and monitoring
# - Smart contract development, testing, and deployment tools
# - Enterprise-grade security and compliance features
# - Multi-tenant architecture for organizational deployment
# 
# PLATFORM ARCHITECTURE:
# The BTP deployment consists of multiple microservices:
# - Web Application: User interface and dashboard
# - API Gateway: RESTful APIs for blockchain operations
# - Blockchain Connectors: Integration with various blockchain networks
# - Identity Management: User authentication and authorization
# - Monitoring Services: Platform metrics and blockchain analytics
# - External DNS Controller: Automatic DNS record management
# 
# ENTERPRISE INTEGRATION:
# - OAuth integration with Google Cloud for user authentication
# - Vault integration for secure secrets management
# - PostgreSQL integration for application data storage
# - Redis integration for session management and caching
# - MinIO integration for file storage and blockchain data
# - Comprehensive monitoring and logging capabilities
# 
# ============================================================================

# JWT Signing Key Generation
# Generates a cryptographically secure random key for JSON Web Token (JWT)
# signing operations. JWTs are used for secure user authentication and
# session management across BTP platform services.
resource "random_password" "jwtSigningKey" {
  length  = 32
  special = false
}

resource "random_password" "encryption_key" {
  length  = 16
  special = false
}

resource "random_password" "grafana_password" {
  length  = 16
  special = false
}

locals {
  values_yaml = templatefile("${path.module}/values.yaml.tmpl", {
    gcp_dns_zone                   = var.gcp_dns_zone
    dependencies_namespace         = var.dependencies_namespace
    redis_password                 = random_password.redis_password.result
    gcp_platform_name              = var.gcp_platform_name
    postgresql_password            = random_password.postgresql_password.result
    jwtSigningKey                  = random_password.jwtSigningKey.result
    gcp_client_id                  = var.gcp_client_id
    gcp_client_secret              = var.gcp_client_secret
    role_id                        = local.role_id
    secret_id                      = local.secret_id
    gcp_region                     = var.gcp_region
    encryption_key                 = random_password.encryption_key.result
    minio_svcacct_access_key       = random_password.minio_svcacct_access_key.result
    minio_svcacct_secret_key       = random_password.minio_svcacct_secret_key.result
    deployment_namespace           = var.deployment_namespace
    grafana_password               = random_password.grafana_password.result
    external_dns_workload_identity = "${var.external_dns_workload_identity}-${random_id.platform_suffix.hex}"
    gcp_project_id                 = var.gcp_project_id
  })
}

resource "helm_release" "settlemint" {
  name             = "settlemint"
  repository       = "oci://registry.settlemint.com/settlemint-platform"
  chart            = "settlemint"
  namespace        = "settlemint"
  version          = var.btp_version
  create_namespace = true

  values = [local.values_yaml]

  depends_on = [kubernetes_job.vault_configure, kubernetes_namespace.settlemint]
}
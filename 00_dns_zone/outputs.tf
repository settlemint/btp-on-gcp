# ============================================================================
# DNS ZONE MODULE OUTPUTS
# ============================================================================
# 
# This file defines the outputs from the DNS zone module that are essential
# for both post-deployment configuration and integration with other modules.
# 
# CRITICAL POST-DEPLOYMENT STEPS:
# After running this Terraform module, DevOps teams MUST:
# 
# 1. RETRIEVE NAMESERVERS:
#    Run: terraform output name_servers
#    This will display the Google Cloud DNS nameservers
# 
# 2. UPDATE DOMAIN REGISTRAR:
#    Configure your domain registrar to use these nameservers:
#    - Log into your domain registrar (GoDaddy, Namecheap, etc.)
#    - Navigate to DNS management for your domain
#    - Replace existing nameservers with the Google Cloud nameservers
#    - Save changes and wait for propagation (up to 48 hours)
# 
# 3. VERIFY DNS DELEGATION:
#    Test DNS resolution using: dig NS yourdomain.com
#    Ensure it returns the Google Cloud nameservers
# 
# INTEGRATION WITH INFRASTRUCTURE MODULE:
# The nameservers output is consumed by the infrastructure module to:
# - Configure cert-manager for Let's Encrypt DNS challenges
# - Set up external-dns for automatic DNS record management
# - Validate domain ownership during certificate provisioning
# 
# ENTERPRISE CONSIDERATIONS:
# - Document nameservers in your infrastructure inventory
# - Implement monitoring for DNS resolution health
# - Consider backup DNS providers for high availability
# - Plan for DNS failover scenarios in disaster recovery
# 
# ============================================================================

# Google Cloud DNS Zone Nameservers
# These are the authoritative nameservers assigned by Google Cloud DNS
# for the created DNS zone. These nameservers MUST be configured at your
# domain registrar to delegate DNS authority to Google Cloud.
# 
# NAMESERVER FORMAT:
# Google Cloud provides 4 nameservers in the format:
# - ns-cloud-a1.googledomains.com.
# - ns-cloud-a2.googledomains.com.
# - ns-cloud-a3.googledomains.com.
# - ns-cloud-a4.googledomains.com.
# 
# USAGE INSTRUCTIONS:
# 1. After deployment, run: terraform output name_servers
# 2. Copy the displayed nameservers
# 3. Configure them at your domain registrar
# 4. Wait for DNS propagation (typically 24-48 hours)
# 5. Verify with: nslookup yourdomain.com
# 
# AUTOMATION CONSIDERATIONS:
# For CI/CD pipelines, this output can be:
# - Stored in configuration management systems
# - Used to automatically update DNS via registrar APIs
# - Integrated with monitoring systems for health checks
# - Referenced in documentation generation tools
# 
# TROUBLESHOOTING:
# If DNS resolution fails after nameserver update:
# - Verify nameservers are correctly set at registrar
# - Check DNS propagation status using online tools
# - Ensure no conflicting DNS records exist
# - Contact domain registrar support if issues persist
output "name_servers" {
  description = "Google Cloud DNS nameservers for the created DNS zone. Configure these at your domain registrar to delegate DNS authority to Google Cloud."
  value       = module.gcp_dns_zone.name_servers
  
  # Mark as sensitive if needed for security compliance
  # sensitive = true
}
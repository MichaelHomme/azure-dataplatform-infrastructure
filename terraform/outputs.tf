# ---------------------------------------------------------
# RESOURCE GROUP OUTPUTS
# ---------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.rg.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = data.azurerm_resource_group.rg.id
}

output "location" {
  description = "Azure region of the resources"
  value       = data.azurerm_resource_group.rg.location
}

# ---------------------------------------------------------
# NETWORKING OUTPUTS
# ---------------------------------------------------------

output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = azurerm_virtual_network.vnet.name
}

output "aks_subnet_id" {
  description = "AKS subnet ID"
  value       = azurerm_subnet.aks_subnet.id
}

output "postgres_subnet_id" {
  description = "PostgreSQL subnet ID"
  value       = azurerm_subnet.postgres_subnet.id
}

output "postgres_private_dns_zone_id" {
  description = "Private DNS zone ID for PostgreSQL"
  value       = azurerm_private_dns_zone.postgres_dns.id
}

# ---------------------------------------------------------
# IDENTITY OUTPUTS
# ---------------------------------------------------------

output "airflow_identity_id" {
  description = "Airflow managed identity ID"
  value       = azurerm_user_assigned_identity.airflow_identity.id
}

output "airflow_identity_principal_id" {
  description = "Airflow managed identity principal ID"
  value       = azurerm_user_assigned_identity.airflow_identity.principal_id
}

output "airflow_identity_client_id" {
  description = "Airflow managed identity client ID"
  value       = azurerm_user_assigned_identity.airflow_identity.client_id
}

# ---------------------------------------------------------
# KEY VAULT OUTPUTS
# ---------------------------------------------------------

output "keyvault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.airflow.id
}

output "keyvault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.airflow.name
}

output "keyvault_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.airflow.vault_uri
}

# ---------------------------------------------------------
# CONTAINER REGISTRY OUTPUTS
# ---------------------------------------------------------

output "acr_id" {
  description = "Container Registry ID"
  value       = azurerm_container_registry.acr.id
}

output "acr_name" {
  description = "Container Registry name"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "Container Registry login server"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "Container Registry admin username"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "Container Registry admin password"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

# ---------------------------------------------------------
# STORAGE ACCOUNT OUTPUTS
# ---------------------------------------------------------

output "storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.airflow_logs.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.airflow_logs.name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint for storage account"
  value       = azurerm_storage_account.airflow_logs.primary_blob_endpoint
}

output "storage_container_name" {
  description = "Storage container name for Airflow logs"
  value       = azurerm_storage_container.airflow_logs_container.name
}

# ---------------------------------------------------------
# AKS OUTPUTS
# ---------------------------------------------------------

output "aks_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_fqdn" {
  description = "AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "aks_kube_config_raw" {
  description = "Raw kubeconfig for AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for AKS workload identity"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "aks_identity_object_id" {
  description = "AKS identity object ID"
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# ---------------------------------------------------------
# POSTGRESQL OUTPUTS
# ---------------------------------------------------------

output "postgres_server_id" {
  description = "PostgreSQL server ID"
  value       = azurerm_postgresql_flexible_server.postgres.id
}

output "postgres_server_name" {
  description = "PostgreSQL server name"
  value       = azurerm_postgresql_flexible_server.postgres.name
}

output "postgres_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "postgres_admin_username" {
  description = "PostgreSQL administrator username"
  value       = azurerm_postgresql_flexible_server.postgres.administrator_login
  sensitive   = true
}

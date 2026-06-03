output "resource_group_name" {
  value       = data.azurerm_resource_group.rg.name
  description = "The existing resource group used for the MVP"
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "The custom Virtual Network securing the platform"
}

output "aks_cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "The name of the AKS cluster"
}

output "aks_kube_config" {
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
  description = "Kubeconfig for local kubectl access"
}

output "postgres_server_name" {
  value       = azurerm_postgresql_flexible_server.postgres.name
}

output "postgres_private_fqdn" {
  value       = azurerm_postgresql_flexible_server.postgres.fqdn
  description = "The private DNS FQDN. This is only resolvable from inside the VNet (e.g., from AKS pods)."
}

output "postgres_database_login" {
  value       = var.db_admin_username
  description = "Login username for the PostgreSQL database"
}
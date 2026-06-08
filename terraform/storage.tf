resource "azurerm_storage_account" "airflow_logs" {
  name                       = "airflowsa${replace(random_string.unique_suffix.result, "-", "")}"
  location                   = data.azurerm_resource_group.rg.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  account_tier               = var.storage_account_tier
  account_replication_type   = var.storage_replication_type
  https_traffic_only_enabled = true
  min_tls_version            = var.storage_min_tls_version
}

# Storage container for Airflow logs
resource "azurerm_storage_container" "airflow_logs_container" {
  name               = "airflow-logs"
  storage_account_id = azurerm_storage_account.airflow_logs.id
}

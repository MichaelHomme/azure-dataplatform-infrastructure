resource "azurerm_key_vault" "airflow" {
  name                = "airflow-kv-${random_string.unique_suffix.result}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.keyvault_sku

  rbac_authorization_enabled = false
  purge_protection_enabled   = false

  depends_on = [
    azurerm_user_assigned_identity.airflow_identity
  ]
}

# Access policy for the Terraform deployer (current user)
resource "azurerm_key_vault_access_policy" "terraform_deployer" {
  key_vault_id       = azurerm_key_vault.airflow.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = data.azurerm_client_config.current.object_id
  secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
}

# Access policy for Airflow managed identity
resource "azurerm_key_vault_access_policy" "airflow_identity" {
  key_vault_id       = azurerm_key_vault.airflow.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = azurerm_user_assigned_identity.airflow_identity.principal_id
  secret_permissions = ["Get", "List"]
}


resource "azurerm_key_vault_secret" "storage_account_name" {
  name         = "AKS-AIRFLOW-LOGS-STORAGE-ACCOUNT-NAME"
  value        = azurerm_storage_account.airflow_logs.name
  key_vault_id = azurerm_key_vault.airflow.id

  depends_on = [azurerm_key_vault_access_policy.terraform_deployer]
}

resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "AKS-AIRFLOW-LOGS-STORAGE-ACCOUNT-KEY"
  value        = azurerm_storage_account.airflow_logs.primary_access_key
  key_vault_id = azurerm_key_vault.airflow.id

  depends_on = [azurerm_key_vault_access_policy.terraform_deployer]
}

resource "azurerm_key_vault_secret" "airflow_git_pat" {
  name         = var.airflow_git_pat_secret_name
  value        = var.airflow_git_pat
  key_vault_id = azurerm_key_vault.airflow.id

  depends_on = [azurerm_key_vault_access_policy.terraform_deployer]
}

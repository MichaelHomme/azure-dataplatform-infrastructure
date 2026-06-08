resource "azurerm_user_assigned_identity" "airflow_identity" {
  name                = "airflow-identity"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

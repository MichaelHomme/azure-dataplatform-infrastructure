resource "azurerm_container_registry" "acr" {
  name                = "acr${replace(random_string.unique_suffix.result, "-", "")}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = var.acr_sku
  admin_enabled       = true
}

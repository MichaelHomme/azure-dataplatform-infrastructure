resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "psql-dataplatform-mvp-${random_id.suffix.hex}"
  resource_group_name    = data.azurerm_resource_group.rg.name
  location               = data.azurerm_resource_group.rg.location
  version                = var.postgres_version
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  zone                   = var.postgres_availability_zone
  storage_mb             = var.postgres_storage_mb
  sku_name               = var.postgres_sku

  public_network_access_enabled = false

  delegated_subnet_id = azurerm_subnet.postgres_subnet.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres_dns.id

  depends_on = [azurerm_private_dns_zone_virtual_network_link.dns_vnet_link]
}

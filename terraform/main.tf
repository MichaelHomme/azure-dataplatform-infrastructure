terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = "rg-azure-dataplatform-mvp"
}

# ---------------------------------------------------------
# NEW: NETWORKING TIER
# ---------------------------------------------------------

# 2. The Main Virtual Network (The secure perimeter)
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-dataplatform-mvp"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"] # 65,536 private IP addresses
}

# 3. Subnet for AKS (Compute)
resource "azurerm_subnet" "aks_subnet" {
  name                 = "snet-aks"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"] # 256 IPs for nodes and pods
}

# 4. Subnet for PostgreSQL (Storage)
resource "azurerm_subnet" "postgres_subnet" {
  name                 = "snet-postgres"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "fs"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}


resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Link the DNS Zone to our VNet
resource "azurerm_private_dns_zone_virtual_network_link" "dns_vnet_link" {
  name                  = "dns-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = data.azurerm_resource_group.rg.name
}

# ---------------------------------------------------------
# UPDATED: COMPUTE & STORAGE
# ---------------------------------------------------------

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-dataplatform-mvp"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "aks-data-mvp"

  default_node_pool {
    name           = "default"
    node_count     = 2
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }


  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"

    # --- NEW: Explicitly define internal Service IPs so they don't overlap with the VNet ---
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10" # Must be an IP inside the service_cidr
  }
}


resource "random_id" "suffix" {
  byte_length = 2
}

resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "psql-dataplatform-mvp-${random_id.suffix.hex}"
  resource_group_name    = data.azurerm_resource_group.rg.name
  location               = data.azurerm_resource_group.rg.location
  version                = "15"
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  zone                   = "1"
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"

  public_network_access_enabled = false

  delegated_subnet_id = azurerm_subnet.postgres_subnet.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres_dns.id

  depends_on = [azurerm_private_dns_zone_virtual_network_link.dns_vnet_link]
}

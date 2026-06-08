resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-dataplatform-mvp"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "aks-data-mvp"

  default_node_pool {
    name                        = "default"
    vm_size                     = var.aks_vm_size
    vnet_subnet_id              = azurerm_subnet.aks_subnet.id
    auto_scaling_enabled        = true
    min_count                   = var.aks_min_count
    max_count                   = var.aks_max_count
    os_disk_type                = "Managed"
    temporary_name_for_rotation = "tmpdefault"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.airflow_identity.id]
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "172.16.0.0/16"
    dns_service_ip    = "172.16.0.10"
  }

  # Enable OIDC issuer for workload identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  storage_profile {
    blob_driver_enabled = true
  }

  depends_on = [
    azurerm_user_assigned_identity.airflow_identity
  ]
}


resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

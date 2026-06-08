variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-azure-dataplatform-mvp"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Norway East"
}

# ---------------------------------------------------------
# NETWORKING VARIABLES
# ---------------------------------------------------------

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_prefix" {
  description = "Address prefix for AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "postgres_subnet_prefix" {
  description = "Address prefix for PostgreSQL subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# ---------------------------------------------------------
# AKS VARIABLES
# ---------------------------------------------------------

variable "aks_node_count" {
  description = "Initial number of AKS nodes"
  type        = number
  default     = 3
}

variable "aks_min_count" {
  description = "Minimum number of AKS nodes for autoscaling"
  type        = number
  default     = 2
}

variable "aks_max_count" {
  description = "Maximum number of AKS nodes for autoscaling"
  type        = number
  default     = 4
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "aks_kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.29"
}

variable "aks_availability_zones" {
  description = "Availability zones for AKS nodes"
  type        = list(string)
  default     = ["1", "2", "3"]
}

# ---------------------------------------------------------
# CONTAINER REGISTRY VARIABLES
# ---------------------------------------------------------

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Premium"
}

# ---------------------------------------------------------
# STORAGE ACCOUNT VARIABLES
# ---------------------------------------------------------

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Storage replication type"
  type        = string
  default     = "LRS"
}

variable "storage_min_tls_version" {
  description = "Minimum TLS version for storage account"
  type        = string
  default     = "TLS1_2"
}

# ---------------------------------------------------------
# POSTGRESQL VARIABLES
# ---------------------------------------------------------

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "postgres_sku" {
  description = "PostgreSQL flexible server SKU"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768
}

variable "postgres_availability_zone" {
  description = "Availability zone for PostgreSQL"
  type        = string
  default     = "1"
}

variable "db_admin_username" {
  description = "PostgreSQL administrator username"
  type        = string
  sensitive   = true
}

variable "db_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------
# KEY VAULT VARIABLES
# ---------------------------------------------------------

variable "keyvault_sku" {
  description = "Key Vault SKU"
  type        = string
  default     = "standard"
}

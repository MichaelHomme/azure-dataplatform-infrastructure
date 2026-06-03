variable "location" {
  type        = string
  description = "The Azure region where resources will be deployed"
  default     = "Norway East"
}

variable "db_admin_username" {
  type        = string
  description = "PostgreSQL administrator username"
  default     = "psqladmin"
}

variable "db_admin_password" {
  type        = string
  description = "PostgreSQL administrator password"
  sensitive   = true
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the MVP Virtual Network"
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_prefix" {
  type        = list(string)
  description = "Address prefix for the AKS compute subnet"
  default     = ["10.0.1.0/24"]
}

variable "postgres_subnet_prefix" {
  type        = list(string)
  description = "Address prefix for the PostgreSQL delegated subnet"
  default     = ["10.0.2.0/24"]
}
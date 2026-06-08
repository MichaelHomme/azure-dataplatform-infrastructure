# ---------------------------------------------------------
# AZURE DATA PLATFORM - TERRAFORM CONFIGURATION
# ---------------------------------------------------------
#
# This Terraform configuration provisions the complete infrastructure
# for Apache Airflow on Azure Kubernetes Service (AKS) with PostgreSQL.
#
# Files:
# - providers.tf          : Provider and data sources
# - variables.tf          : Input variables
# - outputs.tf            : Output values
# - locals.tf             : Random generators
# - networking.tf         : VNet, subnets, private DNS
# - identity.tf           : Managed identity
# - keyvault.tf           : Key Vault and secrets
# - container-registry.tf : Azure Container Registry
# - storage.tf            : Storage account for Airflow logs
# - aks.tf                : AKS cluster configuration
# - database.tf           : PostgreSQL flexible server
#
# ---------------------------------------------------------


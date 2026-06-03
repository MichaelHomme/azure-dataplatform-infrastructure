# Azure Data Platform MVP - Infrastructure

This repository provisions a private Azure infrastructure foundation for a data platform MVP using Terraform.

## What This Deploys

- Existing Resource Group lookup:
    - `rg-azure-dataplatform-mvp` (must already exist)
- Networking:
    - VNet: `vnet-dataplatform-mvp` (`10.0.0.0/16`)
    - AKS subnet: `snet-aks` (`10.0.1.0/24`)
    - PostgreSQL delegated subnet: `snet-postgres` (`10.0.2.0/24`)
    - Private DNS zone: `privatelink.postgres.database.azure.com`
    - DNS link from zone to VNet
- Compute:
    - AKS cluster: `aks-dataplatform-mvp`
    - Node pool: 2 nodes, `Standard_D2s_v3`
    - Azure CNI (`network_plugin = "azure"`)
- Data layer:
    - Azure Database for PostgreSQL Flexible Server (private networking only)
    - Server name includes a random suffix (`psql-dataplatform-mvp-<suffix>`)

## Repository Files

- `backend.tf`: Remote state backend in Azure Storage (`azurerm` backend)
- `main.tf`: Core resources (VNet, subnets, AKS, PostgreSQL, Private DNS)
- `variables.tf`: Input variables
- `outputs.tf`: Useful deployment outputs

## Prerequisites

- Azure CLI installed
- Terraform installed
- Logged in with Azure CLI:

```bash
az login
```

- Existing Azure resources for Terraform remote state (from `backend.tf`):
    - Resource group: `rg-terraform-state-mvp`
    - Storage account: `stazuredataplatformmvp`
    - Container: `tfstate`
    - Key: `mvp.terraform.tfstate`
- Existing deployment resource group:
    - `rg-azure-dataplatform-mvp`

## Inputs

Required variable:

- `db_admin_password` (sensitive)

Optional variables currently defined:

- `location` (default: `Norway East`)
- `db_admin_username` (default: `psqladmin`)
- `vnet_address_space` (default: `10.0.0.0/16`)
- `aks_subnet_prefix` (default: `10.0.1.0/24`)
- `postgres_subnet_prefix` (default: `10.0.2.0/24`)

Note: Network CIDRs and some naming are currently set directly in `main.tf`. The related variables are defined but not yet wired into those resources.

## Deployment

1. Initialize Terraform:

```bash
terraform init
```

2. Validate configuration:

```bash
terraform validate
```

3. Create and review a plan:

```bash
terraform plan -var="db_admin_password=<strong-password>" -out=tfplan
```

4. Apply the plan:

```bash
terraform apply tfplan
```

## Outputs

After apply, Terraform returns:

- `resource_group_name`
- `vnet_name`
- `aks_cluster_name`
- `aks_kube_config` (sensitive)
- `postgres_server_name`
- `postgres_private_fqdn`
- `postgres_database_login`

## Accessing AKS

To merge cluster credentials into your local kube config:

```bash
az aks get-credentials --resource-group rg-azure-dataplatform-mvp --name aks-dataplatform-mvp
```

Then verify access:

```bash
kubectl get nodes
```

## Destroy

To delete provisioned infrastructure in this stack:

```bash
terraform destroy -var="db_admin_password=<strong-password>"
```

## Security Notes

- PostgreSQL is deployed using delegated subnet + private DNS, without public access in this setup.
- Keep secrets out of source control. Prefer environment variables or a secure secret store for `db_admin_password`.


## Database Bootstrapping

```bash
# Create the database for Airflow's internal state
az postgres flexible-server db create \
  --resource-group rg-azure-dataplatform-mvp \
  --server-name psql-dataplatform-mvp-783d \
  --database-name airflow_metadata

# Create the database for dbt transformations
az postgres flexible-server db create \
  --resource-group rg-azure-dataplatform-mvp \
  --server-name psql-dataplatform-mvp-783d \
  --database-name data_warehouse
```

## AKS Cluster Connection & Secrets Ingestion

```bash
# get credentials
az aks get-credentials --resource-group rg-azure-dataplatform-mvp --name aks-dataplatform-mvp

# Create a namesapce for Airflow
kubectl create namespace airflow

# Inject the webserver secret
kubectl create secret generic airflow-webserver-secret --from-literal=webserver-secret-key="********************************" -n airflow

# Inject the connection string directly into Kubernetes
kubectl create secret generic my-airflow-db-secret \
  --from-literal=connection='postgresql+psycopg2://psqladmin:***********@psql-dataplatform-mvp-783d.postgres.database.azure.com:5432/airflow_metadata' \
  -n airflow

# Inject DBT database secret
kubectl create secret generic dbt-postgres-secret \
  --from-literal=DBT_PASSWORD='<strong-password>' \
  -n airflow
```
## Apache Airflow deployment via Helm

```bash
# These are identical in PowerShell, Bash, and Zsh
helm repo add apache-airflow https://airflow.apache.org
helm repo update
helm upgrade --install airflow apache-airflow/airflow --namespace airflow --values helm/airflow/values.yaml
```

### Check the running Pods
```bash
# check running pods
kubectl get pods -n airflow -w
# Test Airflow api-server
kubectl port-forward svc/airflow-api-server 8080:8080 -n airflow
```

## Inject the GitHub PAT
```bash
kubectl create secret generic airflow-git-credentials --from-literal=GIT_SYNC_USERNAME=<github_username> --from-literal=GIT_SYNC_PASSWORD=<your_pat> -n airflow
```
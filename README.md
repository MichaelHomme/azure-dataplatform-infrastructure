# Azure Data Platform Infrastructure

Apache Airflow on Azure Kubernetes Service (AKS) with PostgreSQL, provisioned via Terraform and deployed with Helm.

## Architecture

```mermaid
graph TB
    subgraph RG["Resource Group (Norway East)"]
        subgraph VNET["VNet 10.0.0.0/16"]
            subgraph AKS_SUBNET["Subnet: snet-aks"]
                AKS["AKS Cluster<br/>KubernetesExecutor"]
            end
            subgraph PG_SUBNET["Subnet: snet-postgres"]
                PG["PostgreSQL Flexible Server<br/>(Private endpoint)"]
            end
        end
        KV["Key Vault<br/>Secrets: DB creds, Storage keys, Git PAT"]
        ACR["Container Registry<br/>Airflow + git-sync images"]
        SA["Storage Account<br/>Blob: airflow-logs"]
        MI["Managed Identity<br/>(Workload Identity + OIDC)"]
    end

    subgraph AKS_INTERNAL["AKS Workloads"]
        ESO["External Secrets Operator"]
        AIRFLOW["Airflow (Helm chart v1.15.0)<br/>Scheduler / Webserver / Triggerer"]
        GS["git-sync v4 sidecar"]
    end

    GH["GitHub Repo<br/>(DAGs)"]

    MI -->|"Get secrets"| KV
    ESO -->|"Sync secrets"| KV
    AKS -->|"Pull images"| ACR
    AIRFLOW -->|"Read/write logs"| SA
    AIRFLOW -->|"Metadata DB"| PG
    GS -->|"Clone DAGs"| GH
```

## Project Structure

```
terraform/          # Infrastructure as Code (Azure resources)
helm/
  env.sh.example    # Environment variables template
  deploy.sh         # Automated 7-step deployment script
  import-images.sh  # Import container images to ACR
  manifests/        # Kubernetes manifests (ExternalSecrets, PV/PVC)
  values/           # Helm chart values for Airflow
```

## Prerequisites

- Azure CLI (`az`) authenticated
- Terraform >= 1.0
- `kubectl` and `helm` installed
- A GitHub Personal Access Token for private DAG repo access

## Deployment

### 1. Provision Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

This creates: VNet, AKS, PostgreSQL, Key Vault, Storage Account, Container Registry, and Managed Identity.

### 2. Deploy Airflow

```bash
cd helm
cp env.sh.example env.sh   # Fill in values from Terraform outputs
source env.sh
./import-images.sh          # Import images to ACR
./deploy.sh                 # Deploy Airflow to AKS
```

The deploy script handles: AKS credentials, namespace creation, federated identity binding, External Secrets Operator, secret synchronization, persistent volumes, and Airflow Helm release.

## Key Design Decisions

| Concern | Approach |
|---------|----------|
| Secrets | Azure Key Vault + External Secrets Operator (no secrets in code) |
| DAG sync | git-sync v4 sidecar with PAT from Key Vault |
| Logs | Azure Blob Storage via CSI driver |
| Networking | Private PostgreSQL (delegated subnet + private DNS) |
| Identity | Workload Identity (OIDC federation, no stored credentials) |
| Scaling | AKS autoscaler (2-4 nodes) + KubernetesExecutor |

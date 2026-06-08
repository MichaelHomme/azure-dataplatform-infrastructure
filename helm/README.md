# Helm Deployment for Apache Airflow on AKS

This directory contains all the Kubernetes manifests and Helm values needed to deploy Apache Airflow on AKS.

## Prerequisites

1. Infrastructure deployed via Terraform (see `../terraform/`)
2. `kubectl` configured to connect to your AKS cluster
3. `helm` v3+ installed
4. Docker installed (for importing images to ACR)

## Directory Structure

```
helm/
├── README.md              # This file
├── deploy.sh              # Main deployment script
├── env.sh.example         # Example environment variables (copy to env.sh)
├── manifests/
│   ├── namespace.yaml     # Airflow namespace
│   ├── service-account.yaml
│   ├── secret-store.yaml
│   ├── external-secret.yaml
│   ├── persistent-volume.yaml
│   └── persistent-volume-claim.yaml
└── values/
    └── airflow-values.yaml  # Helm chart values for Airflow
```

## Setup Steps

### 1. Configure Environment Variables

```bash
cp env.sh.example env.sh
# Edit env.sh with your actual values from Terraform output
source env.sh
```

### 2. Import Container Images to ACR

```bash
./import-images.sh
```

### 3. Deploy

```bash
./deploy.sh
```

### 4. Access Airflow UI

```bash
kubectl port-forward svc/airflow-webserver 8080:8080 -n airflow
```

Open `http://localhost:8080` (default credentials: admin/admin)

## Teardown

```bash
helm uninstall airflow -n airflow
helm uninstall external-secrets -n airflow
kubectl delete namespace airflow
```

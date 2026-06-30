#!/usr/bin/env bash
# ---------------------------------------------------------
# Import Airflow container images to Azure Container Registry
# ---------------------------------------------------------
# Usage: source env.sh && ./import-images.sh
# ---------------------------------------------------------
set -euo pipefail

if [[ -z "${ACR_REGISTRY:-}" ]]; then
  echo "Error: ACR_REGISTRY is not set. Source env.sh first."
  exit 1
fi

echo "Importing images to ACR: ${ACR_REGISTRY}..."

echo "  [1/6] airflow:airflow-pgbouncer-2025.03.05-1.23.1"
az acr import --name "$ACR_REGISTRY" \
  --source docker.io/apache/airflow:airflow-pgbouncer-2025.03.05-1.23.1 \
  --image airflow:airflow-pgbouncer-2025.03.05-1.23.1

echo "  [2/6] airflow:airflow-pgbouncer-exporter-2025.03.05-0.18.0"
az acr import --name "$ACR_REGISTRY" \
  --source docker.io/apache/airflow:airflow-pgbouncer-exporter-2025.03.05-0.18.0 \
  --image airflow:airflow-pgbouncer-exporter-2025.03.05-0.18.0

echo "  [3/6] postgresql:16.1.0-debian-11-r15"
az acr import --name "$ACR_REGISTRY" \
  --source docker.io/bitnamilegacy/postgresql:16.1.0-debian-11-r15 \
  --image postgresql:16.1.0-debian-11-r15

echo "  [4/6] statsd-exporter:v0.28.0"
az acr import --name "$ACR_REGISTRY" \
  --source quay.io/prometheus/statsd-exporter:v0.28.0 \
  --image statsd-exporter:v0.28.0

# airflow:3.2.2-cosmos is built by build-images.sh — run that instead of importing the base image.

echo "  [5/5] git-sync:v4.3.0"
az acr import --name "$ACR_REGISTRY" \
  --source registry.k8s.io/git-sync/git-sync:v4.3.0 \
  --image git-sync:v4.3.0

echo "All images imported successfully."

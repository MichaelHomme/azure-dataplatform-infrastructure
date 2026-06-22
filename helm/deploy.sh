#!/usr/bin/env bash
# ---------------------------------------------------------
# Deploy Apache Airflow on AKS
# ---------------------------------------------------------
# Usage: source env.sh && ./deploy.sh
# ---------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to substitute environment variables in a file (replaces envsubst)
render_template() {
  local file="$1"
  local content
  content=$(<"$file")
  content="${content//\$\{RESOURCE_GROUP_NAME\}/$RESOURCE_GROUP_NAME}"
  content="${content//\$\{IDENTITY_NAME_CLIENT_ID\}/$IDENTITY_NAME_CLIENT_ID}"
  content="${content//\$\{IDENTITY_NAME_PRINCIPAL_ID\}/$IDENTITY_NAME_PRINCIPAL_ID}"
  content="${content//\$\{ACR_REGISTRY\}/$ACR_REGISTRY}"
  content="${content//\$\{KEYVAULT_NAME\}/$KEYVAULT_NAME}"
  content="${content//\$\{KEYVAULTURL\}/$KEYVAULTURL}"
  content="${content//\$\{OIDC_URL\}/$OIDC_URL}"
  content="${content//\$\{AKS_AIRFLOW_LOGS_STORAGE_ACCOUNT_NAME\}/$AKS_AIRFLOW_LOGS_STORAGE_ACCOUNT_NAME}"
  content="${content//\$\{AKS_AIRFLOW_LOGS_STORAGE_CONTAINER_NAME\}/$AKS_AIRFLOW_LOGS_STORAGE_CONTAINER_NAME}"
  content="${content//\$\{AKS_AIRFLOW_LOGS_STORAGE_SECRET_NAME\}/$AKS_AIRFLOW_LOGS_STORAGE_SECRET_NAME}"
  content="${content//\$\{AKS_AIRFLOW_NAMESPACE\}/$AKS_AIRFLOW_NAMESPACE}"
  content="${content//\$\{SERVICE_ACCOUNT_NAME\}/$SERVICE_ACCOUNT_NAME}"
  content="${content//\$\{TENANT_ID\}/$TENANT_ID}"
  echo "$content"
}

# Validate required environment variables
REQUIRED_VARS=(
  RESOURCE_GROUP_NAME
  IDENTITY_NAME
  IDENTITY_NAME_CLIENT_ID
  IDENTITY_NAME_PRINCIPAL_ID
  ACR_REGISTRY
  KEYVAULT_NAME
  CLUSTER_NAME
  KEYVAULTURL
  OIDC_URL
  AKS_AIRFLOW_LOGS_STORAGE_ACCOUNT_NAME
  AKS_AIRFLOW_LOGS_STORAGE_CONTAINER_NAME
  AKS_AIRFLOW_LOGS_STORAGE_SECRET_NAME
  AKS_AIRFLOW_NAMESPACE
  SERVICE_ACCOUNT_NAME
  TENANT_ID
)

for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Error: $var is not set. Source env.sh first."
    exit 1
  fi
done

echo "========================================="
echo " Deploying Airflow on AKS"
echo "========================================="

# Step 1: Connect to AKS
echo ""
echo "[1/7] Connecting to AKS cluster..."
az aks get-credentials \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$CLUSTER_NAME" \
  --overwrite-existing

# Step 2: Create namespace and service account
echo ""
echo "[2/7] Creating namespace and service account..."
kubectl create namespace "$AKS_AIRFLOW_NAMESPACE" --dry-run=client --output yaml | kubectl apply -f -

render_template "$SCRIPT_DIR/manifests/service-account.yaml" | kubectl apply -f -

# Step 3: Create federated credential for workload identity
echo ""
echo "[3/7] Creating federated credential..."
az identity federated-credential create \
  --name external-secret-operator \
  --identity-name "$IDENTITY_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --issuer "$OIDC_URL" \
  --subject "system:serviceaccount:${AKS_AIRFLOW_NAMESPACE}:${SERVICE_ACCOUNT_NAME}" \
  --output table 2>/dev/null || echo "Federated credential already exists."

# Step 4: Install External Secrets Operator
echo ""
echo "[4/7] Installing External Secrets Operator..."
helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
helm repo update

helm upgrade --install external-secrets \
  external-secrets/external-secrets \
  --namespace "$AKS_AIRFLOW_NAMESPACE" \
  --create-namespace \
  --set installCRDs=true \
  --wait

# Step 5: Create SecretStore and ExternalSecret
echo ""
echo "[5/7] Creating SecretStore and ExternalSecret..."

# Wait for External Secrets CRDs to be ready
echo "Waiting for External Secrets CRDs..."
kubectl wait --for=condition=Established crd/secretstores.external-secrets.io --timeout=60s
kubectl wait --for=condition=Established crd/externalsecrets.external-secrets.io --timeout=60s

render_template "$SCRIPT_DIR/manifests/secret-store.yaml" | kubectl apply -f -
render_template "$SCRIPT_DIR/manifests/external-secret.yaml" | kubectl apply -f -
render_template "$SCRIPT_DIR/manifests/external-secret-git.yaml" | kubectl apply -f -

# Step 6: Create Persistent Volume and Claim
echo ""
echo "[6/7] Creating Persistent Volume and Claim..."
render_template "$SCRIPT_DIR/manifests/persistent-volume.yaml" | kubectl apply -f -
render_template "$SCRIPT_DIR/manifests/persistent-volume-claim.yaml" | kubectl apply -f -

# Step 7: Deploy Airflow via Helm
echo ""
echo "[7/7] Deploying Apache Airflow..."
helm repo add apache-airflow https://airflow.apache.org 2>/dev/null || true
helm repo update

# Render the values file with environment variables
render_template "$SCRIPT_DIR/values/airflow-values.yaml" > /tmp/airflow-values-rendered.yaml

helm upgrade --install airflow \
  apache-airflow/airflow \
  --version 1.22.0 \
  --namespace "$AKS_AIRFLOW_NAMESPACE" \
  --create-namespace \
  -f /tmp/airflow-values-rendered.yaml \
  --wait --timeout 10m

# Cleanup rendered file
rm -f /tmp/airflow-values-rendered.yaml

echo ""
echo "========================================="
echo " Deployment Complete!"
echo "========================================="
echo ""
echo "Access the Airflow UI:"
echo "  kubectl port-forward svc/airflow-webserver 8080:8080 -n airflow"
echo ""
echo "Then open: http://localhost:8080"
echo "  Username: admin"
echo "  Password: admin"
echo ""

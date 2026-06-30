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
  content="${content//\$\{AIRFLOW_GIT_PAT_SECRET_NAME\}/$AIRFLOW_GIT_PAT_SECRET_NAME}"
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
  AIRFLOW_GIT_PAT_SECRET_NAME
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
echo "[1/8] Connecting to AKS cluster..."
az aks get-credentials \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$CLUSTER_NAME" \
  --overwrite-existing

# Step 2: Create namespace and service account
echo ""
echo "[2/8] Creating namespace and service account..."
kubectl create namespace "$AKS_AIRFLOW_NAMESPACE" --dry-run=client --output yaml | kubectl apply -f -

render_template "$SCRIPT_DIR/manifests/service-account.yaml" | kubectl apply -f -

# Step 3: Create federated credential for workload identity
echo ""
echo "[3/8] Creating federated credential..."
az identity federated-credential create \
  --name external-secret-operator \
  --identity-name "$IDENTITY_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --issuer "$OIDC_URL" \
  --subject "system:serviceaccount:${AKS_AIRFLOW_NAMESPACE}:${SERVICE_ACCOUNT_NAME}" \
  --output table 2>/dev/null || echo "Federated credential already exists."

# Step 4: Install External Secrets Operator
echo ""
echo "[4/8] Installing External Secrets Operator..."
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
echo "[5/8] Creating SecretStore and ExternalSecret..."

# Wait for External Secrets CRDs to be ready
echo "Waiting for External Secrets CRDs..."
kubectl wait --for=condition=Established crd/secretstores.external-secrets.io --timeout=60s
kubectl wait --for=condition=Established crd/externalsecrets.external-secrets.io --timeout=60s

render_template "$SCRIPT_DIR/manifests/secret-store.yaml" | kubectl apply -f -
render_template "$SCRIPT_DIR/manifests/external-secret.yaml" | kubectl apply -f -
render_template "$SCRIPT_DIR/manifests/external-secret-git.yaml" | kubectl apply -f -
render_template "$SCRIPT_DIR/manifests/external-secret-dbt.yaml" | kubectl apply -f -

# Step 6: Create Persistent Volume and Claim
echo ""
echo "[6/8] Creating Persistent Volume and Claim..."
render_template "$SCRIPT_DIR/manifests/persistent-volume.yaml" | kubectl apply -f -
render_template "$SCRIPT_DIR/manifests/persistent-volume-claim.yaml" | kubectl apply -f -

# Step 7: Deploy Airflow via Helm
echo ""
echo "[7/8] Deploying Apache Airflow chart..."
helm repo add apache-airflow https://airflow.apache.org 2>/dev/null || true
helm repo update

# Determine Airflow image tag from values file (used for the migration pod)
AIRFLOW_IMAGE_TAG=$(awk '/^  airflow:/{found=1} found && /^    tag:/{print $2; exit}' "$SCRIPT_DIR/values/airflow-values.yaml")
AIRFLOW_IMAGE="${ACR_REGISTRY}.azurecr.io/airflow:${AIRFLOW_IMAGE_TAG}"

# Render the values file with environment variables
render_template "$SCRIPT_DIR/values/airflow-values.yaml" > /tmp/airflow-values-rendered.yaml

# Deploy without --wait: migrations are handled explicitly in the next step.
# This avoids failures caused by the Helm hook migration job timing out
# before the ACR image is accessible or PostgreSQL is fully ready.
helm upgrade --install airflow \
  apache-airflow/airflow \
  --version 1.22.0 \
  --namespace "$AKS_AIRFLOW_NAMESPACE" \
  --create-namespace \
  -f /tmp/airflow-values-rendered.yaml \
  --timeout 10m

# Cleanup rendered file
rm -f /tmp/airflow-values-rendered.yaml

# Step 8: Run DB migrations explicitly
echo ""
echo "[8/8] Running Airflow DB migrations..."

echo "Waiting for PostgreSQL to be ready..."
kubectl wait pod \
  --selector "app.kubernetes.io/name=postgresql,app.kubernetes.io/instance=airflow" \
  --namespace "$AKS_AIRFLOW_NAMESPACE" \
  --for=condition=Ready \
  --timeout=120s

# Remove any leftover migration pod from a previous run
kubectl delete pod airflow-db-migrate \
  --namespace "$AKS_AIRFLOW_NAMESPACE" \
  --ignore-not-found=true

DB_CONN=$(kubectl get secret airflow-metadata \
  --namespace "$AKS_AIRFLOW_NAMESPACE" \
  -o jsonpath='{.data.connection}' | base64 -d)

kubectl run airflow-db-migrate \
  --image="$AIRFLOW_IMAGE" \
  --restart=Never \
  --namespace="$AKS_AIRFLOW_NAMESPACE" \
  --env="AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=$DB_CONN" \
  --command -- airflow db migrate

echo "Waiting for migrations to complete (up to 5 minutes)..."
for i in $(seq 1 60); do
  PHASE=$(kubectl get pod airflow-db-migrate \
    --namespace "$AKS_AIRFLOW_NAMESPACE" \
    -o jsonpath='{.status.phase}' 2>/dev/null)
  if [[ "$PHASE" == "Succeeded" ]]; then
    echo "Migrations completed successfully."
    break
  elif [[ "$PHASE" == "Failed" ]]; then
    echo "Migration failed! Check logs with:"
    echo "  kubectl logs -n $AKS_AIRFLOW_NAMESPACE airflow-db-migrate"
    exit 1
  fi
  sleep 5
done

kubectl delete pod airflow-db-migrate \
  --namespace "$AKS_AIRFLOW_NAMESPACE" \
  --ignore-not-found=true

# Create the default admin user if it doesn't already exist
echo "Creating default admin user..."
kubectl exec \
  --namespace "$AKS_AIRFLOW_NAMESPACE" \
  deployment/airflow-api-server -- \
  airflow users create \
    --username admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com \
    --password admin 2>&1 | grep -E "already exists|created|Error" || true

echo "Waiting for all Airflow components to be ready..."
kubectl rollout status \
  deployment/airflow-api-server \
  deployment/airflow-dag-processor \
  deployment/airflow-scheduler \
  --namespace "$AKS_AIRFLOW_NAMESPACE" \
  --timeout=10m

kubectl rollout status \
  statefulset/airflow-triggerer \
  --namespace "$AKS_AIRFLOW_NAMESPACE" \
  --timeout=10m

echo ""
echo "========================================="
echo " Deployment Complete!"
echo "========================================="
echo ""
echo "Access the Airflow UI:"
echo "  kubectl port-forward svc/airflow-api-server 8080:8080 -n airflow"
echo ""
echo "Then open: http://localhost:8080"
echo "  Username: admin"
echo "  Password: admin"
echo ""

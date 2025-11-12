#!/bin/bash
# FKS Trading Platform - Local Kubernetes Setup Script
# This script sets up the entire FKS platform on a local Kubernetes cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="fks-trading"
DOCKER_REPO="nuniesmith/fks"
K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}🚀 FKS Trading Platform - Kubernetes Setup${NC}"
echo "=========================================="

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl is required but not installed.${NC}" >&2; exit 1; }
command -v helm >/dev/null 2>&1 || echo -e "${YELLOW}Warning: helm not found (optional for some features)${NC}"

# Check if kubectl can connect to cluster
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    echo "Please ensure your cluster is running and kubectl is configured."
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites check passed${NC}"

# Create namespace
echo -e "\n${YELLOW}Creating namespace...${NC}"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace created${NC}"

# Create secrets (if they don't exist)
echo -e "\n${YELLOW}Setting up secrets...${NC}"
if ! kubectl get secret fks-secrets -n "$NAMESPACE" >/dev/null 2>&1; then
    echo "Creating default secrets..."
    kubectl create secret generic fks-secrets \
        --from-literal=postgres-user=fks_user \
        --from-literal=postgres-password=$(openssl rand -base64 32) \
        --from-literal=redis-password=$(openssl rand -base64 32) \
        --from-literal=django-secret-key=$(openssl rand -base64 64) \
        --from-literal=openai-api-key="" \
        -n "$NAMESPACE" || true
    echo -e "${GREEN}✓ Secrets created${NC}"
else
    echo -e "${GREEN}✓ Secrets already exist${NC}"
fi

# Deploy infrastructure (PostgreSQL, Redis)
echo -e "\n${YELLOW}Deploying infrastructure (PostgreSQL, Redis)...${NC}"
kubectl apply -f "$K8S_DIR/manifests/all-services.yaml" -n "$NAMESPACE"
echo -e "${GREEN}✓ Infrastructure deployed${NC}"

# Wait for database to be ready
echo -e "\n${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres -n "$NAMESPACE" --timeout=300s || true

# Deploy all services
echo -e "\n${YELLOW}Deploying FKS services...${NC}"

# Pull latest images first (optional, but helps with caching)
echo "Pulling latest images from Docker Hub..."
for service in web api app data ai execution portfolio analyze training monitor auth meta ninja main; do
    echo "  - Pulling ${DOCKER_REPO}:${service}-latest"
    docker pull "${DOCKER_REPO}:${service}-latest" 2>/dev/null || echo "    (Image will be pulled by Kubernetes)"
done

# Apply all service deployments
kubectl apply -f "$K8S_DIR/manifests/all-services.yaml" -n "$NAMESPACE"

# Apply missing services if file exists
if [ -f "$K8S_DIR/manifests/missing-services.yaml" ]; then
    kubectl apply -f "$K8S_DIR/manifests/missing-services.yaml" -n "$NAMESPACE"
fi

echo -e "${GREEN}✓ Services deployed${NC}"

# Deploy ingress
echo -e "\n${YELLOW}Deploying ingress...${NC}"
kubectl apply -f "$K8S_DIR/ingress.yaml" -n "$NAMESPACE"
echo -e "${GREEN}✓ Ingress deployed${NC}"

# Deploy development volumes (optional, for live code changes)
echo -e "\n${YELLOW}Setting up development volumes...${NC}"
kubectl apply -f "$K8S_DIR/manifests/dev-volumes.yaml" -n "$NAMESPACE" || echo -e "${YELLOW}⚠ Development volumes setup skipped${NC}"

# Deploy image auto-updater
echo -e "\n${YELLOW}Deploying image auto-updater...${NC}"
kubectl apply -f "$K8S_DIR/manifests/image-auto-updater.yaml" -n "$NAMESPACE"
echo -e "${GREEN}✓ Image auto-updater deployed${NC}"
echo "  - CronJob runs every 15 minutes to check for new images"
echo "  - Deployment runs continuously (alternative mode)"

# Setup Kubernetes Dashboard
echo -e "\n${YELLOW}Setting up Kubernetes Dashboard...${NC}"

# Install dashboard if not exists
if ! kubectl get deployment kubernetes-dashboard -n kubernetes-dashboard >/dev/null 2>&1; then
    echo "Installing Kubernetes Dashboard..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
    # Wait for dashboard to be ready
    kubectl wait --for=condition=available deployment/kubernetes-dashboard -n kubernetes-dashboard --timeout=300s || true
fi

# Create admin user and service account
kubectl apply -f "$K8S_DIR/manifests/dashboard-admin.yaml" -n kubernetes-dashboard

# Get dashboard token (try multiple methods)
echo "Getting dashboard token..."
DASHBOARD_TOKEN=""

# Method 1: Create token (Kubernetes 1.24+)
DASHBOARD_TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user --duration=8760h 2>/dev/null)

# Method 2: Get from secret (older Kubernetes)
if [ -z "$DASHBOARD_TOKEN" ]; then
    DASHBOARD_TOKEN=$(kubectl -n kubernetes-dashboard get secret admin-user-secret -o jsonpath='{.data.token}' 2>/dev/null | base64 -d)
fi

# Method 3: Get from service account token
if [ -z "$DASHBOARD_TOKEN" ]; then
    DASHBOARD_TOKEN=$(kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa admin-user -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' 2>/dev/null | base64 -d)
fi

if [ -n "$DASHBOARD_TOKEN" ]; then
    echo "$DASHBOARD_TOKEN" > "$K8S_DIR/dashboard-token.txt"
    echo -e "${GREEN}✓ Dashboard token saved to $K8S_DIR/dashboard-token.txt${NC}"
    echo "Token (first 50 chars): $(echo "$DASHBOARD_TOKEN" | head -c 50)..."
else
    echo -e "${YELLOW}⚠ Could not get dashboard token automatically${NC}"
    echo "You can get it manually with:"
    echo "  kubectl -n kubernetes-dashboard create token admin-user --duration=8760h"
fi

# Deploy dashboard ingress
kubectl apply -f "$K8S_DIR/manifests/dashboard-ingress.yaml"

# Deploy auto-login service (optional)
if [ -f "$K8S_DIR/manifests/dashboard-ingress-auto-login.yaml" ]; then
    kubectl apply -f "$K8S_DIR/manifests/dashboard-ingress-auto-login.yaml"
fi

echo -e "${GREEN}✓ Kubernetes Dashboard configured${NC}"

# Wait for services to be ready
echo -e "\n${YELLOW}Waiting for services to be ready...${NC}"
kubectl wait --for=condition=available deployment --all -n "$NAMESPACE" --timeout=600s || true

# Show status
echo -e "\n${GREEN}📊 Deployment Status${NC}"
echo "=========================================="
kubectl get pods -n "$NAMESPACE"
echo ""
kubectl get services -n "$NAMESPACE"
echo ""
kubectl get ingress -n "$NAMESPACE"

# Show dashboard info
echo -e "\n${GREEN}📊 Kubernetes Dashboard${NC}"
echo "=========================================="
echo "Dashboard URL: http://dashboard.fkstrading.xyz"
echo "Or via kubectl proxy: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo ""
if [ -f "$K8S_DIR/dashboard-token.txt" ]; then
    echo "Token saved to: $K8S_DIR/dashboard-token.txt"
    echo "Token (first 50 chars): $(head -c 50 "$K8S_DIR/dashboard-token.txt")..."
fi

echo -e "\n${GREEN}✅ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Update /etc/hosts to point fkstrading.xyz to your cluster IP"
echo "2. Access web interface at: http://fkstrading.xyz"
echo "3. Access dashboard at: http://dashboard.fkstrading.xyz"
echo "4. Start kubectl proxy: kubectl proxy (for dashboard access)"


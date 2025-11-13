#!/bin/bash
# FKS Trading Platform - Kubernetes Deployment Script
# Phase 8.1: Kubernetes Migration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="${NAMESPACE:-fks-trading}"
RELEASE_NAME="${RELEASE_NAME:-fks-platform}"
CHART_PATH="./charts/fks-platform"
VALUES_FILE="${VALUES_FILE:-./charts/fks-platform/values.yaml}"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        log_error "helm not found. Please install Helm."
        exit 1
    fi
    
    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster."
        exit 1
    fi
    
    log_info "Prerequisites check passed ✓"
}

create_namespace() {
    log_info "Creating namespace: $NAMESPACE"
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Label namespace
    kubectl label namespace "$NAMESPACE" \
        app=fks-platform \
        environment=production \
        managed-by=helm \
        --overwrite
}

setup_secrets() {
    log_info "Checking secrets..."
    
    # Just check if secrets exist, don't create them
    # Helm will manage the fks-secrets secret
    if kubectl get secret fks-secrets -n "$NAMESPACE" &> /dev/null; then
        log_info "Secrets already exist (managed by Helm) ✓"
    else
        log_info "Secrets will be created by Helm deployment ✓"
    fi
}

add_helm_repos() {
    log_info "Adding Helm repositories..."
    
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    log_info "Helm repositories added ✓"
}

install_cert_manager() {
    log_info "Installing cert-manager for SSL/TLS..."
    
    # Check if cert-manager is already installed
    if kubectl get namespace cert-manager &> /dev/null; then
        log_warn "cert-manager already installed. Skipping."
        return
    fi
    
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
    
    # Wait for cert-manager to be ready
    log_info "Waiting for cert-manager to be ready..."
    kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/instance=cert-manager \
        -n cert-manager \
        --timeout=300s
    
    log_info "cert-manager installed ✓"
}

install_nginx_ingress() {
    log_info "Installing NGINX Ingress Controller..."
    
    # Check if ingress-nginx is already installed
    if kubectl get namespace ingress-nginx &> /dev/null; then
        log_warn "NGINX Ingress already installed. Skipping."
        return
    fi
    
    helm install ingress-nginx ingress-nginx \
        --repo https://kubernetes.github.io/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.metrics.enabled=true \
        --set controller.metrics.serviceMonitor.enabled=true
    
    # Wait for ingress controller to be ready
    log_info "Waiting for NGINX Ingress to be ready..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
    
    log_info "NGINX Ingress installed ✓"
}

deploy_platform() {
    log_info "Deploying FKS Trading Platform..."
    
    # Lint chart
    log_info "Linting Helm chart..."
    helm lint "$CHART_PATH" -f "$VALUES_FILE"
    
    # Get existing passwords if they exist
    POSTGRES_PASSWORD=""
    REDIS_PASSWORD=""
    
    if kubectl get secret fks-platform-postgresql -n "$NAMESPACE" &> /dev/null; then
        log_info "Retrieving existing PostgreSQL password..."
        POSTGRES_PASSWORD=$(kubectl get secret fks-platform-postgresql -n "$NAMESPACE" -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "")
    fi
    
    if kubectl get secret fks-platform-redis -n "$NAMESPACE" &> /dev/null; then
        log_info "Retrieving existing Redis password..."
        REDIS_PASSWORD=$(kubectl get secret fks-platform-redis -n "$NAMESPACE" -o jsonpath="{.data.redis-password}" 2>/dev/null | base64 -d || echo "")
    fi
    
    # Build helm upgrade command with passwords
    HELM_ARGS=()
    if [ -n "$POSTGRES_PASSWORD" ]; then
        log_info "Using existing PostgreSQL password"
        HELM_ARGS+=(--set global.postgresql.auth.password="$POSTGRES_PASSWORD")
    fi
    
    if [ -n "$REDIS_PASSWORD" ]; then
        log_info "Using existing Redis password"
        HELM_ARGS+=(--set global.redis.auth.password="$REDIS_PASSWORD")
    fi
    
    # Dry run
    log_info "Running dry-run deployment..."
    helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
        --namespace "$NAMESPACE" \
        -f "$VALUES_FILE" \
        "${HELM_ARGS[@]}" \
        --dry-run --debug
    
    # Actual deployment
    log_info "Deploying to cluster..."
    helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
        --namespace "$NAMESPACE" \
        -f "$VALUES_FILE" \
        "${HELM_ARGS[@]}" \
        --create-namespace \
        --wait \
        --timeout 10m
    
    log_info "Platform deployed successfully ✓"
}

verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check pod status
    log_info "Pod status:"
    kubectl get pods -n "$NAMESPACE" -o wide
    
    # Check service status
    log_info "Service status:"
    kubectl get svc -n "$NAMESPACE"
    
    # Check ingress
    log_info "Ingress status:"
    kubectl get ingress -n "$NAMESPACE"
    
    # Wait for all pods to be ready
    log_info "Waiting for all pods to be ready..."
    kubectl wait --for=condition=ready pod \
        --all \
        -n "$NAMESPACE" \
        --timeout=600s || log_warn "Some pods are not ready yet"
    
    log_info "Deployment verification complete ✓"
}

show_access_info() {
    log_info "=== Access Information ==="
    
    # Get LoadBalancer IP (if cloud provider)
    INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    
    if [ "$INGRESS_IP" = "pending" ]; then
        log_warn "LoadBalancer IP pending. For local clusters, use port-forward:"
        echo ""
        echo "  kubectl port-forward -n $NAMESPACE svc/fks-main 8000:8000"
        echo "  kubectl port-forward -n $NAMESPACE svc/fks-web 3001:3001"
        echo "  kubectl port-forward -n $NAMESPACE svc/grafana 3000:80"
    else
        echo ""
        echo "  FKS Main: http://$INGRESS_IP:8000"
        echo "  FKS Web: http://$INGRESS_IP:3001"
        echo "  Grafana: http://$INGRESS_IP:3000"
    fi
    
    echo ""
    log_info "To get logs:"
    echo "  kubectl logs -n $NAMESPACE -l app=fks-main -f"
    echo ""
    log_info "To get a shell:"
    echo "  kubectl exec -n $NAMESPACE -it deployment/fks-main -- /bin/bash"
}

main() {
    echo ""
    echo "╔═══════════════════════════════════════════════╗"
    echo "║  FKS Trading Platform - K8s Deployment       ║"
    echo "║  Phase 8.1: Kubernetes Migration             ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo ""
    
    check_prerequisites
    create_namespace
    setup_secrets
    add_helm_repos
    install_cert_manager
    install_nginx_ingress
    deploy_platform
    verify_deployment
    show_access_info
    
    echo ""
    log_info "✓ Deployment complete!"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --values)
            VALUES_FILE="$2"
            shift 2
            ;;
        deploy|uninstall|status|logs|shell)
            COMMAND="$1"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Handle script arguments
case "${COMMAND:-deploy}" in
    deploy)
        main
        ;;
    uninstall)
        log_warn "Uninstalling FKS Platform..."
        helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"
        kubectl delete namespace "$NAMESPACE"
        log_info "Uninstalled successfully"
        ;;
    status)
        kubectl get all -n "$NAMESPACE"
        ;;
    logs)
        POD="${2:-fks-main}"
        kubectl logs -n "$NAMESPACE" -l "app=$POD" -f
        ;;
    shell)
        POD="${2:-fks-main}"
        kubectl exec -n "$NAMESPACE" -it "deployment/$POD" -- /bin/bash
        ;;
    *)
        echo "Usage: $0 {deploy|uninstall|status|logs|shell}"
        exit 1
        ;;
esac

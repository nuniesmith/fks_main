#!/bin/bash
# FKS Trading Platform - Phase 5 Production Deployment Script
# Deploys execution pipeline with monitoring stack to Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="fks-trading"
MANIFESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../manifests" && pwd)"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          FKS Trading Platform - Phase 5 Deployment                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Function to check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}✗ kubectl not found${NC}"
        echo -e "Install kubectl: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
    echo -e "${GREEN}✓ kubectl found${NC}"
    
    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}✗ Cannot connect to Kubernetes cluster${NC}"
        echo -e "Configure kubectl context or start minikube"
        exit 1
    fi
    echo -e "${GREEN}✓ Connected to Kubernetes cluster${NC}"
    
    # Check for secrets file
    if [ ! -f "$MANIFESTS_DIR/secrets.yaml" ]; then
        echo -e "${YELLOW}⚠ secrets.yaml not found${NC}"
        echo -e "Copy secrets.yaml.template to secrets.yaml and fill in values"
        echo -e "  cp $MANIFESTS_DIR/secrets.yaml.template $MANIFESTS_DIR/secrets.yaml"
        echo -e "  nano $MANIFESTS_DIR/secrets.yaml"
        exit 1
    fi
    echo -e "${GREEN}✓ secrets.yaml found${NC}"
}

# Function to create namespace
create_namespace() {
    print_section "Creating Namespace"
    
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        echo -e "${YELLOW}Namespace $NAMESPACE already exists${NC}"
    else
        kubectl create namespace $NAMESPACE
        echo -e "${GREEN}✓ Created namespace: $NAMESPACE${NC}"
    fi
    
    # Label namespace
    kubectl label namespace $NAMESPACE monitoring=enabled --overwrite
    kubectl label namespace $NAMESPACE environment=production --overwrite
}

# Function to apply secrets
apply_secrets() {
    print_section "Applying Secrets"
    
    kubectl apply -f "$MANIFESTS_DIR/secrets.yaml" -n $NAMESPACE
    echo -e "${GREEN}✓ Secrets applied${NC}"
}

# Function to deploy monitoring stack
deploy_monitoring() {
    print_section "Deploying Monitoring Stack"
    
    echo "Applying Prometheus rules..."
    kubectl apply -f "$MANIFESTS_DIR/prometheus-rules.yaml" -n $NAMESPACE
    echo -e "${GREEN}✓ Prometheus rules applied${NC}"
    
    echo "Deploying Prometheus and Grafana..."
    kubectl apply -f "$MANIFESTS_DIR/monitoring-stack.yaml" -n $NAMESPACE
    echo -e "${GREEN}✓ Monitoring stack deployed${NC}"
    
    echo "Deploying Alertmanager..."
    kubectl apply -f "$MANIFESTS_DIR/alertmanager.yaml" -n $NAMESPACE
    echo -e "${GREEN}✓ Alertmanager deployed${NC}"
}

# Function to deploy execution service
deploy_execution() {
    print_section "Deploying Execution Service"
    
    kubectl apply -f "$MANIFESTS_DIR/execution-service.yaml" -n $NAMESPACE
    echo -e "${GREEN}✓ Execution service deployed${NC}"
}

# Function to apply ingress
apply_ingress() {
    print_section "Applying Ingress Configuration"
    
    # Use self-signed cert ingress
    echo "Applying ingress with self-signed TLS..."
    kubectl apply -f "$MANIFESTS_DIR/ingress-selfcert.yaml" -n $NAMESPACE
    echo -e "${GREEN}✓ Ingress applied with self-signed TLS${NC}"
    echo -e "${YELLOW}Note: Browser will show certificate warnings - this is expected for self-signed certs${NC}"
}

# Function to wait for deployments
wait_for_deployments() {
    print_section "Waiting for Deployments"
    
    echo "Waiting for Prometheus..."
    kubectl rollout status deployment/prometheus -n $NAMESPACE --timeout=300s
    echo -e "${GREEN}✓ Prometheus ready${NC}"
    
    echo "Waiting for Grafana..."
    kubectl rollout status deployment/grafana -n $NAMESPACE --timeout=300s
    echo -e "${GREEN}✓ Grafana ready${NC}"
    
    echo "Waiting for Alertmanager..."
    kubectl rollout status deployment/alertmanager -n $NAMESPACE --timeout=300s
    echo -e "${GREEN}✓ Alertmanager ready${NC}"
    
    echo "Waiting for Execution Service..."
    kubectl rollout status deployment/fks-execution -n $NAMESPACE --timeout=300s
    echo -e "${GREEN}✓ Execution service ready${NC}"
}

# Function to display status
display_status() {
    print_section "Deployment Status"
    
    echo "Pods:"
    kubectl get pods -n $NAMESPACE
    echo ""
    
    echo "Services:"
    kubectl get svc -n $NAMESPACE
    echo ""
    
    echo "Ingress:"
    kubectl get ingress -n $NAMESPACE
    echo ""
    
    echo "PersistentVolumeClaims:"
    kubectl get pvc -n $NAMESPACE
}

# Function to display access information
display_access_info() {
    print_section "Access Information"
    
    echo -e "${GREEN}Monitoring URLs:${NC}"
    echo -e "  Grafana:      https://grafana.fks-trading.com"
    echo -e "  Prometheus:   https://prometheus.fks-trading.com"
    echo -e "  Alertmanager: https://alertmanager.fks-trading.com"
    echo ""
    
    echo -e "${YELLOW}Port Forward (for local access):${NC}"
    echo -e "  Grafana:      kubectl port-forward -n $NAMESPACE svc/grafana 3000:3000"
    echo -e "  Prometheus:   kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090"
    echo -e "  Alertmanager: kubectl port-forward -n $NAMESPACE svc/alertmanager 9093:9093"
    echo ""
    
    echo -e "${GREEN}View logs:${NC}"
    echo -e "  kubectl logs -n $NAMESPACE -l app=fks-execution --tail=100 -f"
    echo -e "  kubectl logs -n $NAMESPACE -l app=prometheus --tail=100 -f"
    echo ""
    
    echo -e "${GREEN}View metrics:${NC}"
    echo -e "  kubectl port-forward -n $NAMESPACE svc/fks-execution 8000:8000"
    echo -e "  curl http://localhost:8000/metrics"
}

# Main deployment flow
main() {
    check_prerequisites
    create_namespace
    apply_secrets
    deploy_monitoring
    deploy_execution
    apply_ingress
    wait_for_deployments
    display_status
    display_access_info
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              ✅ Phase 5 Deployment Complete!                             ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Run main function
main "$@"

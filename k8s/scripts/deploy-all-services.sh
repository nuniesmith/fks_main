#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NAMESPACE="fks-trading"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(dirname "$SCRIPT_DIR")/manifests"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}FKS Trading - Full Stack Deployment${NC}"
echo -e "${BLUE}========================================${NC}"

# Function to print colored messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    log_error "Cannot connect to Kubernetes cluster. Is minikube running?"
    exit 1
fi

log_info "Connected to Kubernetes cluster"

# Create namespace if it doesn't exist
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    log_info "Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE
    log_success "Namespace created"
else
    log_info "Namespace $NAMESPACE already exists"
fi

# Check if secrets exist
if ! kubectl get secret fks-secrets -n $NAMESPACE &> /dev/null; then
    log_warning "Secrets not found!"
    log_warning "Please create fks-secrets from template:"
    echo ""
    echo "  cp $K8S_DIR/fks-secrets.yaml.template $K8S_DIR/fks-secrets.yaml"
    echo "  # Edit fks-secrets.yaml with actual values"
    echo "  kubectl apply -f $K8S_DIR/fks-secrets.yaml"
    echo ""
    read -p "Do you want to create secrets now with default values? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Creating secrets with default values (NOT FOR PRODUCTION!)"
        cat > /tmp/fks-secrets-temp.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: fks-secrets
  namespace: $NAMESPACE
type: Opaque
stringData:
  postgres-user: "trading_user"
  postgres-password: "dev_password_123"
  django-secret-key: "django-insecure-dev-key-$(openssl rand -hex 32)"
  openai-api-key: ""
  slack-webhook-url: ""
  binance-api-key: ""
  binance-api-secret: ""
EOF
        kubectl apply -f /tmp/fks-secrets-temp.yaml
        rm /tmp/fks-secrets-temp.yaml
        log_success "Dev secrets created (change for production!)"
    else
        log_error "Cannot proceed without secrets"
        exit 1
    fi
fi

# Deploy database and Redis (stateful services first)
log_info "Deploying PostgreSQL and Redis..."
kubectl apply -f $K8S_DIR/all-services.yaml
log_success "Database and Redis manifests applied"

# Wait for database to be ready
log_info "Waiting for PostgreSQL to be ready (this may take a few minutes)..."
kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=300s || {
    log_warning "PostgreSQL taking longer than expected. Continuing..."
}

log_info "Waiting for Redis to be ready..."
kubectl wait --for=condition=ready pod -l app=redis -n $NAMESPACE --timeout=120s || {
    log_warning "Redis taking longer than expected. Continuing..."
}

# Wait for web service to complete migrations
log_info "Waiting for Django migrations to complete..."
sleep 30

# Check deployment status
log_info "Checking deployment status..."
echo ""
kubectl get pods -n $NAMESPACE
echo ""

# Apply Tailscale ingress
log_info "Configuring ingress for Tailscale network..."
kubectl apply -f $K8S_DIR/ingress-tailscale.yaml
log_success "Ingress configured"

# Update /etc/hosts for Tailscale IP
TAILSCALE_IP="100.116.135.8"
log_info "Updating /etc/hosts for Tailscale IP ($TAILSCALE_IP)..."

# Backup /etc/hosts
sudo cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S)

# Remove old entries
sudo sed -i '/fkstrading.xyz/d' /etc/hosts

# Add new entries with Tailscale IP
cat <<EOF | sudo tee -a /etc/hosts
# FKS Trading - Tailscale network
$TAILSCALE_IP fkstrading.xyz
$TAILSCALE_IP www.fkstrading.xyz
$TAILSCALE_IP api.fkstrading.xyz
$TAILSCALE_IP grafana.fkstrading.xyz
$TAILSCALE_IP prometheus.fkstrading.xyz
$TAILSCALE_IP alertmanager.fkstrading.xyz
$TAILSCALE_IP flower.fkstrading.xyz
$TAILSCALE_IP execution.fkstrading.xyz
EOF

log_success "/etc/hosts updated with Tailscale IP"

# Configure minikube tunnel for LoadBalancer (run in background)
log_info "Setting up ingress access..."
log_warning "You may need to run 'minikube tunnel' in a separate terminal for external access"

# Get ingress IP
INGRESS_IP=$(kubectl get ingress fks-ingress-tailscale -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Services Deployed:${NC}"
kubectl get svc -n $NAMESPACE
echo ""
echo -e "${BLUE}Pod Status:${NC}"
kubectl get pods -n $NAMESPACE
echo ""
echo -e "${BLUE}Persistent Volumes:${NC}"
kubectl get pvc -n $NAMESPACE
echo ""
echo -e "${BLUE}Ingress Routes:${NC}"
kubectl get ingress -n $NAMESPACE
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Access Information${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Web UI:${NC}          https://fkstrading.xyz"
echo -e "${BLUE}API:${NC}             https://api.fkstrading.xyz"
echo -e "${BLUE}Grafana:${NC}         https://grafana.fkstrading.xyz"
echo -e "${BLUE}Prometheus:${NC}      https://prometheus.fkstrading.xyz"
echo -e "${BLUE}Alertmanager:${NC}    https://alertmanager.fkstrading.xyz"
echo -e "${BLUE}Flower:${NC}          https://flower.fkstrading.xyz"
echo -e "${BLUE}Execution:${NC}       https://execution.fkstrading.xyz"
echo ""
echo -e "${YELLOW}Note: Self-signed certificates in use. Accept browser warnings.${NC}"
echo ""
echo -e "${BLUE}Tailscale IP:${NC}    $TAILSCALE_IP"
echo -e "${BLUE}Ingress IP:${NC}      $INGRESS_IP"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Next Steps${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "1. Run 'minikube tunnel' in a separate terminal for external access"
echo "2. Access services via https://*.fkstrading.xyz"
echo "3. Monitor logs: kubectl logs -f deployment/fks-web -n fks-trading"
echo "4. Check health: kubectl get pods -n fks-trading"
echo ""

# Port forwarding helper
cat > /tmp/fks-port-forward.sh <<'EOF'
#!/bin/bash
# Port forwarding helper for local development

NAMESPACE="fks-trading"

echo "Starting port forwarding for FKS services..."
echo "Press Ctrl+C to stop all forwards"

kubectl port-forward -n $NAMESPACE svc/web 8000:8000 &
kubectl port-forward -n $NAMESPACE svc/fks-api 8001:8001 &
kubectl port-forward -n $NAMESPACE svc/grafana 3000:3000 &
kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090 &
kubectl port-forward -n $NAMESPACE svc/flower 5555:5555 &

wait
EOF

chmod +x /tmp/fks-port-forward.sh
log_info "Port forwarding helper created: /tmp/fks-port-forward.sh"

log_success "Deployment complete! 🚀"
